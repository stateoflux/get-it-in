ENV['RACK_ENV'] = 'test'
require 'turn/autorun'
# require 'minitest/autorun'
require 'rack/test'
require 'factory_girl'
require 'database_cleaner'

begin
  require_relative '../get_it_in'
rescue NameError
  require File.expand_path('get_it_in', __FILE__)
end

# this locates the factory definition file /spec/factories.rb
FactoryGirl.find_definitions

# database_cleaner gem config
# =============================================================================
DatabaseCleaner.strategy = :truncation

class MiniTest::Spec
  after :each do
    DatabaseCleaner.clean
  end
end

def set_session(id)
  post '/set_session/' + id
end

# Turn gem config
# =============================================================================
Turn.config.format = :outline
# Turn.config.format = :progress



