begin
  require_relative 'spec_helper'
rescue NameError
  require File.expand_path('spec_helper', __FILE__)
end

include Rack::Test::Methods

def app() Sinatra::Application end

describe "POST signup" do
  before do
    @email = 'wayne.montague@gmail.com'
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

