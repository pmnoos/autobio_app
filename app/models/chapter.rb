class Chapter < ApplicationRecord
  has_rich_text :content
  has_one_attached :image_header

  validates :title, presence: true
  validates :content, presence: true

  # Scope to order: Dedication → Introduction → numbered → Epilogue
  # Uses special_type if column exists; falls back to title detection otherwise.
  scope :order_chapters_with_intro_first, -> {
    begin
      if ActiveRecord::Base.connection.schema_cache.columns_hash("chapters").key?("special_type")
        order(Arel.sql("CASE \
          WHEN special_type = 'dedication' OR (special_type IS NULL AND (LOWER(title) LIKE '%dedication%' OR LOWER(title) LIKE '%didication%')) THEN 0 \
          WHEN special_type = 'introduction' OR (special_type IS NULL AND LOWER(title) LIKE '%intro%') THEN 1 \
          WHEN special_type = 'epilogue' OR (special_type IS NULL AND LOWER(title) LIKE '%epilogue%') THEN 3 \
          ELSE 2 END, created_at ASC"))
      else
        order(Arel.sql("CASE \
          WHEN LOWER(title) LIKE '%dedication%' OR LOWER(title) LIKE '%didication%' THEN 0 \
          WHEN LOWER(title) LIKE '%intro%' THEN 1 \
          WHEN LOWER(title) LIKE '%epilogue%' THEN 3 \
          ELSE 2 END, created_at ASC"))
      end
    rescue
      order(created_at: :asc)
    end
  }

  def special_type_value
    has_attribute?(:special_type) ? (self[:special_type].to_s) : ""
  end

  # Helper method to check if this is the intro chapter
  def intro_chapter?
    (special_type_value == "introduction") || title.downcase.include?("intro")
  end

  # Helper method to check if this is the epilogue chapter
  def epilogue_chapter?
    (special_type_value == "epilogue") || title.downcase.include?("epilogue")
  end

  # Helper method to check if this is the dedication page
  def dedication_chapter?
    (special_type_value == "dedication") || title.downcase.include?("dedication") || title.downcase.include?("didication")
  end

  # Get the chapter number (intro doesn't get a number)
  def chapter_number
    return nil if intro_chapter? || epilogue_chapter? || dedication_chapter?

    # Count non-intro chapters created before this one, plus 1
    if has_attribute?(:special_type)
      Chapter.where("created_at < ? AND (special_type IS NULL OR special_type NOT IN ('introduction','epilogue','dedication')) AND LOWER(title) NOT LIKE '%intro%' AND LOWER(title) NOT LIKE '%epilogue%' AND LOWER(title) NOT LIKE '%dedication%' AND LOWER(title) NOT LIKE '%didication%'", created_at).count + 1
    else
      Chapter.where("created_at < ? AND LOWER(title) NOT LIKE '%intro%' AND LOWER(title) NOT LIKE '%epilogue%' AND LOWER(title) NOT LIKE '%dedication%' AND LOWER(title) NOT LIKE '%didication%'", created_at).count + 1
    end
  end
end
