class CreateTable < ActiveRecord::Migration[5.2]
  def change
    create_table :lectures do |t|
       t.string :day
       t.integer :period
       t.string :name
    end

    create_table :users do |t|
      t.string :name
      t.string :password_digest
      t.timestamps null: false
    end

    create_table :users_lectures do |t|
      t.references :lecture, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true
    end
  end

end
