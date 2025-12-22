class AddSpecialTypeToChapters < ActiveRecord::Migration[8.0]
  def change
    add_column :chapters, :special_type, :string
    add_index :chapters, :special_type
  end
end
