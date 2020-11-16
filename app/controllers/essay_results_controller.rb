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

class EssayResultsController < Teacher::Result::EssaysController
  before_action :require_teacher_permission, except: [:index]
  before_action :set_courses, only: [:index]

  def index
    session[:essay_search] = nil

    ## 履修または担任している科目数が存在するかどうかチェック
		if @courses.count > 0
      course_ids = @courses.map {|course| course.id}

			## 管理者の時
			if current_user.admin?
        @essays = Essay.eager_load(:answer_scores).where("generic_pages.type_cd = ? AND generic_pages.course_id IN (?)",
          Settings.GENERICPAGE_TYPECD_ASSIGNMENTESSAYCODE, course_ids).page(params[:page])

				## 担任者の時
			elsif current_user.teacher?
				## 担任科目でレポート課題がある科目情報を一括取得
        @essays = Essay.eager_load(:answer_scores).joins(:course => :course_assigned_users).
          where("generic_pages.type_cd = ? AND generic_pages.course_id IN (?) AND course_assigned_users.user_id = ?",
            Settings.GENERICPAGE_TYPECD_ASSIGNMENTESSAYCODE, course_ids, current_user.id).page(params[:page])

				## 学生の時
			elsif current_user.student?
				## 履修している科目にレポート課題が出題されていた場合、そのレポートの情報を取得する
        @essays = Essay.joins(:class_sessions, :course => [:course_enrollment_users, :class_sessions]).
          where("generic_pages.type_cd = ? AND generic_pages.course_id IN (?) AND course_enrollment_users.user_id = ?",
            Settings.GENERICPAGE_TYPECD_ASSIGNMENTESSAYCODE, course_ids, current_user.id).distinct.page(params[:page])
			end
    end
  end

  private
    def set_courses
      if current_user.admin?
        @courses = Course.order(VIEW_COUSE_ORER)
      elsif current_user.teacher?
        @courses = Course.order(VIEW_COUSE_ORER).joins(:course_assigned_users).where("user_id = ? AND indirect_use_flag = ? AND (courses.term_flag = ? OR courseware_flag = ?)", current_user.id, false, true, true)
      else
        @courses = Course.order(VIEW_COUSE_ORER).joins(:course_enrollment_users).where("user_id = ? AND indirect_use_flag = ? AND courses.term_flag = ? AND courseware_flag = ?", current_user.id, false, true, false)
      end
    end
end
