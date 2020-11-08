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

class ApplicationController < ActionController::Base

  class Forbidden < ActionController::ActionControllerError; end

  VIEW_COUSE_ORER = "school_year DESC, season_cd, day_cd, hour_cd"

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!

  before_action :set_current_user
  before_action :set_locale
  before_action :check_permission

  rescue_from Exception, with: :render_500
  rescue_from Forbidden, with: :render_403
  rescue_from ActiveRecord::RecordNotFound, with: :render_404
  rescue_from ActionController::RoutingError, with: :render_404

  def render_403
    render template: 'errors/error500', status: :forbidden
  end

  def render_404
    render template: 'errors/error404', status: :not_found
  end
  
  def render_500
    render template: 'errors/error500', status: :internal_server_error
  end

  def send_file_headers!(options)
    super(options)
    match = /(.+); filename="(.+)"/.match(headers['Content-Disposition'])
    encoded = URI.encode_www_form_component(match[2])
    headers['Content-Disposition'] = "#{match[1]}; filename*=UTF-8''#{encoded}" unless encoded == match[2]
  end

  def other_courses
    set_course
    set_other_courses
    render :partial => "shared/courses/course_list"
  end

  protected
    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up) do |user|
        user.permit(:account, :password, :password_confirmation, :remember_me)
      end

      devise_parameter_sanitizer.permit(:sign_in) do |user|
        user.permit(:account, :password, :remember_me)
      end

      devise_parameter_sanitizer.permit(:sign_in) do |user|
        user.permit(:account, :password, :password_confirmation, :email, :user_name, :kana_name, :display_name)
      end
    end

    def set_current_user
      User.current_user = current_user
      cookies['support_user_id'] = current_user.id if current_user
    end

    def set_courses
      if current_user.admin?
        if params[:course_name].blank?
          @courses = Course.order(VIEW_COUSE_ORER).page(params[:page])
        else
          @courses = Course.where("course_name LIKE ?", "%#{params[:course_name]}%").order(VIEW_COUSE_ORER).page(params[:page])
        end
      elsif current_user.teacher?
        if params[:course_name].blank?
          @courses = Course.order(VIEW_COUSE_ORER).joins(:course_assigned_users).where("user_id = ? AND indirect_use_flag = ? AND (courses.term_flag = ? OR courseware_flag = ?)", current_user.id, false, true, true).page(params[:page])
        else
          @courses = Course.order(VIEW_COUSE_ORER).joins(:course_assigned_users).where("user_id = ? AND indirect_use_flag = ? AND (courses.term_flag = ? OR courseware_flag = ?) AND course_name LIKE ?", current_user.id, false, true, true, "%#{params[:course_name]}%").page(params[:page])
        end
      else
        if params[:course_name].blank?
          @courses = Course.order(VIEW_COUSE_ORER).joins(:course_enrollment_users).where("user_id = ? AND indirect_use_flag = ? AND courses.term_flag = ? AND courseware_flag = ?", current_user.id, false, true, false).page(params[:page])
        else
          @courses = Course.order(VIEW_COUSE_ORER).joins(:course_enrollment_users).where("user_id = ? AND indirect_use_flag = ? AND courses.term_flag = ? AND courseware_flag = ? AND course_name LIKE ?", current_user.id, false, true, false, "%#{params[:course_name]}%").page(params[:page])
        end
      end
    end

    def set_other_courses
      if current_user.admin?
        if params[:course_name].blank?
          @courses = Course.where("courses.id != ?", params[:course_id]).
            order(VIEW_COUSE_ORER).page(params[:page])
        else
          @courses = Course.where("courses.id != ? AND course_name LIKE ?", params[:course_id], "%#{params[:course_name]}%").
            order(VIEW_COUSE_ORER).page(params[:page])
        end
      elsif current_user.teacher?
        @courses = Course.order(VIEW_COUSE_ORER).joins(:course_assigned_users).
          where("user_id = ? AND indirect_use_flag = ? AND (courses.term_flag = ? OR courseware_flag = ?) AND courses.id != ? AND course_name LIKE ?",
            current_user.id, false, true, true, params[:course_id], "%#{params[:course_name]}%")
          .page(params[:page])
      end
    end

    def set_course
      @course = Course.find(params[:course_id])
    end

    def set_locale
      I18n.locale = current_user.locale || I18n.default_locale unless current_user.blank?
    end

    def check_permission
      if self.controller_path.match(/^admin\//)
        redirect_to root_path unless current_user.admin?
      elsif self.controller_path.match(/^teacher\//)
        redirect_to root_path unless current_user.admin? || current_user.teacher?
      end
    end

    def require_admin_permission
      redirect_to root_path unless current_user.admin?
    end

    def require_teacher_permission
      redirect_to root_path unless current_user.admin? || current_user.teacher?
    end

    def get_require_course
      if params[:course_id].present?
        course = Course.where("id = ?", params[:course_id]).first
      elsif params[:generic_page_id].present?
        course = Course.joins(:generic_pages).where("generic_pages.id = ?", params[:generic_page_id]).first
      elsif params[:id].present?
        if controller_name == "group_folders"
          course = Course.joins(:group_folders).where("group_folders.id = ?", params[:id]).first
        elsif controller_name == "courses"
          course = Course.where("id = ?", params[:id]).first
        elsif controller_name == "announcements"
          course = Course.joins(:announcements).where("announcements.id = ?", params[:id]).first
        elsif controller_name == "faqs"
          course = Course.joins(:faqs).where("faqs.id = ?", params[:id]).first
        elsif controller_name == "questionnaires" && action_name == "detail"
          question = Question.find(params[:id])
          if question.present?
            generic_page = question.parent.generic_pages.first
            course = generic_page.course
          end
        else
          course = Course.joins(:generic_pages).where("generic_pages.id = ?", params[:id]).first
        end
      end

      if course.blank?
        raise ActiveRecord::RecordNotFound
      else
        course
      end
    end

    def require_assigned
      return if current_user.admin?

      course = get_require_course
      must_be_assigned(course)
    end

    def must_be_assigned(course)
      if current_user.teacher?
        assigned = course.course_assigned_users.where(user_id: current_user.id).first
      end
      
      if assigned.blank?
        raise Forbidden
      end
    end

    def require_enrolled
      return if current_user.admin?

      course = get_require_course
      if current_user.teacher?
        enrolled = course.course_assigned_users.where(user_id: current_user.id).first

      else
        enrolled = course.course_enrollment_users.where(user_id: current_user.id).first

      end

      if enrolled.blank?
        raise Forbidden
      end
    end

    def require_enrolled_or_open_assigned
      return if current_user.admin?

      course = get_require_course
      if current_user.teacher?
        assigned = course.course_assigned_users.where(user_id: current_user.id).first
      else
        assigned = course.course_enrollment_users.where(user_id: current_user.id).first
      end

      if assigned.blank? && course.open_course_flag == Settings.COURSE_OPENCOURSEFLG_PUBLIC
        assigned = course.open_course_assigned_users.where(user_id: current_user.id).first
      end

      if assigned.blank?
        raise Forbidden
      end
    end

    def get_content_type(file_name)
      extname = File.extname(file_name)
      case extname.downcase
      when ".pdf"
        ["application/pdf", true, false]
      when ".xlsx", ".xls"
        ["vnd.ms-excel", false, false]
      when ".docx", ".doc"
        ["vnd.msword", false, false]
      when ".pptx", ".ppt"
        ["vnd.ms-powerpoint", false, false]
      when ".html", ".htm"
        ["text/html", true, true]
      when ".txt"
        ["text/plain", true, true]
      when ".jpg"
        ["image/jpeg", true, false]
      when ".png"
        ["image/png", true, false]
      when ".mp4", "mpg"
        ["video/mp4", true, false]
      when ".zip"
        ["application/zip", false, false]
      else
        ["application/octet-stream", false, false]
      end
    end

    def remote_ip
      request.env["HTTP_X_FORWARDED_FOR"] || request.remote_ip
    end

    def create_access_log(course_id)
      query_string = request.query_string.sub(/class_session_no=\d+\&?/, "")

      CourseAccessLog.create(
        course_id: course_id,
        user_id: current_user.id,
        ip: remote_ip,
        class_session_no: params[:class_session_no],
        access_page: request.path,
        query_string: query_string)
      end
    end
