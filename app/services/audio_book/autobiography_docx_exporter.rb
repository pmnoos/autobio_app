module AudioBook
  class AutobiographyDocxExporter
    def initialize(chapters:)
      @chapters = chapters
    end

    def export(file_path)
      Caracal::Document.save(file_path) do |docx|
        build_title_page(docx)

      @chapters.each_with_index do |chapter, index|
        docx.page

        chapter_number = index + 1

        # Chapter heading
        docx.h2 "Chapter #{chapter_number}"
        docx.h1 chapter.title
        docx.p chapter.subtitle if chapter.subtitle.present?

        # Chapter image
        embed_chapter_image(docx, chapter_number)

        # Chapter content
        chapter.content.to_s.split(/\n{2,}/).each do |para|
          docx.p para.strip
        end
      end
    end
  end

  private

  # ------------------------
  # Title page
  # ------------------------
  def build_title_page(docx)
    docx.h1 "My Autobiography"
    docx.p "A Life in Chapters"
    docx.page
  end

  # ------------------------
  # Image embedding (FIXED)
  # ------------------------
  def embed_chapter_image(docx, chapter_number)
    base = Rails.root.join(
      "public",
      "images",
      "chapter_#{chapter_number}_header"
    )

    image_path =
      %w[.jpg .png .JPG .PNG].map { |ext| "#{base}#{ext}" }
                              .find { |path| File.exist?(path) }

    return unless image_path

    docx.hr
    docx.img image_path, width: 500
    docx.hr
    docx.p ""
  end
  end
end
