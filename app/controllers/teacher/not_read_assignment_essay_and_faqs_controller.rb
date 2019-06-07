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

class Teacher::NotReadAssignmentEssayAndFaqsController < ApplicationController
  def index
    sql_params = {}
    sql_text = ""

    unless current_user.admin?
      sql_text = "course_assigned_users.user_id = :user_id AND "
      sql_params[:user_id] = current_user.id
    end

    sql_text += "courses.indirect_use_flag = :indirect_use_flag" +
      " AND (courses.term_flag = :term_flag OR courses.courseware_flag = :courseware_flag)" +
      " AND (unread_assignment_essay_count_view.unread_count > 0 OR non_answer_faq_count_view.non_answer_count > 0)"

    sql_params[:indirect_use_flag] = false
    sql_params[:term_flag] = true
    sql_params[:courseware_flag] = true

    @not_read_assignment_essay_and_faqs = Course.joins(:course_assigned_users).
      joins("LEFT JOIN unread_assignment_essay_count_view ON unread_assignment_essay_count_view.course_id = courses.id").
      joins("LEFT JOIN non_answer_faq_count_view ON non_answer_faq_count_view.course_id = courses.id").
      where(sql_text, sql_params).
      order("school_year DESC, day_cd, hour_cd, season_cd").distinct
  end
end
