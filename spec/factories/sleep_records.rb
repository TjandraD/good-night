FactoryBot.define do
  factory :sleep_record do
    association :user
    bed_time { Time.current }
    wakeup_time { nil }

    trait :with_wakeup do
      wakeup_time { bed_time + 8.hours }
    end

    trait :completed do
      wakeup_time { bed_time + rand(6..10).hours }
    end
  end
end
