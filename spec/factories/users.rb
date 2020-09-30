#--
# Copyright (c) 2019 Fuyuki Academy
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

FactoryBot.define do
  factory :user do
    name_no_prefix {""}
    sex_cd {1}
    term_flag {1}
    password {"hogehoge"}
    locale {"ja"}
  end

  trait :admin do
    id {1}
    account {"admin"}
    user_name {"admin"}
    email {"admin@ceas.bownet.co.jp"}
    role_id {1}
  end

  trait :teacher do
    sequence(:account) { |n| "teacher#{n}" }
    sequence(:user_name) { |n| "teacher#{n}" }
    sequence(:email) { |n| "teacher#{n}@ceas.bownet.co.jp"}
    role_id {2}
  end

  trait :student do
    sequence(:account) { |n| "student#{n}" }
    sequence(:user_name) { |n| "student#{n}" }
    sequence(:email) { |n| "student#{n}@ceas.bownet.co.jp"}
    role_id {3}
  end

  factory :test_user, class: User do
    account {"testuser"}
    user_name {"test user"}
    email {"testuser@ceas.bownet.co.jp"}
    role_id {2}
    name_no_prefix {""}
    sex_cd {2}
    term_flag {1}
    password {"hogehoge"}
    locale {"ja"}
  end

  factory :teacher_user, class: User do
    account {"teacher_user"}
    user_name {"teacher user"}
    email {"teacher@ceas.bownet.co.jp"}
    role_id {2}
    name_no_prefix {""}
    sex_cd {2}
    term_flag {1}
    password {"hogehoge"}
    locale {"ja"}
  end

  factory :student_user, class: User do
    account {"student_user"}
    user_name {"student user"}
    email {"student@ceas.bownet.co.jp"}
    role_id {3}
    name_no_prefix {""}
    sex_cd {1}
    term_flag {1}
    password {"hogehoge"}
    locale {"ja"}
  end
end
