class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.text :name, null: false
      t.text :email, null: false
      t.text :password_digest, null: false
      t.text :group
      t.integer :points, default: 0
      t.integer :attempts, default: 0
      t.timestamps
    end
  end
end