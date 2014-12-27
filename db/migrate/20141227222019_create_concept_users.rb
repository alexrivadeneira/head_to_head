class CreateConceptUsers < ActiveRecord::Migration
  def change
    create_table :concept_users do |t|
      t.integer :user_id, null: false
      t.integer :concept_id, null: false
      t.integer :rating
      t.timestamps
    end
  end
end

