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

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Create Roles
roles = Role.where(name: "admin")
if roles.count == 0
  Role.create(name: 'admin', description: I18n.t('item.admin'))
end

roles = Role.where(name: "instructor")
if roles.count == 0
  Role.create(name: 'instructor', description: I18n.t('item.instructor'))
end

roles = Role.where(name: "student")
if roles.count == 0
  Role.create(name: 'student', description: I18n.t('item.student'))
end

locale = Locale.where(locale: "ja")
if locale.blank?
  Locale.create(locale: "ja", title: I18n.t('login.LOG_LOGIN_LOCALEJA'))
end

locale = Locale.where(locale: "en")
if locale.blank?
  Locale.create(locale: "en", title: I18n.t('login.LOG_LOGIN_LOCALEEN'))
end

locale = Locale.where(locale: "zh_CN")
if locale.blank?
  Locale.create(locale: "zh_CN", title: I18n.t('login.LOG_LOGIN_LOCALEZH'))
end

locale = Locale.where(locale: "zh_TW")
if locale.blank?
  Locale.create(locale: "zh_TW", title: I18n.t('login.LOG_LOGIN_LOCALEZHTW'))
end

# Create Roles
roles = Role.where(name: "admin")
if roles.count == 0
  Role.create(name: 'admin', description: I18n.t('item.admin'))
end

# Create Admin
admin = User.where(account: "admin")
if admin.blank?
  User.create(account: "admin", email: "admin@example.co.jp", password: "Passw0rd", user_name: "admin", kana_name: "管理者", role_id: 1, sex_cd: 1, term_flag: 1)
end
