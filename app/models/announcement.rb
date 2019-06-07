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

class Announcement < ApplicationRecord
  include CustomValidationModule

  belongs_to  :course
  has_many    :announcement_mail_logs
  has_many    :send_users, :through => :announcement_mail_logs, :source => :user

  validate :check_data

  attr_accessor :announcement_state

  def check_data
    validate_presence(:subject, I18n.t("common.COMMON_SUBJECTCHECK"))
    validate_presence(:content, I18n.t("common.COMMON_CONTENTCHECK"))
    validate_max_length(:content, I18n.t("announcement.COMMONANNOUNCEMENT_SCRIPT1"), 4096)
  end

  after_find do
    if self.announcement_cd == Settings.ANNOUNCEMENT_ANNOUNCEMENTCD_MAIL
      self.announcement_state = "2"
    else
      if self.mail_flag == Settings.ANNOUNCEMENT_MAILFLG_TRANSMITTED
        announcement_state = "0"
      else
        announcement_state = "1"
      end
    end
  end

  before_save do
    case self.announcement_state
    when "0"
      self.mail_flag = Settings.ANNOUNCEMENT_MAILFLG_TRANSMITTED
      self.announcement_cd = Settings.ANNOUNCEMENT_ANNOUNCEMENTCD_INFO
    when "1"
      self.mail_flag = Settings.ANNOUNCEMENT_MAILFLG_UNTRANSMISSION
      self.announcement_cd = Settings.ANNOUNCEMENT_ANNOUNCEMENTCD_INFO
    when "2"
      self.mail_flag = Settings.ANNOUNCEMENT_MAILFLG_TRANSMITTED
      self.announcement_cd = Settings.ANNOUNCEMENT_ANNOUNCEMENTCD_MAIL
    end
  end

  def new?
    if self.updated_at + 3.days > Time.zone.now
      return true
    else
      return false
    end
  end

  def get_title
    self.subject
  end

  def announcement_info?
    self.announcement_cd == Settings.ANNOUNCEMENT_MAILFLG_TRANSMITTED
  end

  def mail_tramitted?
    self.mail_flag == Settings.ANNOUNCEMENT_MAILFLG_TRANSMITTED
  end
end
