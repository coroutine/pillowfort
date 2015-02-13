FactoryGirl.define do
  sequence :email do |n|
    "foo.bar.#{n}@baz.org"
  end

  factory :account do
    email
    password  { "SuperSafe123" }
    activation_token { "thisismytoken" }
    activation_token_expires_at { 1.hour.from_now }
    activated_at nil

    trait :activated do
      activation_token nil
      activation_token_expires_at nil
      activated_at { Time.now }
    end
  end
end
