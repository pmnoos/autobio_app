require "caracal"
require "nokogiri"

class DocxExporter
  def self.generate_full_docx(chapters:, user_info:)
    tmp_docx = Tempfile.new([ "autobiography", ".docx" ])
    tmp_docx.binmode
    tmp_assets = []
    begin
      Caracal::Document.save(tmp_docx.path) do |docx|
      docx.style do
        id "Normal"
        name "Normal"
        font "Georgia"
        size 24
        color "333333"
        line 360
      end

      # Cover Page
      docx.h1 user_info[:title]
      docx.p user_info[:subtitle], italic: true, color: "667eea"
      docx.p "by #{user_info[:name]}"
      docx.p "Generated on #{user_info[:generated_date]}", color: "999999"
      docx.page

      # Table of Contents (simple)
      docx.h2 "Table of Contents"
      chapters.each_with_index do |chapter, index|
        heading = chapter.intro_chapter? ? "Introduction: #{chapter.title}" : "Chapter #{chapter.chapter_number}: #{chapter.title}"
        docx.p "#{index + 1}. #{heading}", bold: true
      end
      docx.page

      # Chapters
      chapters.each do |chapter|
        if chapter.intro_chapter?
          docx.h2 "Introduction"
        else
          docx.h2 "Chapter #{chapter.chapter_number}"
        end
        docx.h1 chapter.title
        docx.p chapter.subtitle if chapter.subtitle.present?
        docx.p "Written on #{chapter.created_at.strftime('%B %d, %Y')}", color: "999999"

        # Optional image header if attached
        if chapter.respond_to?(:image_header) && chapter.image_header.attached?
          tf = Tempfile.new([ "chapter_header", ".jpg" ])
          tf.binmode
          tf.write(chapter.image_header.blob.download)
          tf.flush
          tmp_assets << tf
          docx.img tf.path, width: 600, height: 300
        end

        # Parse HTML content and map basic tags to DOCX
        content_html = chapter.content.to_s
        fragment = Nokogiri::HTML::DocumentFragment.parse(content_html)

        fragment.children.each do |node|
          case node.name
          when "h1"
            docx.h1(node.text.strip)
          when "h2"
            docx.h2(node.text.strip)
          when "h3"
            docx.h3(node.text.strip)
          when "p"
            docx.p node.text.strip
          when "ul"
            node.css("li").each { |li| docx.ul li.text.strip }
          when "ol"
            node.css("li").each { |li| docx.ol li.text.strip }
          when "blockquote"
            docx.p node.text.strip, italic: true
          when "img"
            # Inline images: attempt to fetch via src if present
            src = node["src"]
            if src&.start_with?("http")
              docx.img src, width: 600
            end
          else
            # Fallback: add text if meaningful
            text = node.text.to_s.strip
            docx.p(text) unless text.empty?
          end
        end

        docx.page
      end
      end
      data = File.binread(tmp_docx.path)
      data
    ensure
      tmp_assets.each { |f| f.close! rescue nil }
      tmp_docx.close! rescue nil
    end
  end

  # Reserved for future richer inline formatting support
  # def self.inline_runs_from(pnode); end
end
