require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/reloader'
require 'bcrypt'


require_relative './models/user.rb'
require_relative './models/concept_user.rb'
require_relative './models/concept.rb'
require_relative './models/guest.rb'

enable :sessions

# NOTE: the "Guest" table should actually be called "Guess" but I couldn't figure out how to deal with the irregular plural of "Guesses" when generating my migrations, so Guesses are now just called Guests
# The "conceptuser" table could--more semantically--be called the "Ratings" table.  It is where the ratings are stored; an intersection of particular users and particular concepts (where the user looks at a concept, decides about it, and makes a rating, which is stored in this table)

# helper function to convert info from Guest table to readable stuff 

def convert_rating(number)
	if number == 1
		return "liked"
	elsif number == 2
		return "disliked"
	else
		return "was neutral about"
	end
end

def convert_bool(input)
	input_string = input.to_s
	if input_string == "true"
		return "correct"
	else 
		return "incorrect"
	end
end

helpers do

	def current_user
   	@current_user || nil
	end

  	def current_user?
    @current_user == nil ? false : true
  	end

end

before do

  session[:user] ||= []
  @current_user = User.find_by id: session[:user]
  @errors ||= []

end

# Routes

get '/' do
	@page_name = "Home"
	erb :index
end

get '/signup' do
  @page_name = "Sign up!"
  erb :signup
end

get '/login' do
	@page_name = "Log In"
	erb :login
end

post '/login' do

	# this doesn't make any sense
	# the post form has parameters for email and password_digest, not password
	# but this won't work unless I call for the params of [:password]

	# also, if user in database but not set up originally through BCrypt, throws a server error

	user = User.find_by(:email => params[:email])

	if user && user.authenticate(params[:password])
		session[:user] = user.id
		redirect('/')
	else
		@errors << "Username or password incorrect!"
		erb :login
  	end

end

get '/concept' do
	@concepts = Concept.all

	@page_name = "Make your ratings"

	# if not logged in, direct to log in
	if session[:user] == []
		@errors << "You must log in to make a guess!"
		redirect('/login')
	end
  
  	# all the ratings where the user rated
  	@ratings = @current_user.concept_users
  	
  	@concept_ids_for_rated_items = []

  	# show all of the concepts that the user has not rated

  	# take each rating where user rated, and collect the concept ids
  	@ratings.each do |rating|
  		@concept_ids_for_rated_items << rating.concept_id
  	end

  	# grab all the concepts
	@all_concepts = Concept.all

	@all_concept_id_holder = []

	# take each of the concepts and get the concept id for each one, putting into array
	@all_concepts.each do |concept|
		@all_concept_id_holder << concept.id
	end

	# subtract the concepts where user rated from all the concepts
	@unrated_concepts = @all_concept_id_holder - @concept_ids_for_rated_items

  	erb :concept
end

post '/signup' do
	user = User.new(params)

	if user.save
		session[:user] = user.id
		redirect('/')
	else
		@user = user
		erb :signup
	end
end


post '/concept' do
	# params.inspect
	# example: {"rating"=>"21"}

	# like, dislike, or neutral
	rating = params["rating"][0].to_i

	concept_id = params["rating"]

	# cuts off the rating just leaving the concept id behind
	concept_id.slice!(0).to_i

	ConceptUser.create(user_id: @current_user.id, concept_id: concept_id, rating: rating)

	redirect('/concept')
end

get '/leaderboard' do
	@page_name = "Leaderboard"
	all_users_leaderboard = User.allå

	@scores_array = []

	all_users_leaderboard.each do |user|
		points = user.points

		attempts = Guest.where user_id: user.id
		attempts_length = attempts.length
		

		if attempts_length >= 1
			average = ((points.to_f / attempts_length) * 100).to_i
			@scores_array << { user.id => average }
			
		end

	end

	erb :leaderboard
end

get '/clear' do
	session.clear
	redirect('/')	
end

get '/guess' do

	# if not logged in, direct to log in
	if session[:user] == []
		redirect('/login')
	end

	# Get all of the ratings and subtract out ratings where 1) the user made a guess previously, or 2) the user made the rating herself.

	@page_name = "Guess what others think..."


	# get the User's group
	# get each person in the user's group, and get each of their concept user items

	@user_group = @current_user.group

	@users_in_users_group = User.where(group: @user_group)
	# figure out way to show concept_user items for these people ONLY

	@users_in_users_group_ids = []
	# get the user id for each user in the user's group

	@users_in_users_group.each do |user|
		@users_in_users_group_ids << user.id 
	end

	# all the ConceptUser items associated with the user
	@where_user_rated = @current_user.concept_users 

	# get the conceptuser id from each and store them in an array,
	@concept_user_id_rated = []

	@where_user_rated.each do |concept|
		@concept_user_id_rated << concept.id.to_i
	end


	# get all of the Guest ids where the user made a guess

	@where_user_guessed = @current_user.guests

	# go through each of the Guest items, and take out the concept id

	@concept_users_where_guessed = []

	@where_user_guessed.each do |guess|
		@concept_users_where_guessed << ConceptUser.find(guess.concept_user_id).id
	end
	


	# get all of the conceptuser (ratings) items


	@all_ratings = ConceptUser.where(:user_id => @users_in_users_group_ids)


	@all_ratings_id = []

	@all_ratings.each do |rating|
		@all_ratings_id << rating.id.to_i
	end

	# subtract all of the conceptuser (ratings) item where the user has rated
	
	@ratings_where_user_not_rated = @all_ratings_id - @concept_user_id_rated - @concept_users_where_guessed

	erb :guess
end

get '/test' do
	erb :test
end

post '/guess' do
	# remember, rating is the same as conceptuser

	guess_and_rating_id = params["guess"].split("--")
	guess = guess_and_rating_id[0].to_i
	rating_id = guess_and_rating_id[1].to_i

	focus_rating = ConceptUser.find(rating_id)

	# check if the user guessed correctly
	if focus_rating.rating == guess

	# if guessed correctly, create a Guess item with True for for the outcome attribute
		Guest.create(user_id: @current_user.id, concept_user_id: rating_id, outcome: true)
		
		# add a point to the user for a correct guess
		user = User.find(@current_user.id)
		points = user.points
		points += 1
		user.update(points: points)

		redirect('/guess')
	# else, create a Guess item with False for the outcome attribue

	else 
		Guest.create(user_id: @current_user.id, concept_user_id: rating_id, outcome: false)

		#Guest.create(user_id: @current_user.id, rating_id: rating_id, outcome: false)
		redirect('/guess')
	end

end


#binding.pry

