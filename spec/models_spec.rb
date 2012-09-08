begin
  require_relative 'spec_helper'
rescue NameError
  require File.expand_path('spec_helper', __FILE__)
end

include Rack::Test::Methods

def app() Sinatra::Application end

describe User do
  it "should be built and saved to db successfully" do
    user = FactoryGirl.build(:user)
    # user = FactoryGirl.build(:user_with_workouts)
    user.save.must_equal true
  end
end

describe Workout do
  it "should be build and saved to db successfully" do
    user = FactoryGirl.build(:user)
    workout = FactoryGirl.build(:workout)
    user.workouts << workout
    workout.save.must_equal true
  end
end
