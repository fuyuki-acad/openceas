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

class GeneralAnnouncement < ApplicationRecord
  include CustomValidationModule

  GENERALINFO_LIMIT_LOGIN = 5

  TYPE_LOGIN = 1
  TYPE_SYSTEM = 2
  TYPE_HIDDEN = 3

  validate :check_data

  def check_data
    validate_presence(:title, I18n.t("common.COMMON_SUBJECTCHECK"))
    validate_presence(:content, I18n.t("common.COMMON_CONTENTCHECK"))
    validate_max_length(:content, I18n.t("announcement.COMMONANNOUNCEMENT_SCRIPT1"), 4096)
  end

  def self.get_top_announcements
    GeneralAnnouncement.where(:type_cd => Settings.GENERALINFO_TYPECD_ALLUSR).limit(GeneralAnnouncement::GENERALINFO_LIMIT_LOGIN).order("created_at desc")
  end

  def new?
    if self.created_at + 3.days > Time.zone.now
      return true
    else
      return false
    end
  end
end
