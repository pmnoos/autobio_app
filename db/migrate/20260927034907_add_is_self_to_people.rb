class AddIsSelfToPeople < ActiveRecord::Migration[8.0]
  def change
    add_column :people, :is_self, :boolean, default: false, null: false
  end
end
