require "zip"
require "nokogiri"
require "erb"

module AudioBook
  class AutobiographyDocxImporter
    DOCX_XML_PATH = "word/document.xml".freeze
    CHAPTER_MARKER_REGEX =
      /\A(?:Chapter\s+\d+\b(?:\s*[:\-–—]\s*.*)?|Dedication\b(?:\s*[:\-–—]\s*.*)?|Introduction\b(?:\s*[:\-–—]\s*.*)?|Epilogue\b(?:\s*[:\-–—]\s*.*)?)\z/i
    HEADING_1_REGEX = /heading\s*1|heading1/i
    HEADING_2_REGEX = /heading\s*2|heading2/i
    METADATA_LINE_REGEX = /\AWritten on\s+/i

    def initialize(file_path)
      @file_path = file_path.to_s
      @parsed_chapters = nil
    end

    def preview_matches(database_chapters:)
      imported = parsed_docx_chapters
      website = Array(database_chapters)
      used_website_ids = {}

      imported.each_with_index.map do |word, index|
        site, strategy = suggested_website_chapter_for(word, website, used_website_ids)
        used_website_ids[site.id] = true if site.present?

        {
          position: index + 1,
          imported_index: index,
          word_chapter_title: word[:word_title].to_s,
          website_chapter_title: site&.title.to_s,
          word_content_excerpt: excerpt_text(word[:plain_content].to_s),
          website_content_excerpt: excerpt_text(plain_website_content(site)),
          match_status: preview_match_status(strategy),
          suggested_chapter_id: site&.id
        }
      end
    end

    def import_selected!(database_chapters:, mappings:)
      imported = parsed_docx_chapters
      website_by_id = Array(database_chapters).index_by(&:id)
      mapping_entries = Array(mappings)

      updated = 0
      skipped = 0
      unmatched = 0

      Chapter.transaction do
        mapping_entries.each do |entry|
          imported_index = entry[:imported_index].to_i
          imported_chapter = imported[imported_index]
          next if imported_chapter.blank?

          selected_id = entry[:chapter_id].to_i
          if selected_id <= 0
            skipped += 1
            next
          end

          website_chapter = website_by_id[selected_id]
          if website_chapter.blank?
            unmatched += 1
            next
          end

          new_title = imported_chapter[:word_title].presence || website_chapter.title
          new_subtitle = imported_chapter[:word_subtitle].presence || website_chapter.subtitle
          new_content = imported_chapter[:html_content].to_s

          website_chapter.assign_attributes(title: new_title, subtitle: new_subtitle)
          website_chapter.content = new_content
          website_chapter.save!
          updated += 1
        end
      end

      {
        updated: updated,
        skipped: skipped,
        unmatched: unmatched,
        total_docx_chapters: imported.length
      }
    end

    def import_everything!(database_chapters:)
      imported = parsed_docx_chapters
      website = Array(database_chapters)
      update_count = [ imported.length, website.length ].min
      updated = 0

      Chapter.transaction do
        update_count.times do |index|
          imported_chapter = imported[index]
          website_chapter = website[index]
          next if imported_chapter.blank? || website_chapter.blank?

          new_title = imported_chapter[:word_title].presence || website_chapter.title
          new_subtitle = imported_chapter[:word_subtitle].presence || website_chapter.subtitle
          new_content = imported_chapter[:html_content].to_s

          website_chapter.assign_attributes(title: new_title, subtitle: new_subtitle)
          website_chapter.content = new_content
          website_chapter.save!
          updated += 1
        end
      end

      {
        updated: updated,
        unmatched_docx_chapters: [ imported.length - website.length, 0 ].max,
        unmatched_website_chapters: [ website.length - imported.length, 0 ].max
      }
    end

    private

    def parsed_docx_chapters
      @parsed_chapters ||= begin
        paragraphs = extract_paragraphs_from_docx
        split_into_chapters(paragraphs)
      end
    end

    def preview_match_status(strategy)
      case strategy
      when :title_exact
        "Suggested by exact title"
      when :title_partial
        "Suggested by similar title"
      else
        "No title-based suggestion"
      end
    end

    def suggested_website_chapter_for(word, website, used_website_ids)
      return [ nil, :none ] if word.blank?

      word_title = normalize_title_for_match(word[:word_title])
      available = website.reject { |ch| used_website_ids[ch.id] }

      exact = available.find { |ch| normalize_title_for_match(ch.title) == word_title && word_title.present? }
      return [ exact, :title_exact ] if exact

      partial = available.find do |ch|
        chapter_title = normalize_title_for_match(ch.title)
        next false if chapter_title.blank? || word_title.blank?

        chapter_title.include?(word_title) || word_title.include?(chapter_title)
      end
      return [ partial, :title_partial ] if partial

      [ nil, :none ]
    end

    def normalize_title_for_match(value)
      value.to_s.downcase.gsub(/[^a-z0-9\s]/, " ").gsub(/\s+/, " ").strip
    end

    def extract_paragraphs_from_docx
      xml = nil

      Zip::File.open(@file_path) do |zip_file|
        entry = zip_file.find_entry(DOCX_XML_PATH)
        raise ArgumentError, "Invalid DOCX file (missing document.xml)." unless entry

        xml = entry.get_input_stream.read
      end

      parse_paragraph_nodes(xml)
    end

    def parse_paragraph_nodes(xml)
      doc = Nokogiri::XML(xml)
      ns = { "w" => "http://schemas.openxmlformats.org/wordprocessingml/2006/main" }

      doc.xpath("//w:body/w:p", ns).map do |node|
        text = node.xpath(".//w:t", ns).map(&:text).join
        style = paragraph_style_value(node, ns)

        {
          text: normalize_text(text),
          style: style.to_s
        }
      end
    end

    def paragraph_style_value(node, ns)
      style_node = node.at_xpath("./w:pPr/w:pStyle", ns)
      return "" unless style_node

      style_node.attribute_with_ns("val", ns["w"])&.value ||
        style_node["w:val"] ||
        style_node["val"] ||
        ""
    end

    def normalize_text(text)
      text.to_s.tr("\u00A0", " ").strip
    end

    def split_into_chapters(paragraphs)
      chapters = []
      current = nil

      paragraphs.each do |paragraph|
        text = paragraph[:text]
        style = paragraph[:style]
        next if text.blank?

        if chapter_start?(text, style)
          chapters << finalize_chapter(current) if current
          current = { marker: text, word_title: nil, word_subtitle: nil, blocks: [] }
          next
        end

        next unless current
        next if metadata_line?(text)

        if current[:word_title].blank? && heading_1?(style)
          current[:word_title] = text
          next
        end

        if current[:word_title].blank?
          current[:word_title] = text
          next
        end

        if subtitle_candidate?(current, text, style)
          current[:word_subtitle] = text
          next
        end

        next if duplicate_title_block?(current, text)

        current[:blocks] << {
          type: heading_level_for_style(style),
          text: text
        }
      end

      chapters << finalize_chapter(current) if current
      chapters.compact
    end

    def chapter_start?(text, style)
      CHAPTER_MARKER_REGEX.match?(text) ||
        (heading_2?(style) && CHAPTER_MARKER_REGEX.match?(text))
    end

    def heading_1?(style)
      HEADING_1_REGEX.match?(style.to_s)
    end

    def heading_2?(style)
      HEADING_2_REGEX.match?(style.to_s)
    end

    def metadata_line?(text)
      METADATA_LINE_REGEX.match?(text)
    end

    def heading_level_for_style(style)
      value = style.to_s
      return :h1 if HEADING_1_REGEX.match?(value)
      return :h2 if HEADING_2_REGEX.match?(value)

      if value.match?(/heading\s*3|heading3/i)
        :h3
      else
        :p
      end
    end

    def finalize_chapter(chapter)
      return nil if chapter.blank?

      title = chapter[:word_title].to_s.strip
      subtitle = chapter[:word_subtitle].to_s.strip
      html = blocks_to_html(chapter[:blocks])
      plain = chapter[:blocks].map { |b| b[:text].to_s.strip }.reject(&:blank?).join("\n\n")

      {
        marker: chapter[:marker],
        word_title: title,
        word_subtitle: subtitle,
        html_content: html,
        plain_content: plain
      }
    end

    def subtitle_candidate?(chapter, text, style)
      return false if chapter[:word_subtitle].present?
      return false if chapter[:blocks].present?
      return false if heading_1?(style) || heading_2?(style)

      value = text.to_s.strip
      return false if value.blank?
      return false if normalize_title_for_match(value) == normalize_title_for_match(chapter[:word_title])

      value.length <= 160
    end

    def duplicate_title_block?(chapter, text)
      normalize_title_for_match(text) == normalize_title_for_match(chapter[:word_title])
    end

    def blocks_to_html(blocks)
      return "" if blocks.blank?

      blocks.map do |block|
        escaped = ERB::Util.html_escape(block[:text].to_s)
        next if escaped.blank?

        case block[:type]
        when :h1
          "<h1>#{escaped}</h1>"
        when :h2
          "<h2>#{escaped}</h2>"
        when :h3
          "<h3>#{escaped}</h3>"
        else
          "<p>#{escaped}</p>"
        end
      end.compact.join("\n")
    end

    def plain_website_content(chapter)
      return "" if chapter.blank?

      content = chapter.content
      return content.to_plain_text.to_s if content.respond_to?(:to_plain_text)

      content.to_s
    rescue StandardError
      ""
    end

    def excerpt_text(text, max_length: 260)
      clean = text.to_s.gsub(/\s+/, " ").strip
      return "" if clean.blank?
      return clean if clean.length <= max_length

      "#{clean[0...max_length]}..."
    end
  end
end
