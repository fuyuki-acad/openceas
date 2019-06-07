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

class Schedule
  attr_accessor :course


  def initialize(course)
    @courses = course
    @first_semester = SemesterSchedule.new
    @secound_semester = SemesterSchedule.new
    make_data
  end

  def first_semester
    @first_semester
  end

  def secound_semester
    @secound_semester
  end

  def make_data
    @courses.each do |course|
      next if course.term_flag != Settings.COURSE_TERMFLG_EFFECTIVE

      case course.season_cd
      when Settings.COURSE_SEASONCD_FIRSTTERM
        @first_semester.set_schedule(course)

      when Settings.COURSE_SEASONCD_LASTTERM
        @secound_semester.set_schedule(course)

      end
    end
  end
end

class SemesterSchedule
  SCHEDULE_WEEK = [Settings.COURSE_DAYCD_MON, Settings.COURSE_DAYCD_TUE, Settings.COURSE_DAYCD_WED, Settings.COURSE_DAYCD_THU, Settings.COURSE_DAYCD_FRI, Settings.COURSE_DAYCD_SAT, Settings.COURSE_DAYCD_SUN]
  SCHEDULE_HOUR = [Settings.COURSE_HOURCD_FIRST, Settings.COURSE_HOURCD_SECOND, Settings.COURSE_HOURCD_THIRD, Settings.COURSE_HOURCD_FOURTH, Settings.COURSE_HOURCD_FIFTH, Settings.COURSE_HOURCD_SIXTH, Settings.COURSE_HOURCD_SEVENTH, Settings.COURSE_HOURCD_EIGHTH]

  def initialize
    @sessions = {}
    SCHEDULE_HOUR.each do |hour|
      @sessions[hour] = {}
      SCHEDULE_WEEK.each do |week|
        @sessions[hour][week] = ""
      end
    end
  end

  def set_schedule(course)
    if SCHEDULE_HOUR.include?(course.hour_cd) && SCHEDULE_WEEK.include?(course.day_cd)
      @sessions[course.hour_cd][course.day_cd] = course.course_name
    end
  end

  def get_schedule(hour_cd, day_cd)
    if SCHEDULE_HOUR.include?(hour_cd) && SCHEDULE_WEEK.include?(day_cd)
      @sessions[hour_cd][day_cd]
    end
  end
end
