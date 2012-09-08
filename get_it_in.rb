require 'sinatra'
require 'mongoid'
# require 'slim'
require 'json'
require "sinatra/reloader" if development?
# TODO: add gems below to Gemfile and use bundler to handle dependencies
require 'bcrypt'
require 'securerandom'

# to protect session data
use Rack::Session::Cookie, :secret => 'A1 sauce 1s so good you should use 1t on a11 yr st34ksssss'

# load the mondodb configuration file
# what is the name of this application's db?
# - get_it_in
Mongoid.load!("mongoid.yml")

# Include Rack utils and alias the escape_html function to h()
# actually, do I really need this?  I should catch malformed input at the client side
helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

# Model definition
# Can I also include validations here ala rails? Yes.
# need to add validations
# TODO: How do I update the database schema??

# User Model
# =============================================================================
# User Model is based on codebiff article & sinatra-authentication mongoid_user 
# Model
# http://codebiff.com/roll-your-own-sinatra-authentication
# https://github.com/maxjustus/sinatra-authentication/blob/master/lib/models/mongoid_user.rb
class User
  include Mongoid::Document
  include Mongoid::Timestamps # what are Timestamps used for?
  # all fields below are strings so no need to specify type
  field :user_name
  field :hashed_password
  field :salt
  field :token
  embeds_many :workouts

  # Validations
  # TODO: determine how to set error messages
  validates_uniqueness_of   :user_name
  validates_format_of       :user_name, :with =>/\w{4,}/i
  # validates_presence_of     :password
  # validates_confirmation_of :password
  # validates_length_of       :password, :min => 6

  attr_accessor :password, :password_confirmation

  def encrypt_password(passwd)
   self.salt = BCrypt::Engine.generate_salt
   self.hashed_password = BCrypt::Engine.hash_secret(passwd, self.salt)
  end

  def self.authenticate(name, pass)
    # first returns a single document
    current_user = User.first(conditions: {user_name: name})
    return nil if current_user.nil?
    return current_user if current_user.hashed_password == BCrypt::Engine.hash_secret(pass, current_user.salt)
  end
end

class Workout
  include Mongoid::Document
  # field :complete, type: Boolean, :required => true, :default => false # not sure why this complete field is here?
  field :created_at, type: Date
  field :updated_at, type: Date
  embedded_in :user
  embeds_many :exercises
end

class Exercise
  include Mongoid::Document
  # TODO: convert duration field to hours & mins fields
  field :exercise_name, type: String
  field :duration, type: Integer  # will represent number of mins
  embedded_in :workout

  # Validations
  validates_presence_of :duration
  # validates_format_of :duration, :with =>/[1-9]{1,5}/
end

class StrengthExercise < Exercise
  field :sets, type: Integer
  field :reps, type: Integer

  # Validations
  validates_presence_of :reps
  validates_format_of :reps, :with =>/[1-9]{1,4}/
end

class CardioExercise < Exercise
  field :distance, type: Float  # in miles
  field :calories, type: Integer

  # Validations
  validates_presence_of :distance
  # validates_format_of :distance, :with =>/\d{1,4}\.\d{1,4}/
  validates_presence_of :calories
  # validates_format_of :calories, :with =>/[1-9]{1,5}/
end


# Route Handlers
# =============================================================================
 post '/signup' do
   # TODO: determine a way to group form parameters into a hash that I can
   # directly pass to the User.create method
   # ie: user = User.create(params[:user]
   user = User.new(:user_name => params[:user_name],
                   :password => params[:password],
                   :password_confirmation => params[:password_confirmation])
   user.encrypt_password(params[:password])
   if user.save
     session[:user] = user.id
     # redirect "/"
   else
     # not sure if this is a correct Rack response
     [500, ['Oops! There were some problems creating your account.']]
     # redirect "/signup?email=#{params[:user][:email]}"
     # return some type of error status
     # puts "user was not saved cos of following errors: #{user.errors[:password]}"

   end
 end

post '/login' do
  # User.first?
  # going to follow the sinatra-authentication logic instead of codebiff article
  if user = User.authenticate(params[:user_name], params[:password])
    session[:user] = user.id
  #if user = User.first(:user_name => params[:user_name])
    #if user.password_hash == BCrypt::Engine.hash_secret(params[:password], user.salt)
    #session[:user] = user.token 
    # redirect "/"
  else
    # redirect "/login?user_name=#{params[:user_name]}"
    [500, ['Oops! There is something wrong with either your username or password.']]
  end
end

get '/logout' do
end

# TODO: investigate the correct route to use to access the workout resource/s
get '/' do
  # does mongoid specify order this way?
  # @workouts = Workout.asc(:id)
   erb :workout_new
end

post '/' do
  content_type :json
  # w = current_user.workouts.new(Workout.new)
  w = Workout.new
  # used to determine if workout is valid or not. if at least one exercise has valid
  # data, then the workout is valid and will be persisted.
  wo_valid = false

  # TODO: DRY this up
  1.upto(params[:st_cnt].to_i) do |i|
    # check that reps field has data. if no data, assume user has not entered a
    # valid exercise and do not create one.
    reps = params["st_reps#{i}".to_sym]
    unless reps.empty?
      wo_valid = true
      st = StrengthExercise.new
      st.exercise_name = params["st_exercise#{i}".to_sym]
      st.sets = params["st_sets#{i}".to_sym].to_i
      st.reps = reps.to_i
      w.exercises << st
    end
  end

  1.upto(params[:ca_cnt].to_i) do |i|
    # same as reps above
    cals = params["ca_calories#{i}".to_sym]
    unless cals.empty?
      wo_valid = true
      ca = CardioExercise.new
      ca.exercise_name = params["ca_exercise#{i}".to_sym]
      puts params
      ca.duration = params["ca_duration#{i}".to_sym].to_f
      ca.distance = params["ca_distance#{i}".to_sym].to_f
      ca.calories = cals
      #ca.calories = params["calories#{i}".to_sym]
      w.exercises << ca
    end
  end
  # TODO: add logic that does not create workout if no exercise is valid
  # DONE
  if (wo_valid)
    w.created_at = Time.now
    w.updated_at = Time.now
    # TODO:
    # need to verify that the save operation completed successfully
    # have server update the "flash" if an error occurs.
    # add validation to the Workout and Exercise models
    # save workout to current_user's workout collection
    puts "DEBUG: about to push workout on workouts collection"
    current_user.workouts << w
    puts "DEBUG: about to save current_user"
    current_user.save
    # w.save
    # respond with current workout object
    # should I respond with workout object here or should i move to the "single retrieve" action
    w.to_json
  end
end

get '/logs' do
  # need to investigate the necessary of specifying the content as json via
  content_type :json

  workouts = Workout.asc(:id)
  workouts.to_json
end

# Helpers
# =============================================================================
def current_user
  return unless session[:user]
  puts "session[:user] is valid"
  User.find(session[:user])
end

