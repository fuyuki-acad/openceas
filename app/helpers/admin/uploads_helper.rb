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

module Admin::UploadsHelper

  def user_file_empty?
    csv_user = CsvUser.new
    files = Dir.glob("#{csv_user.tmp_dir}*")
    files.count == 0 ? true : false
  end

  def course_file_empty?
    csv_course = CsvCourse.new
    files = Dir.glob("#{csv_course.tmp_dir}*")
    files.count == 0 ? true : false
  end

  def course_assigned_file_empty?
    csv_course_assigned = CsvCourseAssigned.new
    files = Dir.glob("#{csv_course_assigned.tmp_dir}*")
    files.count == 0 ? true : false
  end

  def course_enrollment_file_empty?
    csv_course_enrollment = CsvCourseEnrollment.new
    files = Dir.glob("#{csv_course_enrollment.tmp_dir}*")
    files.count == 0 ? true : false
  end
end
