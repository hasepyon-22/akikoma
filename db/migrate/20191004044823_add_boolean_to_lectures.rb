class AddBooleanToLectures < ActiveRecord::Migration[5.2]
  def change
    add_column :lectures, :exist, :boolean
  end
end
