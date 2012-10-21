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
  # field :token
  has_many :exercises
  # embeds_many :exercises
  accepts_nested_attributes_for :exercises

  # TODO: add security to the hashed_password, salt & token fields
  # attr_accessor allows for virtual attributes
  attr_accessor :password, :password_confirmation

  # per stackoverflow post, the only requirements that names should have are
  # - not zero length
  # - except any and all unicode
  # - reject ^\pM\pC\pZ (need to investigate these chars)
  # http://stackoverflow.com/questions/4718266/advice-on-how-to-validate-names-and-surnames-using-regex
  # html5 regex for email validation: 
  # http://www.whatwg.org/specs/web-apps/current-work/multipage/states-of-the-type-attribute.html#valid-e-mail-address
  validates :first_name,  presence: true,
                          format: { :with => /^\w+$/ }

  validates :last_name,   presence: true,
                          format: { :with => /^\w+$/ }

  validates :email,       presence: true,
                          format: { :with => /^[a-zA-Z0-9.!\#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/ },
                          uniqueness: true

  validates :password,    presence: true,
                          confirmation: true,
                          length: { minimum: 4 }


  def encrypt_password(passwd)
   self.salt = BCrypt::Engine.generate_salt
   self.hashed_password = BCrypt::Engine.hash_secret(passwd, self.salt)
  end

  def self.authenticate(email, pass)
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
  field :workout_timestamp, type: DateTime
  field :duration, type: Integer  # will represent number of mins
  field :sets, type: Integer
  field :reps, type: Integer
  field :distance, type: Float  # in miles
  field :calories, type: Integer
  belongs_to :user
  # embedded_in :workout
  
  # virtual attributes which will be used to create the workout_timestamp 
  # expects a "Zulu" time ISO8601 formatted  string
  # ie. 2009-09-28T19:03:12Z
  attr_accessor :w_timestamp

  validates :name,          presence: true,
                            format: { :with => /^[\w\s]{2,}$/ }
  validates :duration,      presence: true

  validates :w_timestamp,    presence: true
                            # format: { :with => /^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|1\d|2\d|3[0-1])$/ }

  def as_json(options={})
    super(root: true)
  end

  def set_timestamp
    self.workout_timestamp = DateTime.iso8601(w_timestamp)
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
  # rescue ArgumentError
  #  json_status 400, "the workout timestamp does not follow the iso8601 format"
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

delete '/api/exercises/:id' do
  if exercise = current_user.exercises.find(params[:id])
    exercise.destroy
    status 200
  else
    json_status 404, "The requested exercise was not found"
  end
end


# get '/from/:fr_year/:fr_month/:fr_day/to/:to_year/:to_month/:to_day' do
#   "from date: #{params[:fr_year]} #{params[:fr_month]} #{params[:fr_day]}   to date: #{params[:to_year]} #{params[:to_month]} #{params[:to_day]}"
# end



# Misc Handlers
# =============================================================================
get "*" do
  status 404
end

# put_or_post "*" do
#   status 404
# end

delete "*" do
  status 404
end

not_found do
  json_status 404, "Not found"
end

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

