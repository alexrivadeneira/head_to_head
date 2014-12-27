class Concept < ActiveRecord::Base

  has_many :users, through: :concept_users
  has_many :concept_users
  
  validates_presence_of :body

end