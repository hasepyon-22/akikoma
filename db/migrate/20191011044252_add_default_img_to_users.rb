class AddDefaultImgToUsers < ActiveRecord::Migration[5.2]
  def up
    change_column :users, :img, :string, default: '/assets/green.png'
  end

  def down
    change_column :users, :img, :string
  end
end
