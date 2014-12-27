class ConceptUser < ActiveRecord::Base

  belongs_to :user
  belongs_to :concept
  has_many :guests
  
  validates_presence_of :user_id
end