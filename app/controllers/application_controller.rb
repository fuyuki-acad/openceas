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
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!

  before_action :set_current_user
  before_action :set_locale
  before_action :check_permission

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
          @courses = Course.order("school_year DESC, day_cd, hour_cd, season_cd").page(params[:page])
        else
          @courses = Course.where("course_name LIKE ?", "%#{params[:course_name]}%").order("school_year DESC, day_cd, hour_cd, season_cd").page(params[:page])
        end
#          @courses = Course.all.order("school_year DESC, day_cd, hour_cd, season_cd").page(params[:page])
      elsif current_user.teacher?
        if params[:course_name].blank?
          @courses = Course.order("school_year DESC, day_cd, hour_cd, season_cd").joins(:course_assigned_users).where("user_id = ? AND indirect_use_flag = ? AND (courses.term_flag = ? OR courseware_flag = ?)", current_user.id, false, true, true).page(params[:page])
        else
          @courses = Course.order("school_year DESC, day_cd, hour_cd, season_cd").joins(:course_assigned_users).where("user_id = ? AND indirect_use_flag = ? AND (courses.term_flag = ? OR courseware_flag = ?) AND course_name LIKE ?", current_user.id, false, true, true, "%#{params[:course_name]}%").page(params[:page])
        end
      else
#        @courses = Course.order("school_year DESC, day_cd, hour_cd, season_cd").joins(:course_enrollment_users).where("user_id = ? AND indirect_use_flag = ? AND courses.term_flag = ? AND courseware_flag = ? AND course_name LIKE ?", current_user.id, false, true, true, "%#{params[:course_name]}%").page(params[:page])
        if params[:course_name].blank?
          @courses = Course.order("school_year DESC, day_cd, hour_cd, season_cd").joins(:course_enrollment_users).where("user_id = ? AND indirect_use_flag = ? AND courses.term_flag = ? AND courseware_flag = ?", current_user.id, false, true, false).page(params[:page])
        else
          @courses = Course.order("school_year DESC, day_cd, hour_cd, season_cd").joins(:course_enrollment_users).where("user_id = ? AND indirect_use_flag = ? AND courses.term_flag = ? AND courseware_flag = ? AND course_name LIKE ?", current_user.id, false, true, false, "%#{params[:course_name]}%").page(params[:page])
        end
      end
    end

    def set_other_courses
      if current_user.admin?
        if params[:course_name].blank?
          @courses = Course.where("courses.id != ?", params[:course_id]).
            order("school_year DESC, day_cd, hour_cd, season_cd").page(params[:page])
        else
          @courses = Course.where("courses.id != ? AND course_name LIKE ?", params[:course_id], "%#{params[:course_name]}%").
            order("school_year DESC, day_cd, hour_cd, season_cd").page(params[:page])
        end
      elsif current_user.teacher?
        @courses = Course.order("school_year DESC, day_cd, hour_cd, season_cd").joins(:course_assigned_users).
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
