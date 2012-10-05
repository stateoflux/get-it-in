begin
  require_relative 'spec_helper'
rescue NameError
  require File.expand_path('spec_helper', __FILE__)
end

include Rack::Test::Methods

def app() Sinatra::Application end

describe "POST signup" do
  before do
    @email = 'wayne.montague@zmail.com'
    @passwd = 'zion'
  end

  describe "when signup succeeds" do
    before do
      post '/signup', :email => @email, :password => @passwd,
        :password_confirmation => @passwd
    end

    it "responds with status code 200" do
      last_response.must_be :successful?
    end

    it "responds with a 'success' json object" do
      response = JSON.parse(last_response.body)
      response.size.must_equal 2
      response['success'].must_equal true
      response['email'].must_equal @email
    end
  end

  describe "when signup fails" do
    before do
      post '/signup', :email => @email, :password => @passwd,
        :password_confirmation => "zion1"
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
    @passwd = 'zion'
    # same as default email field in User factory
    # would be nice to figure out how to remove this dependency
    @email = 'wayne.montague@zmail.com'
  end

  describe "when login succeeds" do
    before do
      # hmmm, the test case is looking for email & pass, not sure why.  will have to investigate
      # mock(User).authenticate(email, pass).returns(FactoryGirl.build(:user))
       # stub out the authenticate method
       class User
         def self.authenticate(email, pass)
           FactoryGirl.build(:user)
         end
       end
      post '/login', :email => @email, :password => @passwd
    end

    it "responds with status code 200" do
      last_response.must_be :successful?
    end

    it "responds with a 'success' json object" do
      response = JSON.parse(last_response.body)
      response.size.must_equal 2
      response['success'].must_equal true
      response['email'].must_equal @email
    end
  end

  describe "when login fails" do
    before do
      # stub out the authenticate method
      class User
        def self.authenticate(email, pass)
          false
        end
      end
      post '/login', :email => @email, :password => @passwd
    end

    it "responds with status code 400" do
      last_response.must_be :client_error?
    end

    it "responds with an 'error' json object" do
      response = JSON.parse(last_response.body)
      response.size.must_equal 2
      response['success'].must_equal false
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
    response['success'].must_equal true
  end
end

# WORKOUTS API
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


describe "GET api/workouts/:id" do

  describe "when user in not logged in" do
    it "responds with status code 400" do
      get '/api/workouts/1'
      last_response.must_be :client_error?
    end
  end

  describe "when user is logged in" do
    before do
      class User
        # override the _id method since by default it returns an ObjectId
        # which cannot be converted to a string.
        field :_id, type: String, default: "007"

        def self.add_user(user)
          @@user = user
        end
        def self.find(id)
          @@user
        end

        def self.workout_id
          @@user.workouts[0].id
        end
      end

      class Workout
        field :_id, type: String, default: "1"
      end

      wayne = FactoryGirl.build(:user_with_workouts)
      User.add_user(wayne)
      set_session(wayne.id)
    end

    describe "when request succeeds" do
      it "responds with a status code 200" do
        get '/api/workouts/' + User.workout_id
        last_response.must_be :successful?
      end

      it "responds with requested workout json object" do
        get '/api/workouts/' + User.workout_id
        last_response.must_be :successful?
        response = JSON.parse(last_response.body)
        response['workout_date'].must_be_instance_of String  # why is this a string? shouldn't this be a Date object?
        response['exercises'].must_be_instance_of Array
        response['exercises'][0].size.must_be :>=, 4
        response['exercises'].wont_be :empty?
      end
    end

    describe "when request fails" do
      before do
        get '/api/workouts/7'
      end

      it "responds with status code 404" do
        last_response.must_be :not_found?
      end

      it "responds with an error json object" do
        skip
        response = JSON.parse(last_response.body)
        response.size.must_equal 2
        response['success'].must_equal false
        response['reason'].must_be_instance_of String
        response['reason'].wont_be :empty?
      end
    end
  end
end
