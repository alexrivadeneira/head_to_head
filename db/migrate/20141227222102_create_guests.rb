class CreateGuests < ActiveRecord::Migration
  def change
    create_table :guests do |t|
      t.integer :user_id, null: false
      t.integer :concept_user_id, null: false
      t.boolean :outcome, null: false
      t.timestamps
    end
  end
end