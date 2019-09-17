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

class GenericPage < ApplicationRecord
  include UploadFileModule, CustomValidationModule

  belongs_to  :course
  has_many  :answer_scores,  :foreign_key => :page_id
  has_many  :generic_page_class_session_associations,  dependent: :delete_all
  has_many  :answer_score_histories,  :foreign_key => :page_id

  has_and_belongs_to_many :questions, :class_name => "Question",
    :join_table => :generic_page_question_associations, :foreign_key => :generic_page_id, :association_foreign_key => :question_id
  has_and_belongs_to_many :parent_questions, -> { where "pattern_cd = ?", Settings.QUESTION_PATTERNCD_PARENTQUESTION}, :class_name => "Question",
    :join_table => :generic_page_question_associations, :foreign_key => :generic_page_id, :association_foreign_key => :question_id
  has_and_belongs_to_many :class_sessions, :class_name => "ClassSession",
    :join_table => :generic_page_class_session_associations, :foreign_key => :generic_page_id, :association_foreign_key => :class_session_id
  has_and_belongs_to_many :class_sessions, :join_table => :generic_page_class_session_associations

  attr_accessor :upload_flag, :current_file, :html_text, :self_type, :edit_essay_flag, :answer_file

  TYPE_NOFILEUPLOAD = '0'
  TYPE_FILEUPLOAD = '1'
  TYPE_CREATEHTML = '2'

  DEFAULT_PASS_GRADE = 60

  XML_CONVERT_CEAS10 = {:tag_attributes => {:course_id => :courseId, :id => :pageId}, :type_cd => :typeCd,
    :generic_page_title => :pageTitle, :start_pass => :startPass, :start_time => :startTime, :end_time => :endTime,
    :file_name => :fileName, :link_name => :linkName, :explanation_file_name => :explanationFileName,
    :max_count => :maxCount, :pass_grade => :passGrade, :self_flag => :selfFlg, :self_pass => :selfPass,
    :edit_flag => :editFlg, :anonymous_flag => :anonymousFlg, :timelag_flag => :timelagFlg,
    :url_content => :urlContent, :pre_grading_enable_flag => :preGradingEnableFlg,
    :assignment_essay_return_method_cd => :assignmentEssayReturnMethodCd, :score_open_flag => :scoreOpenFlg,
    :material_memo => :materialMemo, :material_memo_closed => :materialMemoClosed,
    :parent_questions => {:tag => 'parentQuestion', :xml_convertor => Question::XML_CONVERT_PARENT_CEAS10}}
  XML_CONVERT_MANIFEST_CEAS10 = {:type_cd => :typeCd, :id => :pageId, :generic_page_title => :pageTitle}

  after_initialize do
    if self.new_record?
      case self.type_cd
      when Settings.GENERICPAGE_TYPECD_MULTIPLEFIBCODE
        self.pass_grade = GenericPage::DEFAULT_PASS_GRADE if self.pass_grade.blank?
      end
    end
  end

  after_find do
    self.current_file = self.link_name unless link_name.blank?
    case self.self_flag
    when Settings.GENERICPAGE_SELFFLG_SELF
      if self.self_pass.blank?
        self.self_type = "1"
      else
        self.self_type = "2"
      end
    when Settings.GENERICPAGE_SELFFLG_MUTUAL
      self.self_type = "3"
    when Settings.GENERICPAGE_SELFFLG_MUTUAL2
      self.self_type = "3"
    else
      self.self_type = "0"
    end

  end

  before_save do
    if User.current_user
      if self.new_record?
        self.insert_user_id = User.current_user.id
      end
      self.update_user_id = User.current_user.id
    end

    case self.self_type
    when "0"
      self.self_flag = Settings.GENERICPAGE_SELFFLG_NONE
      self.self_pass = ""
    when "1"
      self.self_flag = Settings.GENERICPAGE_SELFFLG_SELF
      self.self_pass = ""
    when "2"
      self.self_flag = Settings.GENERICPAGE_SELFFLG_SELF
    end

    self.edit_flag = "0" if self.end_time.blank?
  end

  before_create do
    if self.upload_flag == GenericPage::TYPE_CREATEHTML
      create_html_file(self.html_text)
      self.link_name = self.store_filename
    else
      if self.extract_path
        move_extracted_files
      else
        unless self.file.blank?
          create_file(get_material_path)
          self.file_name = self.original_filename
          self.link_name = self.store_filename
        end
      end
    end
  end

  before_update do
    unless self.html_text.blank?
      create_html_file(self.html_text)
      self.link_name = self.store_filename
    end
    unless self.file.blank?
      create_file(get_material_path)
      self.file_name = self.original_filename
      self.link_name = self.store_filename
    end

    unless self.file.blank? && self.html_text.blank?
      unless self.current_file.blank?
        delete_file(self.current_file, get_material_path)
      end
    end
  end

  before_destroy do
    unless self.link_name.blank?
      delete_file(self.link_name, get_material_path)
    end

    self.parent_questions.each { |parent| parent.destroy}
  end

  validate :check_data

  def check_data
    case type_cd.to_s
    when Settings.GENERICPAGE_TYPECD_EVALUATIONLISTCODE.to_s
      validate_presence(:generic_page_title, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE6"))
      validate_max_length(:material_memo, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_COMMENT_TOO_LONG"), 4096)
    when Settings.GENERICPAGE_TYPECD_MATERIALCODE.to_s
      validate_presence(:generic_page_title, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE1"))

      case upload_flag
      when GenericPage::TYPE_FILEUPLOAD
        if file.blank?
          errors.add(:file, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE2")) if new_record?
        else
          extname = File.extname(file.original_filename)
          errors.add(:file_name, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE3")) if extname.blank?
          errors.add(:file_name, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE4")) if extname.downcase == ".exe"

          if extract_flag === "true"
            if EXTRACT_TYPES.include?(extname.downcase)
              errors.add(:file_name, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE11")) unless check_compressed_file(file)
            else
              errors.add(:file_name, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE5"))
            end
          end
        end

      when GenericPage::TYPE_CREATEHTML
        validate_presence(:file_name, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE2"))
        validate_file_name(:file_name, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE16"))
      end

      validate_max_length(:material_memo, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_COMMENT_TOO_LONG"), 4096)
      validate_max_length(:material_memo_closed, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_COMMENT_TOO_LONG2"), 4096)

    when Settings.GENERICPAGE_TYPECD_URLCODE.to_s
      validate_presence(:generic_page_title, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE6"))
      validate_presence(:url_content, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE7"))
      result = self.url_content.match(/\A#{URI::regexp(%w(http https))}\z/)
      unless result && result[4]
        self.errors.add(:url_content, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE7"))
      end
      validate_max_length(:material_memo, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_COMMENT_TOO_LONG"), 4096)
      validate_max_length(:material_memo_closed, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_COMMENT_TOO_LONG2"), 4096)

    when Settings.GENERICPAGE_TYPECD_COMPOUNDCODE.to_s
      validate_presence(:generic_page_title, I18n.t("common.COMMON_SUBJECTCHECK"))
      if self.upload_flag == GenericPage::TYPE_FILEUPLOAD && self.file.blank?
        errors.add(:file, I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE6"))
      end
      validate_alphanumeric(:start_pass, I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE3"))
      validate_alphanumeric(:self_pass, I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE3"))
      validate_max_length(:material_memo, I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_COMMENT_TOO_LONG"), 4096)
      validate_presence(:self_pass, I18n.t("materials_registration.MAT_REG_COM_REGISTERCOMPOUND_STARTGRADEPASSWORD_ALERT")) if self.self_type == "2" || self.self_type == "3"
      unless start_time.blank? || end_time.blank?
        errors.add(:start_time, I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE2")) if self.start_time > self.end_time
      end

    when Settings.GENERICPAGE_TYPECD_MULTIPLEFIBCODE.to_s
      validate_presence(:generic_page_title, I18n.t("common.COMMON_SUBJECTCHECK"))
      validate_alphanumeric(:start_pass, I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE3"))
      validate_max_length(:material_memo, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_COMMENT_TOO_LONG"), 4096)
      if self.upload_flag == GenericPage::TYPE_FILEUPLOAD && self.file.blank?
        errors.add(:file, I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE6"))
      end

    when Settings.GENERICPAGE_TYPECD_ASSIGNMENTESSAYCODE.to_s
      validate_presence(:generic_page_title, I18n.t("common.COMMON_SUBJECTCHECK"))
      case upload_flag
      when GenericPage::TYPE_FILEUPLOAD
        if file.blank?
          errors.add(:file, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE2")) if new_record?
        else
          extname = File.extname(file.original_filename)
          errors.add(:file, I18n.t("materials_registration.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE3")) if extname.blank?
          errors.add(:file, I18n.t("materials_registration.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE4")) if extname.downcase == ".exe"
        end
      end
      validate_alphanumeric(:start_pass, I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE3"))
      validate_max_length(:material_memo, I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_COMMENT_TOO_LONG"), 4096)
      validate_presence(:start_time, I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE2"))
      validate_presence(:end_time, I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE2"))
      unless start_time.blank? || end_time.blank?
        errors.add(:start_time, I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE2")) if self.start_time > self.end_time
      end

    when Settings.GENERICPAGE_TYPECD_QUESTIONNAIRECODE.to_s
      validate_presence(:generic_page_title, I18n.t("common.COMMON_SUBJECTCHECK"))
      case upload_flag
      when GenericPage::TYPE_FILEUPLOAD
        if file.blank?
          errors.add(:file, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE2")) if new_record?
        else
          extname = File.extname(file.original_filename)
          errors.add(:file, I18n.t("materials_registration.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE3")) if extname.blank?
          errors.add(:file, I18n.t("materials_registration.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE4")) if extname.downcase == ".exe"
        end
      end
      validate_alphanumeric(:start_pass, I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE3"))
      validate_max_length(:material_memo, I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_COMMENT_TOO_LONG"), 4096)
      unless start_time.blank? || end_time.blank?
        errors.add(:start_time, I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE2")) if self.start_time > self.end_time
      end

    end

  end

  def copy(course)
    new_object = self.dup
    new_object.course_id = course.id
    file_name = copy_file(new_object)
    if file_name.blank?
      new_object.file_name = nil
      new_object.link_name = nil
    else
      new_object.link_name = file_name
    end
    new_object
  end

  def copy_file(new_object)
    unless self.link_name.blank?
      src_path = File.dirname(self.link_name)
      if src_path == "."
        src_file = self.get_material_path + self.link_name
        dest_file = new_object.get_material_path + new_object.get_link_name(self.link_name)
        if File.exist?(src_file)
          FileUtils.cp src_file, dest_file
          File.basename(dest_file)
        else
          raise I18n.t("common.COMMON_ERROR_NOTEXISTFILE") + "(" + I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ATTACHMENT") + ")"
        end
      else
        src_path = self.get_material_path + src_path
        dest_path_name = Time.zone.now.to_f.to_s.sub(".","")
        dest_path = new_object.get_material_path + dest_path_name
        if File.exist?(src_path)
          FileUtils.cp_r(src_path, dest_path)
          dest_path_name + "/" + File.basename(self.link_name)
        else
          raise I18n.t("common.COMMON_ERROR_NOTEXISTFILE") + "(" + I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ATTACHMENT") + ")"
        end
      end
    end
  end

  def copy_questions(src)
    src.questions.each do |parent|
      new_parent = parent.dup
      new_parent.save!(validate: false)

      parent.questions.each do |question|
        new_question = question.dup
        new_question.parent_question_id = new_parent.id
        new_question.save!(validate: false)

        question.select_quizzes.each do |quiz|
          new_quiz = quiz.dup
          new_quiz.question_id = new_question.id
          new_quiz.save!(validate: false)
        end
      end

      self.parent_questions << new_parent
    end
  end

  def get_title
    self.generic_page_title
  end

  def get_link_url
    if type_cd == Settings.GENERICPAGE_TYPECD_URLCODE
      self.url_content
    else
      self.get_material_url_path + self.link_name.to_s
    end
  end

  def get_material_file_path
    if type_cd != Settings.GENERICPAGE_TYPECD_URLCODE
      self.get_material_path + self.link_name.to_s
    end
  end

  def get_explanation_file_path
    return "" if self.explanation_link_name.blank?
    self.get_material_path + self.explanation_link_name.to_s
  end

  def destroy_file
    delete_file(self.link_name, get_material_path)
    self.file_name = ""
    self.link_name = ""
    self.save
  end

  def get_total_score
    Question.joins(:parent => :generic_pages).where('generic_pages.id = ?', self.id).sum(:score)
  end

  def get_html_file
    ERB::Util.html_escape(load_file(self.link_name, get_material_path))
  end

  def assigned?
    @sessions = self.generic_page_class_session_associations if @sessions.nil?
    @sessions.each do |session|
      return true if session.class_session.class_session_no != 0 && !self.material? && !self.url?
    end
    false
  end

  def get_assigned_session(class_session_id)
    return false if class_session_id.nil?
    @sessions = self.generic_page_class_session_associations if @sessions.nil?
    @sessions.each do |session|
      return session if session.class_session_id.to_s == class_session_id.to_s
    end
    false
  end

  def get_assigned_message
    @sessions = self.generic_page_class_session_associations if @sessions.nil?
    @sessions.each do |session|
      next if session.class_session.class_session_no == 0
      return I18n.t("select_class_session.MAT_ALL_SELECTCLASSSESSION_MATERIALTEXT15", :param0 => session.class_session.class_session_day)
    end
  end

  def material?
    self.type_cd == Settings.GENERICPAGE_TYPECD_MATERIALCODE
  end

  def url?
    self.type_cd == Settings.GENERICPAGE_TYPECD_URLCODE
  end

  def compond?
    self.type_cd == Settings.GENERICPAGE_TYPECD_COMPOUNDCODE
  end

  def multiplefib?
    self.type_cd == Settings.GENERICPAGE_TYPECD_MULTIPLEFIBCODE
  end

  def essay?
    self.type_cd == Settings.GENERICPAGE_TYPECD_ASSIGNMENTESSAYCODE
  end

  def questionnaire?
    self.type_cd == Settings.GENERICPAGE_TYPECD_QUESTIONNAIRECODE
  end

  def evaluation?
    self.type_cd == Settings.GENERICPAGE_TYPECD_EVALUATIONLISTCODE
  end

  def valid_term?
		# 受付開始時間を設定している時
		if self.start_time
			return false if self.start_time > Time.zone.now
		end

		# 受付終了時間を設定している時
		if self.end_time
			return false if self.end_time < Time.zone.now
    end

    return true
  end

  def not_ready?
    if self.start_time
			return true if self.start_time > Time.zone.now
		end
    return false
  end

  def expired?
    if self.end_time
			return true if self.end_time < Time.zone.now
    end
    return false
  end

  def answer_saved?(user)
    answer_scores.where("user_id = ? AND total_score = ?", user.id, Settings.ANSWERSCORE_TMP_SAVED_SCORE).count > 0
  end

  def answer_completed?(user)
    answer_scores.where("user_id = ? AND total_score > ?", user.id, Settings.ANSWERSCORE_TMP_SAVED_SCORE).count > 0
  end

  def can_edit?(user)
    completed = answer_completed?(user)
    if completed
      if self.end_time && self.end_time >= Time.zone.now && self.edit_flag == Settings.GENERICPAGE_EDITFLG_ON
        true
      else
        false
      end
    else
      true
    end
  end

  def answerd_user_count(course_id)
    self.answer_scores.joins(:user => :course_enrollment_users).where("answer_scores.total_score > ? AND course_id = ?", Settings.ANSWERSCORE_TMP_SAVED_SCORE, course_id).distinct.count(:user_id)
  end

  def latest_score(user_id)
    self.answer_scores.where(page_id: self.id, user_id: user_id).first
  end

  def answered?(user_id)
    latest_score = self.latest_score(user_id)
    if latest_score && latest_score.total_score > -1
      true
    else
      false
    end
  end

  def passed?(user_id)
    scores = self.answer_scores.where("user_id = ?", user_id)
    scores.each do |score|
      return true if score.pass_cd == Settings.ANSWERSCORE_PASSCD_SUBMITTED
    end

    return false
  end

  def get_class_session_day
    class_sessions = self.course.class_sessions.order("class_session_no")
    if class_sessions.count > 0
      class_sessions.first.class_session_day
    end
  end

  def get_total_point
    total_point = 0

		self.parent_questions.each do |parent|
      parent.questions.each do |question|
        total_point += question.score
      end
    end

		total_point
  end

  def html?
    HTML_TYPES.include?(File.extname(self.link_name.downcase))
  end
end
