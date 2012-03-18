require 'sinatra'
require 'mongoid'
require 'slim'
require 'json'
require "sinatra/reloader" if development?

# load the mondodb configuration file
Mongoid.load!("mongoid.yml")

# Include Rack utils and alias the escape_html function to h()
# actually, do I really need this?  I should catch malformed input at the client side
helpers do    
  include Rack::Utils
  alias_method :h, :escape_html
end

# Model definition
# Can I also include validations here ala rails? Yes.
# need to add validations
# TODO: How do I update the database schema??
class Workout
  include Mongoid::Document
  field :complete , type: Boolean, :required => true, :default => false
  field :created_at , type: Date
  field :updated_at , type: Date
  embeds_many :exercises
end


class Exercise
  include Mongoid::Document
  field :exercise_name, type: String
  field :duration, type: Float
  embedded_in :workout
end

class StrengthExercise < Exercise
  field :sets, type: Integer
  field :reps, type: Integer
end

class CardioExercise < Exercise
  field :distance, type: Float
  field :calories, type: Integer
end


# Routes and "controller code"  are specified in the same place (unlike rails)
get '/' do
  # does mongoid specify order this way?
  # @workouts = Workout.asc(:id)
  # slim :workout_new
   erb :workout_new
end

post '/' do
  content_type :json
  w = Workout.new
  # used to determine if workout is valid or not. if at least one exercise has valid
  # data, then the workout is valid and will be persisted.
  wo_valid = false

  # TODO: DRY this up
  1.upto(params[:st_cnt].to_i) do |i|
    # check that reps field has data. if no data, assume user has not entered a
    # valid exercise and do not create one.
    reps = params["st_reps#{i}".to_sym]
    unless reps.empty?
      wo_valid = true
      st = StrengthExercise.new
      st.exercise_name = params["st_exercise#{i}".to_sym]
      st.sets = params["st_sets#{i}".to_sym].to_i
      st.reps = reps.to_i
      w.exercises << st
    end
  end

  1.upto(params[:ca_cnt].to_i) do |i|
    # same as reps above
    cals = params["ca_calories#{i}".to_sym]
    unless cals.empty?
      wo_valid = true
      ca = CardioExercise.new
      ca.exercise_name = params["ca_exercise#{i}".to_sym]
      puts params
      ca.duration = params["ca_duration#{i}".to_sym].to_f
      ca.distance = params["ca_distance#{i}".to_sym].to_f
      ca.calories = cals
      #ca.calories = params["calories#{i}".to_sym]
      w.exercises << ca
    end
  end
  # TODO: add logic that does not create workout if no exercise is valid
  # DONE
  if (wo_valid)
    w.created_at = Time.now
    w.updated_at = Time.now
    # TODO:
    # need to verify that the save operation completed successfully
    # have server update the "flash" if an error occurs.
    # add validation to the Workout and Exercise models
    w.save
    # respond with current workout object
    # should I respond with workout object here or should i move to the "single retrieve" action
    w.to_json
  end
end

get '/logs' do
  # need to investigate the necessary of specifying the content as json via
  content_type :json

  workouts = Workout.asc(:id)
  workouts.to_json
end

