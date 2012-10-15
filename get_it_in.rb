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
Mongoid.load!("mongoid.yml")


# User Model
# =============================================================================
class User
  include Mongoid::Document
  include Mongoid::Timestamps # provides automatic created_at and updated_at attributes
  # all fields below are strings so no need to specify type
  field :first_name
  field :last_name
  field :email
  field :hashed_password
  field :salt
  field :token
  has_many :exercises
  # embeds_many :exercises
  accepts_nested_attributes_for :exercises

  # Validations
  # TODO: determine how to set error messages
  # validates_uniqueness_of   :email
  # validates_format_of       :email, :with =>/\w{4,}/i
  validates_presence_of     :password
  validates_confirmation_of :password
  # validates_length_of       :password, :min => 6

  # TODO: add security to the hashed_password, salt & token fields
  attr_accessor :password, :password_confirmation

  def encrypt_password(passwd)
   self.salt = BCrypt::Engine.generate_salt
   self.hashed_password = BCrypt::Engine.hash_secret(passwd, self.salt)
  end

  def self.authenticate(email, pass)
    # first returns a single document
    current_user = User.find_by(email: email)
    return nil if current_user.nil?
    return current_user if current_user.hashed_password == BCrypt::Engine.hash_secret(pass, current_user.salt)
  end

  def as_json(options={})
    super(:only => [:email])
  end
end

# Exercise Model
# =============================================================================
class Exercise
  include Mongoid::Document
  # TODO: convert duration field to hours & mins fields
  field :name, type: String
  field :workout_date, type: Date
  field :start_time, type: Time
  field :duration, type: Integer  # will represent number of mins
  field :sets, type: Integer
  field :reps, type: Integer
  field :distance, type: Float  # in miles
  field :calories, type: Integer
  belongs_to :user
  # embedded_in :workout

  # Validations
  # validates_presence_of :duration
  # validates_format_of :duration, :with =>/[1-9]{1,5}/
  def as_json(options={})
    super(root: true)
  end
end

# specify the content type (json) for all routes
before do
  content_type :json
end

before '/api/exercises*' do
  halt 400 unless authenticated?
end

# Route Handlers
# =============================================================================
post '/signup' do
  # content_type :json  # TODO is this the standard way of specifying a json response?
  # TODO: determine a way to group form parameters into a hash that I can
  # directly pass to the User.create method
  # ie: user = User.create(params[:user]
  user = User.new(:email => params[:email],
                  :password => params[:password],
                  :password_confirmation => params[:password_confirmation])
  user.encrypt_password(params[:password])
  if user.save
    session[:user] = user.id
    auth_response 200, user
  else
    json_status 400, user.errors.to_hash
  end
end

post '/login' do
  if user = User.authenticate(params[:email], params[:password])
    session[:user] = user.id
    auth_response(200, user)
  else
    json_status 400, "Login credentials are incorrect"
  end
end

get '/logout' do
  session.clear
  { :status => 200 }.to_json
end

get '/' do
   erb :workout_new
end

# a Fake route. Only used for setting the session
# in order to test the API.
# TODO: investigate if possible for this route
# to be valid only in the test environment
# 
post '/set_session/:id' do
  session[:user] = params[:id]
end

get '/api/exercises' do
  if exercises = current_user.exercises
    # TODO: investigate adding metadata to the returned collection
    # such as total count, etc.
    { :exercises => exercises }.to_json
  else
    json_status 404, "The requested exercise was not found"
  end
end

post '/api/exercises' do
  exercise = Exercise.new(params[:exercise])
  current_user.exercises << exercise
  if current_user.save
    exercise.to_json
  else
    json_status 400, current_user.errors.to_hash
  end
end

get '/api/exercises/:id' do
  if exercise = current_user.exercises.find(params[:id])
    exercise.to_json
  else
    json_status 404, "The requested exercise was not found"
  end
end

put '/api/exercises/:id' do
  # TODO: add validation that id param is in the correct format
  if exercise = current_user.exercises.find(params[:id])
    # if the update_attributes method fails what could be the causes?
    # - new attribute, models should not accept new attributes
    # - somehow the attribute/s cause validation to fail
    begin
      if exercise.update_attributes(params[:exercise])
        exercise.to_json
      else
        json_status 400, current_user.errors.to_hash
      end
    rescue Mongoid::Errors::UnknownAttribute
      json_status 400, "Sorry, but you can't add an unknown attribute"
    end
  else
    json_status 404, "The requested exercise was not found"
  end
end

# delete 'api/exercises/:id' do
# end


# post '/' do
  # content_type :json
  # w = current_user.workouts.new(Workout.new)
  # w = Workout.new
  # used to determine if workout is valid or not. if at least one exercise has valid
  # data, then the workout is valid and will be persisted.

get '/logs' do
  # need to investigate the necessary of specifying the content as json via
  content_type :json

  workouts = Workout.asc(:id)
  workouts.to_json
end

get '/from/:fr_year/:fr_month/:fr_day/to/:to_year/:to_month/:to_day' do
  "from date: #{params[:fr_year]} #{params[:fr_month]} #{params[:fr_day]}   to date: #{params[:to_year]} #{params[:to_month]} #{params[:to_day]}"
end

# Misc Handlers
# =============================================================================
error do
  json_status 500, env['sinatra.error'].message
end

# Helpers
# =============================================================================

# Include Rack utils and alias the escape_html function to h()
# actually, do I really need this?  I should catch malformed input at the client side
helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

def authenticated?
  current_user.is_a? User
end

def current_user
  return unless session[:user]
  User.find(session[:user])
end

def json_status(code, reason)
  status code
  {
    :status => code,
    :reason => reason
  }.to_json
end

def auth_response(code, user)
  status code
  {
    :status => code,
    :user => user.to_json
  }.to_json
end

