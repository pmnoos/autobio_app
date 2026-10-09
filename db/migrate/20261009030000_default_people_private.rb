class DefaultPeoplePrivate < ActiveRecord::Migration[8.0]
  def change
    change_column_default :people, :private_profile, from: false, to: true
  end
end
