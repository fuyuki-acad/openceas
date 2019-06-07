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

module ClassSessionsHelper
  def attendance_options_for_select(selected = 15)
    attendance_period = {}
    attendance_period.store("#{t("attendance_execution.COMMONATTENDANCEEXECUTION_PERIOD1")}#{t("attendance_execution.COMMONATTENDANCEEXECUTION_MINUTE")}", 0)
    attendance_period.store("#{t("attendance_execution.COMMONATTENDANCEEXECUTION_PERIOD2")}#{t("attendance_execution.COMMONATTENDANCEEXECUTION_MINUTE")}", 5)
    attendance_period.store("#{t("attendance_execution.COMMONATTENDANCEEXECUTION_PERIOD3")}#{t("attendance_execution.COMMONATTENDANCEEXECUTION_MINUTE")}", 10)
    attendance_period.store("#{t("attendance_execution.COMMONATTENDANCEEXECUTION_PERIOD4")}#{t("attendance_execution.COMMONATTENDANCEEXECUTION_MINUTE")}", 15)
    attendance_period.store("#{t("attendance_execution.COMMONATTENDANCEEXECUTION_PERIOD5")}#{t("attendance_execution.COMMONATTENDANCEEXECUTION_MINUTE")}", 20)
    attendance_period.store("#{t("attendance_execution.COMMONATTENDANCEEXECUTION_PERIOD6")}#{t("attendance_execution.COMMONATTENDANCEEXECUTION_MINUTE")}", 30)
    attendance_period.store("#{t("attendance_execution.COMMONATTENDANCEEXECUTION_PERIOD7")}#{t("attendance_execution.COMMONATTENDANCEEXECUTION_MINUTE")}", 60)
    attendance_period.store("#{t("attendance_execution.COMMONATTENDANCEEXECUTION_PERIOD8")}#{t("attendance_execution.COMMONATTENDANCEEXECUTION_MINUTE")}", 90)
    options_for_select(attendance_period, :selected => selected)
  end

  def attendance_list_options_for_select(attendances)
    attendance_list = {}
    attendances.each do |attendance|
      attendance_list.store("#{attendance.attendance_count}#{t("attendance_execution.PRE_BEA_ATT_EXE_COLLECTATTENDANCEBEAN_TEXT")}#{attendance.attendance_time}", attendance.attendance_count)
    end
    options_for_select(attendance_list, :selected => 1)
  end
end
