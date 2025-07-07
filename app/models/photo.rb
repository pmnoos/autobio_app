class Photo < ApplicationRecord
  has_one_attached :image
  
  validates :title, presence: true
  validates :image, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_date, -> { order(taken_at: :desc, created_at: :desc) }
end
