class Guest < ActiveRecord::Base

  belongs_to :user
  belongs_to :concept_user
  
  validates_presence_of :user_id
end
