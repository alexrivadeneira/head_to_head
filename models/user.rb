class User < ActiveRecord::Base
  
  has_many :guests
  has_many :concept_users
  has_many :concepts, through: :concept_users

  validates_presence_of :group
  # attributes
  attr_accessor :password

  # callbacks
  before_save :encrypt_password

  # validations
  validates_confirmation_of :password
  validates_presence_of :password, :on => :create
  validates :name,
    :presence => true,
    :length => { maximum: 255 }
  validates :email,
    :presence => true,
    :uniqueness => { case_sensitive: false },
    :length => { maximum: 255 },
    :format => { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i }

  # methods
  def authenticate(password)
    if BCrypt::Password.new(self.password_digest) == password
      return self
    else
      return nil
    end
  end

  def encrypt_password
    if password.present?
      return self.password_digest = BCrypt::Password.create(password)
    end
  end

end