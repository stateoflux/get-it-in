begin
  require_relative 'spec_helper'
rescue NameError
  require File.expand_path('spec_helper', __FILE__)
end


# include Rack::Test::Methods

def app() Sinatra::Application end


describe "User" do
  before do
    @user = FactoryGirl.build(:user)
    @user.encrypt_password("test123")
  end

  it "is valid with valid attributes" do
    @user.must_be :valid?
  end

  it "is not valid without a first name" do
    @user.first_name = nil
    @user.wont_be :valid?
    @user.errors['first_name'].wont_be :empty?
  end

  it "is not valid without an email" do
    @user.email = nil
    @user.wont_be :valid?
    @user.errors['email'].wont_be :empty?
  end

  it "is not valid without a password" do
    @user.password = nil
    @user.wont_be :valid?
    @user.errors['password'].wont_be :empty?
  end

  it "is not valid if first_name is less than 1 character" do
    @user.first_name = ""
    @user.wont_be :valid?
    @user.errors['first_name'].wont_be :empty?
  end

  it "is not valid if email is malformed" do
    @user.email = "wayne @ gmail"
    @user.wont_be :valid?
    @user.errors['email'].wont_be :empty?
  end

  it "is not valid if email is not unique" do
    @user.save
    @user2 = FactoryGirl.build(:user)
    @user2.wont_be :valid?
    @user2.errors['email'].wont_be :empty?
  end

  it "is not valid if password is less than 4 chars" do
    @user.password = "abc"
    @user.password_confirmation = "abc"
    @user.wont_be :valid?
    @user.errors['password'].wont_be :empty?
  end

  it "is not valid if passwords do not match" do
    @user.password_confirmation = "test1234"
    @user.wont_be :valid?
    @user.errors['password'].wont_be :empty?
  end

  # TODO: add specs for encrypt_password & authenticate
end

describe "Exercise" do
  before do
    @exercise = FactoryGirl.build(:exercise)
  end

  it "is valid with valid attributes" do
    @exercise.must_be :valid?
  end

  it "is not valid without a name" do
    @exercise.name = nil
    @exercise.wont_be :valid?
    @exercise.errors['name'].wont_be :empty?
  end

  it "is not valid without a w_timestamp" do
    @exercise.w_timestamp = nil
    @exercise.wont_be :valid?
    @exercise.errors['w_timestamp'].wont_be :empty?
  end

  it "is not valid without a duration" do
    @exercise.duration = nil
    @exercise.wont_be :valid?
    @exercise.errors['duration'].wont_be :empty?
  end

  it "is not valid if name is not greater than 1 char" do
    @exercise.name = "r"
    @exercise.wont_be :valid?
    @exercise.errors['name'].wont_be :empty?
  end

  it "is not valid if w_timestamp is not in correct format" do
    # test to see if an exception is raised when
    # timestamp is invalid
    proc do
      @exercise.w_timestamp = "08-13-12"
      @exercise.set_timestamp
    end.must_raise ArgumentError
  end

  it "is not valid if duration is a negative integer" do
    @exercise.duration = -20
    @exercise.wont_be :valid?
    @exercise.errors['duration'].wont_be :empty?
  end

  it "is not valid if sets is a negative integer" do
    @exercise.sets = -20
    @exercise.wont_be :valid?
    @exercise.errors['sets'].wont_be :empty?
  end

  it "is not valid if reps is a negative integer" do
    @exercise.reps = -20
    @exercise.wont_be :valid?
    @exercise.errors['reps'].wont_be :empty?
  end

  it "is not valid if calories is a negative integer" do
    @exercise.calories = -200
    @exercise.wont_be :valid?
    @exercise.errors['calories'].wont_be :empty?
  end

  it "is not valid if distance is a negative float" do
    @exercise.distance = -20.0
    @exercise.wont_be :valid?
    @exercise.errors['distance'].wont_be :empty?
  end
end

