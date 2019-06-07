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

class Role < ApplicationRecord
  has_many :users

  ADMIN = 'admin'
  TEACHER = 'teacher'
  STUDENT = 'student'

  validates :description, :presence => true

  class << self
    def role_list
      [[I18n.t("common.COMMON_ADMINISTRATOR"), Settings.USR_AUTHCD_ADMINISTRATOR],
       [I18n.t("common.COMMON_INSTRUCTOR"), Settings.USR_AUTHCD_INSTRUCTOR],
       [I18n.t("common.COMMON_STUDENT"), Settings.USR_AUTHCD_STUDENT]]
    end

    def role_name(id)
      role_list.each do |key, value|
        return key if value == id
      end

      ""
    end
  end
end
