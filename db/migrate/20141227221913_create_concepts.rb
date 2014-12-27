class CreateConcepts < ActiveRecord::Migration
  def change
    create_table :concepts do |t|
      t.text :body, null: false
      t.timestamps
   	end
  end
end
