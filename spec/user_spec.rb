begin
  require 'test_helper'
rescue NameError
  require File.expand_path('test_helper', __FILE__)
end

include Rack::Test::Methods

def app() Sinatra::Application end

describe String do
  it "always true" do
    "hey now".must_be_instance_of String
  end
end
