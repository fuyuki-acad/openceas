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

module Teacher::AttendancesHelper
  def attendance_options()
    options = []
    options << [" ", 0]
    options << [t("attendanceAdministration.COMMONATTENDANCEADMINISTRATION_ATTENDANCE"), 1]
    options << [t("attendanceAdministration.COMMONATTENDANCEADMINISTRATION_LATE"), 2]
    options << [t("attendanceAdministration.COMMONATTENDANCEADMINISTRATION_ABSENT"), 3]

    return options
  end

  def attendance_long_options()
    options = []
    options << [" ", 0]
    options << [t("attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_ATTENDANCE"), 1]
    options << [t("attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_LATE"), 2]
    options << [t("attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_ABSENT"), 3]

    return options
  end

  def class_session_name(class_session_count)
    if @course.class_session(class_session_count).nil? || @course.class_session(class_session_count).class_session_day == I18n.t("common.COMMON_COUNTFORM", :param0 => class_session_count)
      return class_session_count.to_s + I18n.t("common.COMMON_COUNT1")
    else
      return @course.class_session(class_session_count).class_session_day
    end
  end
end
