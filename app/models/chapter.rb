class Chapter < ApplicationRecord
  has_rich_text :content
  has_one_attached :image_header
  
  validates :title, presence: true
  validates :content, presence: true
  
  # Scope to order chapters with intro first, then by creation order
  scope :order_chapters_with_intro_first, -> {
    order(Arel.sql("CASE WHEN LOWER(title) LIKE '%intro%' THEN 0 ELSE 1 END, created_at ASC"))
  }
  
  # Helper method to check if this is the intro chapter
  def intro_chapter?
    title.downcase.include?('intro')
  end
  
  # Get the chapter number (intro doesn't get a number)
  def chapter_number
    return nil if intro_chapter?
    
    # Count non-intro chapters created before this one, plus 1
    Chapter.where("created_at < ? AND LOWER(title) NOT LIKE '%intro%'", created_at).count + 1
  end
end
