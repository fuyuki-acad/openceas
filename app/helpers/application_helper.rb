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

module ApplicationHelper
  def system_name
    t('login.LOG_LOGIN_FACULTY1')
  end

  def glyphicon(glyphicon, title)
    '<span class="glyphicon glyphicon-file" aria-hidden="true">' + t('top.COMMONTOP_ASSIGNMENTESSAY') + '</span>'
  end

  def copyright
    t('copyright', year: Date.today.year.to_s).html_safe
  end

  def convert_season_cd(season_cd)
    case season_cd.to_s
      when Settings.COURSE_SEASONCD_SPRING.to_s then
        return t("common.COMMON_SEASONCD1")
      when Settings.COURSE_SEASONCD_SUMMER.to_s then
        return t("common.COMMON_SEASONCD2")
      when Settings.COURSE_SEASONCD_AUTUMN.to_s then
        return t("common.COMMON_SEASONCD3")
      when Settings.COURSE_SEASONCD_WINTER.to_s then
        return t("common.COMMON_SEASONCD4")
      when Settings.COURSE_SEASONCD_FIRSTTERM.to_s then
        return t("common.COMMON_SEASONCD5")
      when Settings.COURSE_SEASONCD_LASTTERM.to_s then
        return t("common.COMMON_SEASONCD6")
      when Settings.COURSE_SEASONCD_CONCENTRATION.to_s then
        return t("common.COMMON_SEASONCD7")
      when Settings.COURSE_SEASONCD_OVERYEAR.to_s then
        return t("common.COMMON_SEASONCD8")
      when Settings.COURSE_SEASONCD_OTHER.to_s then
        return t("common.COMMON_SEASONCD9")
    end

    return ""
  end

  def season_list(type = nil)
    type = :blank unless type
    case type
    when :all
      seasons = [[t("system_usage.SYS_CONFIRMSYSTEMLOG_ALL"), ""]]
    when :blank
      seasons = [[t("common.COMMON_NOTHING"), Settings.COURSE_SEASONCD_INDEFINITE]]
    else
      seasons = []
    end

    seasons + [
      [t("common.COMMON_SEASONCD1"), Settings.COURSE_SEASONCD_SPRING],
      [t("common.COMMON_SEASONCD2"), Settings.COURSE_SEASONCD_SUMMER],
      [t("common.COMMON_SEASONCD3"), Settings.COURSE_SEASONCD_AUTUMN],
      [t("common.COMMON_SEASONCD4"), Settings.COURSE_SEASONCD_WINTER],
      [t("common.COMMON_SEASONCD5"), Settings.COURSE_SEASONCD_FIRSTTERM],
      [t("common.COMMON_SEASONCD6"), Settings.COURSE_SEASONCD_LASTTERM],
      [t("common.COMMON_SEASONCD7"), Settings.COURSE_SEASONCD_CONCENTRATION],
      [t("common.COMMON_SEASONCD8"), Settings.COURSE_SEASONCD_OVERYEAR],
      [t("common.COMMON_SEASONCD9"), Settings.COURSE_SEASONCD_OTHER]
    ]
  end

  def convert_day_cd(day_cd)
    case day_cd.to_s
      when Settings.COURSE_DAYCD_MON.to_s then
        return t("common.COMMON_DAYCD1")
      when Settings.COURSE_DAYCD_TUE.to_s then
        return t("common.COMMON_DAYCD2")
      when Settings.COURSE_DAYCD_WED.to_s then
        return t("common.COMMON_DAYCD3")
      when Settings.COURSE_DAYCD_THU.to_s then
        return t("common.COMMON_DAYCD4")
      when Settings.COURSE_DAYCD_FRI.to_s then
        return t("common.COMMON_DAYCD5")
      when Settings.COURSE_DAYCD_SAT.to_s then
        return t("common.COMMON_DAYCD6")
      when Settings.COURSE_DAYCD_SUN.to_s then
        return t("common.COMMON_DAYCD7")
    end

    return ""
  end

  def day_list
    [
      [t("common.COMMON_NOTHING"), Settings.COURSE_DAYCD_INDEFINITE],
      [t("common.COMMON_DAYCD1"), Settings.COURSE_DAYCD_MON],
      [t("common.COMMON_DAYCD2"), Settings.COURSE_DAYCD_TUE],
      [t("common.COMMON_DAYCD3"), Settings.COURSE_DAYCD_WED],
      [t("common.COMMON_DAYCD4"), Settings.COURSE_DAYCD_THU],
      [t("common.COMMON_DAYCD5"), Settings.COURSE_DAYCD_FRI],
      [t("common.COMMON_DAYCD6"), Settings.COURSE_DAYCD_SAT],
      [t("common.COMMON_DAYCD7"), Settings.COURSE_DAYCD_SUN]
    ]
  end

  def convert_hour_cd(hour_cd)
    case hour_cd.to_s
      when Settings.COURSE_HOURCD_FIRST.to_s then
        return t("common.COMMON_HOURCD1")
      when Settings.COURSE_HOURCD_SECOND.to_s then
        return t("common.COMMON_HOURCD2")
      when Settings.COURSE_HOURCD_THIRD.to_s then
        return t("common.COMMON_HOURCD3")
      when Settings.COURSE_HOURCD_FOURTH.to_s then
        return t("common.COMMON_HOURCD4")
      when Settings.COURSE_HOURCD_FIFTH.to_s then
        return t("common.COMMON_HOURCD5")
      when Settings.COURSE_HOURCD_SIXTH.to_s then
        return t("common.COMMON_HOURCD6")
      when Settings.COURSE_HOURCD_SEVENTH.to_s then
        return t("common.COMMON_HOURCD7")
      when Settings.COURSE_HOURCD_EIGHTH.to_s then
        return t("common.COMMON_HOURCD8")
    end

    return ""
  end

  def hour_list
    [
      [t("common.COMMON_NOTHING"), Settings.COURSE_HOURCD_INDEFINITE],
      [t("common.COMMON_HOURCD1"), Settings.COURSE_HOURCD_FIRST],
      [t("common.COMMON_HOURCD2"), Settings.COURSE_HOURCD_SECOND],
      [t("common.COMMON_HOURCD3"), Settings.COURSE_HOURCD_THIRD],
      [t("common.COMMON_HOURCD4"), Settings.COURSE_HOURCD_FOURTH],
      [t("common.COMMON_HOURCD5"), Settings.COURSE_HOURCD_FIFTH],
      [t("common.COMMON_HOURCD6"), Settings.COURSE_HOURCD_SIXTH],
      [t("common.COMMON_HOURCD7"), Settings.COURSE_HOURCD_SEVENTH],
      [t("common.COMMON_HOURCD8"), Settings.COURSE_HOURCD_EIGHTH]
    ]
  end

  def school_year_current_list(type = nil)
    type = :blank unless type
    case type
    when :all
      years = [[t("system_usage.SYS_CONFIRMSYSTEMLOG_ALL"), ""]]
    when :blank
      years = [[t("common.COMMON_NOTHING"), "0"]]
    else
      years = []
    end

    year = Time.zone.now.strftime('%Y')
    results = Course::get_year_list
    if results.count > 0
      (results.first[:school_year]..year.to_i).each{|num|
        years.push([num, num])
      }
    else
      years.push([year.to_i, year.to_i])
    end
    years.push([year.to_i + 1, year.to_i + 1])

    case type
    when :year
      years.push([t("admin.course.PRI_ADM_COU_COURSEBATCHDELETE_SCHOOLYEAR_ALL"), 0])
    end

    return years
  end

  def school_year_list(type = nil)
    type = :blank unless type
    case type
    when :all
      years = [[t("system_usage.SYS_CONFIRMSYSTEMLOG_ALL"), ""]]
    when :blank
      years = [[t("common.COMMON_NOTHING"), "0"]]
    else
      years = []
    end

    results = Course::get_year_list
    if results.count > 0
      results.each do |result|
        years.push([result.school_year, result.school_year])
      end
    else
      year = Time.zone.now.strftime('%Y')
      years.push([year.to_i, year.to_i])
    end

    case type
    when :year
      years.push([t("admin.course.PRI_ADM_COU_COURSEBATCHDELETE_SCHOOLYEAR_ALL"), 0])
    end

    return years
  end

  def class_session_count_list
    list = []
    Settings.CUSTOM_MAXCLASSSESSIONCOUNT.times do |count|
      list << [count+1, count+1]
    end
    return list
  end

  def group_folder_count_list
    list = []
    (Settings.CUSTOM_MAXGROUPFOLDERCOUNT+1).times do |count|
      list << [count, count]
    end
    return list
  end

  def get_name_no_prefix(value)
    return "" unless value

		if (0 < Settings.CUSTOM_NAMENOPREFIXSTARTNO && 0 < Settings.CUSTOM_NAMENOPREFIXENDNO)
			ret = value

		elsif (Settings.CUSTOM_NAMENOPREFIXSTARTNO < 0 && Settings.CUSTOM_NAMENOPREFIXENDNO >= 0 && Settings.CUSTOM_NAMENOPREFIXENDNO <= value.size)
			ret = value[Settings.CUSTOM_NAMENOPREFIXENDNO, value.size]

		elsif (Settings.CUSTOM_NAMENOPREFIXSTARTNO < 0 && Settings.CUSTOM_NAMENOPREFIXENDNO > value.size)
			ret = value;

		elsif (Settings.CUSTOM_NAMENOPREFIXSTARTNO >= 0 && Settings.CUSTOM_NAMENOPREFIXENDNO <= value.size && Settings.CUSTOM_NAMENOPREFIXSTARTNO <= Settings.CUSTOM_NAMENOPREFIXENDNO)
			ret = value[0, Settings.CUSTOM_NAMENOPREFIXSTARTNO] + value[Settings.CUSTOM_NAMENOPREFIXENDNO, value.size]

		elsif (Settings.CUSTOM_NAMENOPREFIXSTARTNO >= 0 && Settings.CUSTOM_NAMENOPREFIXSTARTNO <= value.size && Settings.CUSTOM_NAMENOPREFIXENDNO > value.size)
			ret = value[0, Settings.CUSTOM_NAMENOPREFIXSTARTNO]

		else
			ret = value
		end

		return ret;
  end

  def role_name(value)
    case value
    when Settings.USR_AUTHCD_ADMINISTRATOR
      t("common.COMMON_ADMINISTRATOR")
    when Settings.USR_AUTHCD_INSTRUCTOR
      t("common.COMMON_INSTRUCTOR")
    when Settings.USR_AUTHCD_STUDENT
      t("common.COMMON_STUDENT")
    end
  end

  def convert_indirect_use_flag(flag)
    case flag
    when Settings.COURSE_INDIRECTUSEFLG_DIRECT
      return t('admin.course.PRI_ADM_COU_REGISTERCOURSE_INDIRECTUSEFLG_DIRECT')
    when Settings.COURSE_INDIRECTUSEFLG_INDIRECT
      return t('admin.course.PRI_ADM_COU_REGISTERCOURSE_INDIRECTUSEFLG_INDIRECT')
    end
  end

  def convert_term_flag(flag)
    case flag.to_s
    when Settings.COURSE_TERMFLG_EFFECTIVE.to_s
      return t('common.COMMON_USE')
    when Settings.COURSE_TERMFLG_INVALIDITY.to_s
      return t('common.COMMON_NOTUSE')
    end
  end

  def convert_open_course_flag(flag)
    case flag
    when Settings.COURSE_OPENCOURSEFLG_PUBLIC
      return t('common.COMMON_OPEN')
    when Settings.COURSE_OPENCOURSEFLG_PRIVATE
      return t('common.COMMON_NOTOPEN')
    end
  end

  def convert_announcement_cd(cd)
    case cd.to_s
    when "1"
      return t('common.COMMON_USE')
    when "0"
      return t('common.COMMON_NOTUSE')
    end
  end

  def convert_open_course_announcement_flag(flag)
    if flag == 1
      return t('common.COMMON_OPEN')
    else
      return t('common.COMMON_NOTOPEN')
    end
  end

  def convert_faq_cd(cd)
    case cd.to_s
    when "1"
      return t('common.COMMON_USE')
    when "0"
      return t('common.COMMON_NOTUSE')
    end
  end

  def convert_open_course_faq_flag(flag)
    if flag == 1
      return t('common.COMMON_OPEN')
    else
      return t('common.COMMON_NOTOPEN')
    end
  end

  def convert_unread_assignment_display_cd(cd)
    case cd.to_s
    when Settings.UNREAD_DISPLAYFLG_ON.to_s
      return t('common.COMMON_DO_DISPLAY')
    when Settings.UNREAD_DISPLAYFLG_OFF.to_s
      return t('common.COMMON_DONOT_DISPLAY')
    end
  end

  def convert_unread_faq_display_cd(cd)
    case cd.to_s
    when Settings.UNREAD_DISPLAYFLG_ON.to_s
      return t('common.COMMON_DO_DISPLAY')
    when Settings.UNREAD_DISPLAYFLG_OFF.to_s
      return t('common.COMMON_DONOT_DISPLAY')
    end
  end

  def convert_delete_flag(flag)
    case flag.to_s
    when "1"
      return t('common.COMMON_ON')
    when "0"
      return t('common.COMMON_OFF')
    end
  end

  def convert_password(password)
    "*" * password.length
  end

  def convert_move_cd(cd)
    User::MOVE_LIST[cd]
  end

  def option_range(min, max)
    list = {}
    min.upto(max) do |i|
      list[i] = i
    end
    list
  end

  def convert_pattern_cd(cd)
    case cd
    when Settings.QUESTION_PATTERNCD_RADIO
      t("materials_registration.MAT_REG_REGISTERQUESTION_SELECTTYPE1")
    when Settings.QUESTION_PATTERNCD_ONELIST
      t("materials_registration.MAT_REG_REGISTERQUESTION_SELECTTYPE2")
    when Settings.QUESTION_PATTERNCD_CHECK
      t("materials_registration.MAT_REG_REGISTERQUESTION_SELECTTYPE3")
    when Settings.QUESTION_PATTERNCD_ESSAY
      t("materials_registration.MAT_REG_REGISTERQUESTION_SELECTTYPE4")
    end
  end

  def convert_string(value)
    if value.blank?
			return ""
    end

    ret = value.to_s

		## 「::」で区切られている時（お知らせ、FAQの時）は一度分解し、trimしてから再結合する
		if ret.index("::")
      ret = ret.gsub("::", "/").strip
		end

    ## 「::」で区切られていない時も念のためtrimする
    ret = ret.gsub("　", " ").strip

		## 表示の上限文字数を超えている時は、それ以降を「...」にする
		ret.truncate(Settings.DISPLAY_LIMIT);
  end

  def convert_evaluation_notify(value)
    if value == Settings.GENERICPAGE_SCOREOPENFLG_ON
      t("materials_registration.MAT_EVALUATIONLIST_RATE_NOTIFY")
    else
      t("materials_registration.MAT_EVALUATIONLIST_RATE_UNNOTIFY")
    end
  end

  def convert_mail_flag(mail_flag, announcement_cd)
    if mail_flag == Settings.ANNOUNCEMENT_MAILFLG_UNTRANSMISSION
      if announcement_cd == Settings.ANNOUNCEMENT_ANNOUNCEMENTCD_INFO
        t("converter.PRE_CON_ANNOUNCEMENTSTATECONVERTER_STATE1")
      end
    elsif mail_flag == Settings.ANNOUNCEMENT_MAILFLG_TRANSMITTED
      if announcement_cd == Settings.ANNOUNCEMENT_ANNOUNCEMENTCD_MAIL
        t("converter.PRE_CON_ANNOUNCEMENTSTATECONVERTER_STATE2")
      elsif announcement_cd == Settings.ANNOUNCEMENT_ANNOUNCEMENTCD_INFO
        t("converter.PRE_CON_ANNOUNCEMENTSTATECONVERTER_STATE3")
      end
    end
  end

  def convert_html(text)
    if text.blank?
      return "<br/>".html_safe
    end

    ret = text.gsub("\r\n", "<br/>")
    ret = ret.gsub("\r", "<br/>")
    ret = ret.gsub("\n", "<br/>")

    ret = ret.gsub("  ", "&nbsp;")

    ret.html_safe
  end

  def tooltip_text(text, max_length = 5, separator = "...")
    return "" if text.nil?

    if text.length > max_length
      short_text = text[0, max_length] + separator
      ret = "<span class=\"tooltip_text\" data-toggle=\"tooltip\" data-html=\"true\" title=\"#{text}\">#{short_text}</span>"
    else
      ret = text
    end

    ret.html_safe
  end

  def course_name_with_prefix(course)
    prefix = course.school_year.to_s
    unless course.season_cd.blank?
      season = convert_season_cd(course.season_cd)
      prefix += "/" + season unless season.blank?
    end
    prefix += "/" + course.course_cd.to_s

    "[#{prefix}] #{course.course_name}"
  end
end
