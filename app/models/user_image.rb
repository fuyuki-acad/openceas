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

class UserImage < ApplicationRecord
  mount_uploader :mount_url, UserImageUploader

  belongs_to  :user

#  validates :mount_url, presence: {message: "AAAAAAAAAAAAAA"}
#  validates :mount_url, presence: true

  IMAGE_TYPE_ICON = 0
  IMAGE_TYPE_EXPRESSION = 1
  IMAGE_TYPE_THUMBNAIL = 2

  IMAGE_EXP_CD = 0

  after_save do
    if self.image_type == IMAGE_TYPE_EXPRESSION
      icon = UserImage.find_by(user_id: self.user_id, image_type: IMAGE_TYPE_ICON)
      unless icon
        icon = UserImage.new
        icon.user_id = self.user_id
        icon.image_type = IMAGE_TYPE_ICON
        icon.exp_cd = IMAGE_EXP_CD
      end
      icon.mount_url = self.mount_url.icon
      icon.save

      thumb = UserImage.find_by(user_id: self.user_id, image_type: IMAGE_TYPE_THUMBNAIL)
      unless thumb
        thumb = UserImage.new
        thumb.user_id = self.user_id
        thumb.image_type = IMAGE_TYPE_THUMBNAIL
        thumb.exp_cd = IMAGE_EXP_CD
      end
      thumb.mount_url = self.mount_url.thumb
      thumb.save
    end
  end

  def image_valid?
    if mount_url.blank?
      self.errors.add(:mount_url, I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE20"))
    else
      unless mount_url.file.content_type.match(/^image\/.+/)
        self.errors.add(:mount_url, I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE17"))
      end
    end

    errors.count == 0 ? true : false
  end
end
