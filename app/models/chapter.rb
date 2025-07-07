class Chapter < ApplicationRecord
  has_rich_text :content
  has_one_attached :image_header
  
  validates :title, presence: true
  validates :content, presence: true
end
