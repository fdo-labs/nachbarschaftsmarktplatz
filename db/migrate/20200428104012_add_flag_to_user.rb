class AddFlagToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :show_on_map, :boolean
  end
end
