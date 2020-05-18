class AddExternalWebsiteToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :external_website, :string
  end
end
