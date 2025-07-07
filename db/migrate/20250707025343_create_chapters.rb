class CreateChapters < ActiveRecord::Migration[8.0]
  def change
    create_table :chapters do |t|
      t.string :title
      t.string :subtitle
      t.string :image_header
      t.text :content

      t.timestamps
    end
  end
end
