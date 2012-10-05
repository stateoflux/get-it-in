FactoryGirl.define do

  factory :user do
    email  "wayne.montague@zmail.com"
    hashed_password {}
    # salt {}
    # token {}
    factory :user_with_workouts do
      # workout_count is declared as an ignored attribute and available in
      # attributes on the factory, as well as the callback via the evaluator
      ignore do
        workout_count 1
      end

      # the after(:create) yields two values; the user instance itself and the
      # evaluator, which stores all values from the factory, including ignored
      # attributes; `create_list`'s second argument is the number of records
      # to create and we make sure the user is associated properly to the post
      after(:build) do |user, evaluator|
        FactoryGirl.build_list(:workout, evaluator.workout_count, user: user)
      end
    end
  end

  factory :workout do
    # created_at {Time.now}
    # updated_at {Time.now}
    workout_date { Date.today }
    exercises { [build(:strength_exercise)] }
  end

  factory :strength_exercise do
    exercise_name "Push Ups"
    duration      30   # would like to randomize this
    sets        3
    reps        10
  end

  factory :cardio_exercise do
    exercise_name "Running"
    duration      30   # would like to randomize this
    distance    3
    calories    400
  end
end





