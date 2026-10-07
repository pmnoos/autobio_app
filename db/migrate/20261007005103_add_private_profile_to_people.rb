class AddPrivateProfileToPeople < ActiveRecord::Migration[8.0]
  def change
    add_column :people, :private_profile, :boolean, default: false, null: false
  end
end