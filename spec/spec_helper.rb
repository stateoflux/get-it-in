ENV['RACK_ENV'] = 'test'
require 'turn/autorun'
# require 'minitest/autorun'
require 'rack/test'
require 'factory_girl'
require 'database_cleaner'
require 'rr'

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


# Turn gem config
# =============================================================================
Turn.config.format = :outline
# Turn.config.format = :progress

# RR Setup
# =============================================================================
class MockSpec < MiniTest::Spec
  include RR::Adapters::RRMethods
end
MiniTest::Spec.register_spec_type(/.*/, MockSpec)


# helper methods
# ============================================================================

GOOD_ID = "1"
BAD_ID = "7"

def set_session(id)
  post '/set_session/' + id
end

def login_as(user)
  stub(user).id { "007" }
  set_session(user.id)
  stub(User).find(is_a(String)) { user }
  any_instance_of(Exercise) do |e|
     stub(e).id { GOOD_ID }
  end
  stub(user.exercises).find(user.exercises[0].id) { user.exercises[0] }
  stub(user.exercises).find(BAD_ID) { nil }
end
