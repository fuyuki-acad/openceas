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

require 'rails_helper'

RSpec.describe GenericPage, type: :model do
  before do
    @course = create(:course, :year_of_2019)
  end

  describe 'バリデーション' do
    before do
      @url_link = build(:url_link, course_id: @course.id)
    end

    it "正常" do
      @url_link.valid?
      expect(@url_link.errors.count).to eq 0
      expect(@url_link).to be_valid
    end

    it "タイトル" do
      @url_link.generic_page_title = nil
      @url_link.valid?
      expect(@url_link.errors.messages[:base]).to include I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE6")
    end

    it "url" do
      #不正url
      @url_link.url_content = "text.xxxx---.."
      @url_link.valid?
      expect(@url_link.errors.messages[:url_content]).to include I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE7")
    end

    it "公開メモ" do
      @url_link.material_memo = "あ" * 4097
      @url_link.valid?
      expect(@url_link.errors.messages[:base]).to include I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_COMMENT_TOO_LONG")

      @url_link.material_memo = "あ" * 4096
      @url_link.valid?
      expect(@url_link.errors.count).to eq 0
    end

    it "非公開メモ" do
      @url_link.material_memo_closed = "あ" * 4097
      @url_link.valid?
      expect(@url_link.errors.messages[:base]).to include I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_COMMENT_TOO_LONG2")

      @url_link.material_memo_closed = "あ" * 4096
      @url_link.valid?
      expect(@url_link.errors.count).to eq 0
    end
  end

  describe '登録' do
    it "成功" do
      url_link = build(:url_link, course_id: @course.id)

      expect{
        url_link.save
      }.to change(GenericPage, :count).by(1)

      expect(url_link.url_content).to eq "https://www.google.co.jp/"
    end
  end

  describe '更新' do
    it "成功" do
      url_link = create(:url_link, course_id: @course.id)

      url_link.url_content = "https://www.yahoo.co.jp"

      expect{
        url_link.save
      }.to change(GenericPage, :count).by(0)

      expect(url_link.url_content).to eq "https://www.yahoo.co.jp"
    end
  end

  describe 'コピー' do
    before do
      @url_link = create(:url_link, course_id: @course.id)

      @other_course = create(:course, :year_of_2019)
    end

    it "成功" do
      new_url_link = @url_link.copy(@other_course)

      expect(@url_link.course_id).to_not eq new_url_link.course_id

      expect(@url_link.type_cd).to eq new_url_link.type_cd
      expect(@url_link.generic_page_title).to eq new_url_link.generic_page_title
      expect(@url_link.upload_flag).to eq new_url_link.upload_flag
      expect(@url_link.url_content).to eq new_url_link.url_content
      expect(@url_link.extract_flag).to eq new_url_link.extract_flag
      expect(@url_link.material_memo_closed).to eq new_url_link.material_memo_closed
      expect(@url_link.material_memo).to eq new_url_link.material_memo
    end
  end
end