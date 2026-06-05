class Photo < ApplicationRecord
  has_one_attached :image

  validates :title, presence: true
  validates :image, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_date, -> { order(taken_at: :desc, created_at: :desc) }
  # Position first (nulls last), then fall back to taken_at / created_at
  scope :by_position, -> {
    order(Arel.sql("COALESCE(\"photos\".\"position\", 2147483647) ASC"), taken_at: :desc, created_at: :desc)
  }
end
