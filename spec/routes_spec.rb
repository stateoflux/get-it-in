begin
  require_relative 'spec_helper'
rescue NameError
  require File.expand_path('spec_helper', __FILE__)
end

include Rack::Test::Methods

def app() Sinatra::Application end

# TODO: remove the coupling between the authentication test cases and User model
describe "POST signup" do
  before do
    @user_attrs = { :user => FactoryGirl.attributes_for(:user) }
    # @email = 'wayne.montague@zmail.com'
    # @passwd = 'zion'
  end

  describe "when signup succeeds" do
    before do
      # pp @user_attrs
      post '/signup', @user_attrs
      # post '/signup', :email => @email, :password => @passwd,
      #  :password_confirmation => @passwd
    end

    it "responds with status code 200" do
      last_response.must_be :successful?
    end

    it "responds with a 'success' json object" do
      response = JSON.parse(last_response.body)
      response.size.must_be :>=, 2
      response['status'].must_equal 200
      response['user'].wont_be :empty?
    end
  end

  describe "when signup fails" do
    before do
      @user_attrs = { :user => FactoryGirl.attributes_for(:user, :password_confirmation => "zion1") }
      post '/signup', @user_attrs
    end

    it "responds with status code 400" do
      last_response.must_be :client_error?
    end

    it "responds with an 'error' json object" do
      response = JSON.parse(last_response.body)
      response['status'].must_equal 400
      response['reason'].must_be_instance_of Hash
      response['reason'].wont_be :empty?
    end
  end
end

describe "POST login" do
  before do
    @user_attrs = { :user => FactoryGirl.attributes_for(:user, first_name: nil,
                                                        last_name: nil,
                                                        password_confirmation: nil) }
  end

  describe "when login succeeds" do
    before do
      mock(User).authenticate(@user_attrs[:user][:email],
                              @user_attrs[:user][:password]).returns(FactoryGirl.build(:user))
      post '/login', @user_attrs
    end

    it "responds with status code 200" do
      last_response.must_be :successful?
    end

    it "responds with a 'success' json object" do
      response = JSON.parse(last_response.body)
      response.size.must_be :>=, 2
      response['status'].must_equal 200
      response['user'].wont_be :empty?
    end
  end

  describe "when login fails" do
    before do
      mock(User).authenticate(@user_attrs[:user][:email],
                              @user_attrs[:user][:password]).returns(false)
      post '/login', @user_attrs
    end

    it "responds with status code 400" do
      last_response.must_be :client_error?
    end

    it "responds with an 'error' json object" do
      response = JSON.parse(last_response.body)
      response.size.must_equal 2
      response['status'].must_equal 400
      response['reason'].must_be_instance_of String
      response['reason'].wont_be :empty?
    end
  end
end

describe "GET logout" do
  before do
    get '/logout'
  end

  it "responds with status code 200" do
    last_response.must_be :successful?
  end

  it "responds with a 'success' json object" do
    response = JSON.parse(last_response.body)
    response.size.must_equal 1
    response['status'].must_equal 200
  end
end

# exerciseS API
# =============================================================================
# Will need to simulate a logged in user
# how do i simulate?
# what determines that a user is logged in?
# - session[:user] is not nil.
# need to populate session with a user id
# id needs to correspond to a user in db.
# how do I populate the session?
# can I access the session object from the Rack::Test Environment?
# according to stackoverflow post:
# http://stackoverflow.com/questions/7695775/sinatra-racktest-rspec2-using-sessions
# I will have to add a route within the application that will allow
# me to set the session object.
# will create this as a method within spec_helper.rb



describe "POST api/exercises" do

  describe "when user in not logged in" do
    it "responds with status code 400" do
      post '/api/exercises'
      last_response.must_be :client_error?
    end
  end

  describe "when user is logged in" do
    before do
      @wayne = FactoryGirl.build(:user_with_exercises)
      login_as(@wayne)
      @squats = FactoryGirl.attributes_for(:exercise, name: "squats")
      # @squats = FactoryGirl.attributes_for(:exercise, name: "squats", w_timestamp: DateTime.now.utc.to_s)
    end

    describe "when request succeeds" do
      before do
        stub(@wayne).save { true }
        post '/api/exercises', :exercise => @squats
      end
      
      it "responds with a status code 200" do
        last_response.must_be :successful?
      end

      it "responds with the newly created exercise object" do
        response = JSON.parse(last_response.body)
        response['exercise'].wont_be :empty?
        response['exercise']['name'].must_equal @squats[:name]
        # response['exercise']['workout_timestamp'].must_equal @squats[:w_timestamp]
        response['exercise']['calories'].must_equal @squats[:calories]
        response['exercise']['duration'].must_equal @squats[:duration]
        response['exercise']['sets'].must_equal @squats[:sets]
        response['exercise']['reps'].must_equal @squats[:reps]
      end
    end

    describe "when request fails" do
      before do
        stub(@wayne).save { false }
        post '/api/exercises', @squats
      end

      it "responds with status code 400" do
        last_response.must_be :client_error?
      end

      it "responds with an error json object" do
        response = JSON.parse(last_response.body)
        response.size.must_be :>=, 2
        response['status'].must_equal 400
        response['reason'].must_be_instance_of Hash
        # response['reason'].wont_be :empty?
      end
    end
  end
end


describe "GET api/exercises" do

  describe "when user in not logged in" do
    it "responds with status code 400" do
      get '/api/exercises'
      last_response.must_be :client_error?
    end
  end

  describe "when user is logged in" do
    before do
      @wayne = FactoryGirl.build(:user_with_exercises)
      login_as(@wayne)
      get '/api/exercises'
    end

    describe "when request succeeds" do
      
      it "responds with a status code 200" do
        last_response.must_be :successful?
      end

      it "responds with exercises object" do
        response = JSON.parse(last_response.body)
        response['exercises'].must_be_instance_of Array
      end
    end

    # right now, I can't think of a scenerio where the request would fail
    # unless some type of exception was thrown by Mongoid.
  end
end

describe "GET api/exercises/:id" do

  describe "when user in not logged in" do
    it "responds with status code 400" do
      get '/api/exercises/1'
      last_response.must_be :client_error?
    end
  end

  describe "when user is logged in" do
    before do
      @wayne = FactoryGirl.build(:user_with_exercises)
      login_as(@wayne)
      get '/api/exercises/' + @wayne.exercises[0].id
    end

    describe "when request succeeds" do
      it "responds with a status code 200" do
        last_response.must_be :successful?
      end

      it "responds with requested exercise json object" do
        last_response.must_be :successful?
        response = JSON.parse(last_response.body)
        response['exercise'].wont_be :empty?
        response['exercise']['name'].must_equal @wayne.exercises[0][:name]
        # response['exercise']['workout_timestamp'].must_equal @wayne.exercises[0][:w_timestamp]
        response['exercise']['calories'].must_equal@wayne.exercises[0][:calories]
        response['exercise']['duration'].must_equal @wayne.exercises[0][:duration]
        response['exercise']['sets'].must_equal @wayne.exercises[0][:sets]
        response['exercise']['reps'].must_equal @wayne.exercises[0][:reps]
      end
    end

    describe "when request fails" do
      before do
        get '/api/exercises/7'
      end

      it "responds with status code 404" do
        last_response.must_be :not_found?
      end

      it "responds with an error json object" do
        response = JSON.parse(last_response.body)
        response.size.must_be :>=, 2
        response['status'].must_equal 404
        response['reason'].must_be_instance_of String
        response['reason'].wont_be :empty?
      end
    end
  end
end

describe "PUT api/exercises/:id" do

  describe "when user in not logged in" do
    it "responds with status code 400" do
      put '/api/exercises'
      last_response.must_be :client_error?
    end
  end

  describe "when user is logged in" do
    before do
      @wayne = FactoryGirl.build(:user_with_exercises)
      login_as(@wayne)
    end

    describe "when request succeeds" do
      before do
        stub(@wayne).save { true }
        put '/api/exercises/' + @wayne.exercises[0].id, :exercise => {name: "running", distance: "4"}
      end
      
      it "responds with a status code 200" do
        last_response.must_be :successful?
      end

      it "responds with the newly created exercise object" do
        response = JSON.parse(last_response.body)
        response['exercise'].wont_be :empty?
        response['exercise']['name'].must_equal "running"
        response['exercise']['distance'].must_equal 4
        # response['exercise']['workout_timestamp'].must_equal @wayne.exercises[0][:w_timestamp]
        response['exercise']['calories'].must_equal@wayne.exercises[0][:calories]
        response['exercise']['duration'].must_equal @wayne.exercises[0][:duration]
        response['exercise']['sets'].must_equal @wayne.exercises[0][:sets]
        response['exercise']['reps'].must_equal @wayne.exercises[0][:reps]
      end
    end

    describe "when exercise not found" do
      before do
        put '/api/exercises/7', :exercise => {name: "running", distance: "4"}
      end

      it "responds with status code 404" do
        last_response.must_be :not_found?
      end

      it "responds with an error json object" do
        response = JSON.parse(last_response.body)
        response.size.must_be :>=, 2
        response['status'].must_equal 404
        response['reason'].must_be_instance_of String
        # response['reason'].wont_be :empty?
      end
    end

    describe "when an attribute has an error" do
      before do
        stub(@wayne.exercises[0]).update_attributes { false }
        put '/api/exercises/' + @wayne.exercises[0].id, :exercise => {name: "running"}
      end

      it "responds with status code 400" do
        last_response.must_be :client_error?
      end

      it "responds with an error json object" do
        response = JSON.parse(last_response.body)
        response.size.must_be :>=, 2
        response['status'].must_equal 400
        response['reason'].must_be_instance_of Hash
        # response['reason'].wont_be :empty?
      end
    end

    describe "when adding an unknown attribute is attempted" do
      before do
        # TODO: will have to investigate how to stop dynamic attributes being added to Models
        # - set allow_dynamic_fields to false in mongoid config file
        # Mongoid throws a Mongoid::Errors::UnknownAttribute since I'm trying to add a beer attribute to
        # the exercise model.  How should I handle this exception in my app?
        # I tried using an "error" block, but it doesn't seem to work.
        # - i ended up using a rescue block
        put '/api/exercises/' + @wayne.exercises[0].id, :exercise => {name: "running", beer: "4"}
      end

      it "responds with status code 400" do
        last_response.must_be :client_error?
      end

      it "responds with an error json object" do
        response = JSON.parse(last_response.body)
        response.size.must_be :>=, 2
        response['status'].must_equal 400
        response['reason'].must_be_instance_of String
        # response['reason'].wont_be :empty?
      end
    end
  end
end


describe "delete api/exercises/:id" do

  describe "when user in not logged in" do
    it "responds with status code 400" do
      delete '/api/exercises/1'
      last_response.must_be :client_error?
    end
  end

  describe "when user is logged in" do
    before do
      @wayne = FactoryGirl.build(:user_with_exercises)
      login_as(@wayne)
      delete '/api/exercises/' + @wayne.exercises[0].id
    end

    describe "when request succeeds" do
      it "responds with a status code 200" do
        last_response.must_be :successful?
      end
    end

    describe "when request fails" do
      before do
        delete '/api/exercises/7'
      end

      it "responds with status code 404" do
        last_response.must_be :not_found?
      end

      it "responds with an error json object" do
        response = JSON.parse(last_response.body)
        response.size.must_be :>=, 2
        response['status'].must_equal 404
        response['reason'].must_be_instance_of String
        response['reason'].wont_be :empty?
      end
    end
  end
end
