class CreatePeople < ActiveRecord::Migration[8.0]
  def change
    create_table :people do |t|
      t.string :first_name
      t.string :last_name
      t.string :maiden_name
      t.date :birth_date
      t.date :death_date
      t.string :birth_place
      t.string :death_place
      t.string :gender
      t.text :bio_notes

      t.timestamps
    end
  end
end
