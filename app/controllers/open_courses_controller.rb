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

class OpenCoursesController < ApplicationController
  def index
    get_data
  end

  def assign
    ActiveRecord::Base.transaction do
      if params[:assign]
        params[:assign].each do |key, value|
          course = Course.where(:id => key).first
          if course
            unless course.open_course_pass.blank?
              raise I18n.t("open_course_list.OPE_OPENCOURSELIST_ERROR1") if course.open_course_pass != params[:password][key]
            end

            assign_user = OpenCourseAssignedUser.new(:user_id => current_user.id)
            course.open_course_assigned_users << assign_user
          end
        end
      end

      if params[:release]
        params[:release].each do |key, value|
          assigned_user = OpenCourseAssignedUser.where("course_id = ? AND user_id = ?", key, current_user.id).first
          if assigned_user
            assigned_user.destroy
          end
        end
      end
    end

  rescue => e
    logger.error e.backtrace.join("\n")
    flash[:notice] = e.message

  ensure
    get_data
    render :index
  end

  private
    def get_data
      ## 割付していない公開科目を取得する
      user_assigned_courses = current_user.open_course_assigned_users.select("course_id")
      @courses = Course.
        where("open_course_flag = ? AND id NOT IN (?) AND course_name LIKE ?",
          Settings.COURSE_OPENCOURSEFLG_PUBLIC, user_assigned_courses, "%#{params[:key_word]}%").page(params[:page])
      @assigned_courses = Course.joins(:open_course_assigned_users).
        where("courses.open_course_flag = ? AND open_course_assigned_users.user_id = ?", Settings.COURSE_OPENCOURSEFLG_PUBLIC, current_user.id)
    end
end
