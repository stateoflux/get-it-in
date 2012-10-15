FactoryGirl.define do

  factory :user do
    email  "wayne.montague@zmail.com"
    hashed_password {}
    factory :user_with_exercises do
      # workout_count is declared as an ignored attribute and available in
      # attributes on the factory, as well as the callback via the evaluator
      ignore do
        exercise_count 1
      end

      # the after(:create) yields two values; the user instance itself and the
      # evaluator, which stores all values from the factory, including ignored
      # attributes; `create_list`'s second argument is the number of records
      # to create and we make sure the user is associated properly to the post
      after(:build) do |user, evaluator|
        FactoryGirl.build_list(:exercise, evaluator.exercise_count, user: user)
      end
    end
  end

  factory :exercise do
    name "Push Ups"
    workout_date  { Date.today }
    start_time    { Time.now }
    calories      100
    duration      30   # would like to randomize this
    sets          5
    reps          100
  end
end






