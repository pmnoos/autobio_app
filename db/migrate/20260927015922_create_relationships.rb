class CreateRelationships < ActiveRecord::Migration[8.0]
  def change
    create_table :relationships do |t|
      t.references :person, null: false, foreign_key: true
      t.references :related_person, null: false, foreign_key: { to_table: :people }
      t.integer :relationship_type
      t.date :start_date
      t.date :end_date
      t.text :notes

      t.timestamps
    end
  end
end
