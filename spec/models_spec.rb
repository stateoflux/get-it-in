begin
  require_relative 'spec_helper'
rescue NameError
  require File.expand_path('spec_helper', __FILE__)
end

include Rack::Test::Methods

def app() Sinatra::Application end



describe User do

  # create (persisted) a User with workouts prior to all tests
  before do
    @user = FactoryGirl.create(:user_with_workouts)
  end

  it "must be built and saved to db successfully" do
    user = FactoryGirl.build(:user, user_name: "Mikki Montague")
    # user = FactoryGirl.build(:user_with_workouts)
    user.save!.must_equal true
  end

  it "must be built and saved to db with associated workouts successfully" do
    skip
    user = FactoryGirl.create(:user_with_workouts)
    user.save!.must_equal true
  end

  it "must be retrievable" do
    User.find(@user._id).must_be_instance_of User
  end

  it "must be updatable" do
    @user.update_attributes!(user_name: "The Man With The Golden Arms").must_equal true
  end

end

describe Workout do
  it "should be build and saved to db successfully" do
    user = FactoryGirl.build(:user)
    workout = FactoryGirl.build(:workout)
    user.workouts << workout
    workout.save!.must_equal true
  end
end
