FactoryGirl.define do
  sequence :email do |n|
    "foo.bar.#{n}@baz.org"
  end

  factory :account do
    email
    password  { "SuperSafe123" }
  end
end
