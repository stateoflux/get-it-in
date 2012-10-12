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
      response.size.must_be :>=, 2
      response['status'].must_equal 200
      response['user'].wont_be :empty?
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
      response.size.must_be :>=, 2
      response['status'].must_equal 200
      response['user'].wont_be :empty?
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


describe "GET api/exercises/:id" do

  describe "when user in not logged in" do
    it "responds with status code 400" do
      get '/api/exercises/1'
      last_response.must_be :client_error?
    end
  end

  describe "when user is logged in" do
    before do
      wayne = FactoryGirl.build(:user_with_exercises)
      login_as(wayne)
      get '/api/exercises/' + wayne.exercises[0].id
    end

    describe "when request succeeds" do
      it "responds with a status code 200" do
        last_response.must_be :successful?
      end

      it "responds with requested exercise json object" do
        last_response.must_be :successful?
        response = JSON.parse(last_response.body)
        response.size.must_be :>=, 3
        response['workout_date'].must_be_instance_of String
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
      post '/api/exercises',
          FactoryGirl.attributes_for(:exercise, name: "squats")
    end

    describe "when request succeeds" do
      it "responds with a status code 200" do
        last_response.must_be :successful?
      end

      it "responds with the newly created exercise object" do
        skip
        response = JSON.parse(last_response.body)
        response['exercise'].wont_be :empty?
        response['exercise']['name'].must_equal 
        response['exercise']['workout_date'].must_equal
        response['exercise']['start_time'].must_equal
        response['exercise']['calories'].must_equal
        response['exercise']['duration'].must_equal 
        response['exercise']['sets'].must_equal 
        response['exercise']['reps'].must_equal 
      end
    end

    describe "when request fails" do
      before do
        get '/api/exercises/7'
      end

      it "responds with status code 404" do
        skip
        last_response.must_be :not_found?
      end

      it "responds with an error json object" do
        skip
        response = JSON.parse(last_response.body)
        response.size.must_be :>=, 2
        response['status'].must_equal 404
        response['reason'].must_be_instance_of String
        response['reason'].wont_be :empty?
      end
    end
  end
end
