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

    it "responds with a success status code (200) when user is valid" do
      last_response.must_be :successful?
    end

    it "responds with a 'success' json object when user is valid" do
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

    it "responds with a client error status code (400) when user is invalid" do
      last_response.must_be :client_error?
    end

    it "responds with an 'error' json object when user is invalid" do
      response = JSON.parse(last_response.body)
      response.size.must_equal 2
      response['success'].must_equal false
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
      # stub out the authenticate method
      class User
        def self.authenticate(email, pass)
          FactoryGirl.build(:user)
        end
      end
      post '/login', :email => @email, :password => @passwd
    end

    it "responds with a success status code (200) when user is valid" do
      last_response.must_be :successful?
    end

    it "responds with a 'success' json object when user is valid" do
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

    it "responds with a client error status code (400) when user is invalid" do
      last_response.must_be :client_error?
    end

    it "responds with an 'error' json object when user is invalid" do
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

  it "responds with a success status code (200)" do
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


describe "GET workouts/:id" do
  describe "when request succeeds" do
    it "responds with requested workout json object" do
    end
  end

  describe "when request fails" do
    it "responds with an 'error' json object" do
    end
  end
end
