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

module Admin::AccessLogsHelper
    def log_type_list
      list = []

      if User.current_user.admin?
        list << [t("access_log.ACC_ACCESSLOG_NAVITEXT2"), "0"]
        #courses = Course.order("school_year DESC, day_cd, hour_cd, season_cd").limit(200)
        @courses.each do |course|
          list << [course.course_cd.to_s + " " + course.course_name.to_s + " " + course.instructor_name.to_s, course.id]
        end
      elsif User.current_user.teacher?
        #courses = Course.order("school_year DESC, day_cd, hour_cd, season_cd").joins(:course_assigned_users)
        #  .where("user_id = ? AND indirect_use_flag = ? AND (courses.term_flag = ? OR courseware_flag = ?)", current_user.id, false, true, true)
        #  .limit(200)
        @courses.each do |course|
          list << [course.course_cd.to_s + " " + course.course_name.to_s + " " + course.instructor_name.to_s, course.id]
        end
      end

      return list
    end

    def circle_or_cross(value)
      if value == Settings.SYSTEMLOG_RESULTFLG_SUCCESS
        t("access_log.ACC_ACCESSLOG_SEARCHRESULTTABLE5")
      else
        t("access_log.ACC_ACCESSLOG_SEARCHRESULTTABLE6")
      end
    end

    def role_list
      list = [[t("access_log.ACC_ACCESSLOG_ALL"), ""]]
      list + Role::role_list
    end
end
