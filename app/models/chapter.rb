class Chapter < ApplicationRecord
  has_rich_text :content
  has_one_attached :image_header
  has_one_attached :image
  has_one_attached :audio_file

  validates :title, presence: true
  validates :content, presence: true

  # Scope to order: Dedication → Introduction → numbered → Epilogue → Afterword → About the Author
  # Uses special_type if column exists; falls back to title detection otherwise.
  scope :order_chapters_with_intro_first, -> {
    begin
      case_sql = if ActiveRecord::Base.connection.schema_cache.columns_hash("chapters").key?("special_type")
        "CASE \
          WHEN special_type = 'dedication' OR (special_type IS NULL AND (LOWER(title) LIKE '%dedication%' OR LOWER(title) LIKE '%didication%')) THEN 0 \
          WHEN special_type = 'introduction' OR (special_type IS NULL AND LOWER(title) LIKE '%intro%') THEN 1 \
          WHEN special_type = 'epilogue' OR (special_type IS NULL AND LOWER(title) LIKE '%epilogue%') THEN 3 \
          WHEN special_type = 'afterword' OR (special_type IS NULL AND LOWER(title) LIKE '%afterword%') THEN 4 \
          WHEN special_type = 'about_author' OR (special_type IS NULL AND (LOWER(title) LIKE '%about the author%' OR LOWER(title) LIKE '%about author%')) THEN 5 \
          ELSE 2 END"
      else
        "CASE \
          WHEN LOWER(title) LIKE '%dedication%' OR LOWER(title) LIKE '%didication%' THEN 0 \
          WHEN LOWER(title) LIKE '%intro%' THEN 1 \
          WHEN LOWER(title) LIKE '%epilogue%' THEN 3 \
          WHEN LOWER(title) LIKE '%afterword%' THEN 4 \
          WHEN LOWER(title) LIKE '%about the author%' OR LOWER(title) LIKE '%about author%' THEN 5 \
          ELSE 2 END"
      end

      order(Arel.sql("#{case_sql}, CASE WHEN position IS NULL THEN 1 ELSE 0 END, position ASC, created_at ASC"))
    rescue StandardError
      order(Arel.sql("CASE WHEN position IS NULL THEN 1 ELSE 0 END, position ASC, created_at ASC"))
    end
  }

  def special_type_value
    has_attribute?(:special_type) ? (self[:special_type].to_s) : ""
  end

  def normalized_title
    title.to_s.downcase
  end

  # Helper method to check if this is the intro chapter
  def intro_chapter?
    (special_type_value == "introduction") || normalized_title.include?("intro")
  end

  # Helper method to check if this is the epilogue chapter
  def epilogue_chapter?
    (special_type_value == "epilogue") || normalized_title.include?("epilogue")
  end

  # Helper method to check if this is the dedication page
  def dedication_chapter?
    (special_type_value == "dedication") || normalized_title.include?("dedication") || normalized_title.include?("didication")
  end

  def afterword_chapter?
    (special_type_value == "afterword") || normalized_title.include?("afterword")
  end

  def about_author_chapter?
    (special_type_value == "about_author") || normalized_title.include?("about the author") || normalized_title.include?("about author")
  end

  # Get the chapter number (intro doesn't get a number)
  def chapter_number
    return nil if intro_chapter? || epilogue_chapter? || dedication_chapter? || afterword_chapter? || about_author_chapter?

    ordered_ids = Chapter.order_chapters_with_intro_first
               .reject { |chapter| chapter.intro_chapter? || chapter.epilogue_chapter? || chapter.dedication_chapter? || chapter.afterword_chapter? || chapter.about_author_chapter? }
                       .map(&:id)
    chapter_index = ordered_ids.index(id)
    chapter_index ? chapter_index + 1 : nil
  end
end
