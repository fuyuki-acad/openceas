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

require 'csv'
require 'nkf'

class Teacher::AttendancesController < ApplicationController
  before_action :require_assigned, except: [:index]
  before_action :set_courses, only: [:index]
  before_action :set_course, except: [:index]

  def index
  end

  def show
    # 履修者がいる場合
    if @course.enrolled_users.count > 0
      # 出席情報の取得
      @attendance_data = get_attendance_data

      # 授業回数別に出席・遅刻・欠席数の取得
      @total_attendance_data = get_total_attendance_data(@attendance_data)

      # 授業回数別に確認回数の最大値を取得
      @attendance_count_list = get_attendance_count_list

      if params[:session_no]
        set_class_session

        # 収集中の出席を取得
        @attendance = get_collect_attendance
        if @attendance
          if @attendance.status_cd == Settings.ATTENDANCE_STATUSCD_ATTENDANCE
            @attendance_cd = 'attendance'
          elsif @attendance.status_cd == Settings.ATTENDANCE_STATUSCD_LATE
            @attendance_cd = 'late'
          end
        end
      end
    end
  end

  def output_csv
    # 授業回数別に確認回数の最大値を取得
    @attendance_count_list = get_attendance_count_list

    # 出席情報の取得
    @attendance_data = get_attendance_data

    # 授業回数別に出席・遅刻・欠席数の取得
    @total_attendance_data = get_total_attendance_data(@attendance_data)

    bom = %w(EF BB BF).map { |e| e.hex.chr }.join
    csv_data = CSV.generate(bom) do |csv|
#    csv_data = CSV.generate(headers: headers, write_headers: true, force_quotes: true) do |csv|
      # ヘッダ1
      header1 = []
      header1 << I18n.t('attendanceAdministration.COMMONATTENDANCEADMINISTRATION_COLUMNCLASSSESSIONNO')
      for class_session_count in 1..@course.class_session_count
        for attendance_count in 1..@attendance_count_list[class_session_count]
          header1 << I18n.t('common.COMMON_NO2') + class_session_count.to_s + I18n.t('common.COMMON_COUNT1')
        end
      end
      csv << header1

      # ヘッダ2
      header2 = []
      header2 << I18n.t('attendanceAdministration.COMMONATTENDANCEADMINISTRATION_COLUMNATTENDANCECOUNTNO')
      for class_session_count in 1..@course.class_session_count
        for attendance_count in 1..@attendance_count_list[class_session_count]
          header2 << attendance_count.to_s + I18n.t('common.COMMON_COUNT2')
        end
      end
      csv << header2

      line1 = []
      line1 << I18n.t('attendanceAdministration.COMMONATTENDANCEADMINISTRATION_COLUMNATTENDANCE')
      for class_session_count in 1..@course.class_session_count
        for attendance_count in 1..@attendance_count_list[class_session_count]

          line1 << @total_attendance_data[1][class_session_count][attendance_count].to_s
        end
      end
      csv << line1

      line2 = []
      line2 << I18n.t('attendanceAdministration.COMMONATTENDANCEADMINISTRATION_COLUMNLATE')
      for class_session_count in 1..@course.class_session_count
        for attendance_count in 1..@attendance_count_list[class_session_count]
          line2 << @total_attendance_data[2][class_session_count][attendance_count].to_s
        end
      end
      csv << line2

      line3 = []
      line3 << I18n.t('attendanceAdministration.COMMONATTENDANCEADMINISTRATION_COLUMNABSENT')
      for class_session_count in 1..@course.class_session_count
        for attendance_count in 1..@attendance_count_list[class_session_count]
          line3 << @total_attendance_data[3][class_session_count][attendance_count].to_s
        end
      end
      csv << line3

      @course.enrolled_users.each.with_index(1) do |user, user_index|
        line4 = []
        line4 << user.get_name_no_prefix + user.user_name
        for class_session_count in 1..@course.class_session_count
          for attendance_count in 1..@attendance_count_list[class_session_count]
            if @attendance_data[user.id][class_session_count][attendance_count] == Settings.ATTENDANCEINFO_ATTENDANCEDATACD_ATTENDANCE
              line4 << I18n.t('attendanceAdministration.COMMONATTENDANCEADMINISTRATION_ATTENDANCE')
            elsif @attendance_data[user.id][class_session_count][attendance_count] == Settings.ATTENDANCEINFO_ATTENDANCEDATACD_LATE
              line4 << I18n.t('attendanceAdministration.COMMONATTENDANCEADMINISTRATION_LATE')
            elsif @attendance_data[user.id][class_session_count][attendance_count] == Settings.ATTENDANCEINFO_ATTENDANCEDATACD_ABSENT
              line4 << I18n.t('attendanceAdministration.COMMONATTENDANCEADMINISTRATION_ABSENT')
            else
              line4 << ""
            end
          end
        end
        csv << line4
      end
    end

    respond_to do |format|
      format.html
      format.csv {send_data csv_data, filename: "attendance.csv"}
    end
  end

  def attendance_input
    class_session_count = params[:class_session_count]
    attendance_count = params[:attendance_count]

    # 授業回数別に確認回数の最大値を取得
    attendance_count_list = get_attendance_count_list

    # 出席情報の取得
    attendance_data = get_attendance_data

    bom = %w(EF BB BF).map { |e| e.hex.chr }.join
    csv_data = CSV.generate(bom) do |csv|
      # ●出席表
      csv << [I18n.t('attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_CSV_HEADER1')]

      # ★科目ID
      csv << [I18n.t('attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_CSV_HEADER2'), @course.id]

      # ★授業回数
      csv << [I18n.t('attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_CSV_HEADER3'), class_session_count]

      # ★確認回数
      csv << [I18n.t('attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_CSV_HEADER4'), attendance_count]

      # ●科目名
      csv << [I18n.t('attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_CSV_HEADER5'), @course.course_name]

      csv << []

      csv << [I18n.t('attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_CSV_HEADER_EXPLANATION1')]
      csv << [I18n.t('attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_CSV_HEADER_EXPLANATION2')]
      csv << [I18n.t('attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_CSV_HEADER_EXPLANATION3')]
      csv << [I18n.t('attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_CSV_HEADER_EXPLANATION4')]
      csv << [I18n.t('attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_CSV_HEADER_EXPLANATION5')]
      csv << [I18n.t('attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_CSV_HEADER_EXPLANATION6')]
      csv << [I18n.t('attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_CSV_HEADER_EXPLANATION7')]
      csv << [I18n.t('attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_CSV_HEADER_EXPLANATION8')]
      csv << [I18n.t('attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_CSV_HEADER_EXPLANATION9')]
      csv << [I18n.t('attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_CSV_HEADER_EXPLANATION10')]

      csv << []
      csv << []
      csv << []

      # ヘッダ1
      header1 = []
      header1 << I18n.t('attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_CSV_HEADER6')
      header1 << I18n.t('attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_CSV_HEADER7')
      header1 << I18n.t('attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_CSV_HEADER8')
      header1 << I18n.t('attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_CSV_HEADER9')
      csv << header1

      @course.enrolled_users.each.with_index(1) do |user, user_index|
        line1 = []

        line1 << CsvAttendance::BUS_SER_IMP_IMP_IDENTIFICATIONCD
        line1 << user.id
        line1 << user.user_name
        if attendance_data[user.id][class_session_count.to_i]
          if attendance_data[user.id][class_session_count.to_i][attendance_count.to_i] == Settings.ATTENDANCEINFO_ATTENDANCEDATACD_UNREGISTRATION
            line1 << ""
          elsif attendance_data[user.id][class_session_count.to_i][attendance_count.to_i] == Settings.ATTENDANCEINFO_ATTENDANCEDATACD_ATTENDANCE
            line1 << I18n.t('attendanceAdministration.COMMONATTENDANCEADMINISTRATION_ATTENDANCE')
          elsif attendance_data[user.id][class_session_count.to_i][attendance_count.to_i] == Settings.ATTENDANCEINFO_ATTENDANCEDATACD_LATE
            line1 << I18n.t('attendanceAdministration.COMMONATTENDANCEADMINISTRATION_LATE')
          elsif attendance_data[user.id][class_session_count.to_i][attendance_count.to_i] == Settings.ATTENDANCEINFO_ATTENDANCEDATACD_ABSENT
            line1 << I18n.t('attendanceAdministration.COMMONATTENDANCEADMINISTRATION_ABSENT')
          end
        else
          line1 << ""
        end
        csv << line1
      end
    end

#    explanatory += csv_data
    respond_to do |format|
      format.html
#      format.csv {send_data explanatory}
      format.csv {send_data csv_data, filename: "attendanceInput.csv"}
    end
  end

  def edit
    @class_session_count = params[:class_session_count].to_i
    @attendance_count = params[:attendance_count].to_i

    # 出席情報の取得
    @attendance_data = get_attendance_data

    # 授業回数別に出席・遅刻・欠席数の取得
    @total_attendance_data = get_total_attendance_data(@attendance_data)

    session[:class_session_count] = params[:class_session_count]
    session[:attendance_count] = params[:attendance_count]
  end

  def update
    course_id = params[:course_id]
    class_session_count = session[:class_session_count]
    attendance_count = session[:attendance_count]
    session[:class_session_count] = nil
    session[:attendance_count] = nil

    attendance_data = params[:attendance_data]

    begin
      Attendance.transaction do
        attendance_data.each do |user_id, attendance_data_cd|
          # 指定した科目と授業回数の出席を取得
          attendance = @course.attendances.where(:class_session_no => class_session_count, :attendance_count => attendance_count).first

          # 出席がある場合
          if attendance
            # 指定した出席と生徒の出席情報を取得
            attendance_information = attendance.attendance_information.where(:user_id => user_id).first
            # 出席情報がある場合
            if attendance_information
              if attendance_information.attendance_data_cd.to_s != attendance_data_cd
                # 出席情報を更新
                attendance_information_params = {}
                attendance_information_params[:attendance_data_cd] = attendance_data_cd
                attendance_information.update!(attendance_information_params)
              end
            else
              # 出席情報が変更されている場合
              if '0' != attendance_data_cd
                # 出席情報を生成、登録
                attendance_information_params = {}
                attendance_information_params[:attendance_id] = attendance.id
                attendance_information_params[:user_id] = user_id
                attendance_information_params[:attendance_data_cd] = attendance_data_cd
                attendance_information_params[:insert_user_id] = User.current_user.id
                attendance_information = AttendanceInformation.new(attendance_information_params)
                attendance_information.save!
              end
            end
          else
            # 出席情報が変更されている場合
            if '0' != attendance_data_cd
              # 出席を生成、登録
              attendance_params = {}
              attendance_params[:course_id] = course_id
              attendance_params[:class_session_no] = class_session_count
              attendance_params[:attendance_count] = attendance_count
              attendance_params[:insert_user_id] = User.current_user.id
              attendance = Attendance.new(attendance_params)
              attendance.save!

              # 出席情報を生成、登録
              attendance_information_params = {}
              attendance_information_params[:attendance_id] = attendance.id
              attendance_information_params[:user_id] = user_id
              attendance_information_params[:attendance_data_cd] = attendance_data_cd
              attendance_information_params[:insert_user_id] = User.current_user.id
              attendance_information = AttendanceInformation.new(attendance_information_params)
              attendance_information.save!
            end
          end
        end
      end
    rescue => e
      logger.error e.backtrace.join("\n")
      logger.debug(e.message)
    end

    redirect_to action: :edit, :class_session_count => class_session_count, :attendance_count => attendance_count
  end

  def batch_update
    # 出席情報の取得
    @attendance_data = get_attendance_data

    course_id = params[:course_id]
    class_session_count = session[:class_session_count]
    attendance_count = session[:attendance_count]
    session[:class_session_count] = nil
    session[:attendance_count] = nil

    if params[:update]
      attendance_data_cd = params[:attendance_data_cd].to_i
    else
      attendance_data_cd = 0
    end

    # 指定した科目と授業回数の出席を取得
    attendance = @course.attendances.where(:class_session_no => class_session_count, :attendance_count => attendance_count).first

    # 出席がある場合
    if attendance
      # 生徒数で繰り返し
      @attendance_data.each do |user_id, value|
        # 指定した出席と生徒の出席情報を取得
        attendance_information = attendance.attendance_information.where(:user_id => user_id).first
        if attendance_information
          # 出席情報を更新
          attendance_information_params = {}
          attendance_information_params[:attendance_data_cd] = params[:attendance_data_cd]
          attendance_information.update!(attendance_information_params)
        end
      end
    else
      # 出席を生成、登録
      attendance_params = {}
      attendance_params[:course_id] = course_id
      attendance_params[:class_session_no] = class_session_count
      attendance_params[:attendance_count] = attendance_count
      attendance_params[:insert_user_id] = User.current_user.id
      attendance = Attendance.new(attendance_params)
      attendance.save!

      # 生徒数で繰り返し
      @attendance_data.each do |user_id, value|
         # 出席情報を生成、登録
         attendance_information_params = {}
         attendance_information_params[:attendance_id] = attendance.id
         attendance_information_params[:user_id] = user_id
         attendance_information_params[:attendance_data_cd] = params[:attendance_data_cd]
         attendance_information_params[:insert_user_id] = User.current_user.id
         attendance_information = AttendanceInformation.new(attendance_information_params)
         attendance_information.save!
      end
    end

    redirect_to action: :edit, :class_session_count => class_session_count, :attendance_count => attendance_count
  end

  def edit_user
    @user = User.find(params[:user_id])

    # 出席情報の取得
    @attendance_data = get_attendance_data

    # 授業回数別に確認回数の最大値を取得
    @attendance_count_list = get_attendance_count_list

    session[:user_id] = params[:user_id]
  end

  def update_user
    user_id = session[:user_id]
    session[:user_id] = nil

    # 授業回数別に確認回数の最大値を取得
    @attendance_count_list = get_attendance_count_list

    course_id = params[:course_id]
    attendance_data = params[:attendance_data]

    # 授業回数で繰り返し
    begin
      Attendance.transaction do
        for class_session_count in 1..@course.class_session_count
          for attendance_count in 1..@attendance_count_list[class_session_count]
            # 指定した科目と授業回数の出席を取得
            attendance = @course.attendances.where(:class_session_no => class_session_count, :attendance_count => attendance_count).first
            # 出席がある場合
            if attendance
              # 指定した出席と生徒の出席情報を取得
              attendance_information = attendance.attendance_information.where(:user_id => user_id).first
              # 出席情報がある場合
              if attendance_information
                if attendance_information.attendance_data_cd.to_s != attendance_data[class_session_count.to_s][attendance_count.to_s]
                  # 出席情報を更新
                  attendance_information_params = {}
                  attendance_information_params[:attendance_data_cd] = attendance_data[class_session_count.to_s][attendance_count.to_s]
                  attendance_information.update!(attendance_information_params)
                end
              else
                # 出席情報が変更されている場合
                if '0' != attendance_data[class_session_count.to_s][attendance_count.to_s]
                  # 出席情報を生成、登録
                  attendance_information_params = {}
                  attendance_information_params[:attendance_id] = attendance.id
                  attendance_information_params[:user_id] = user_id
                  attendance_information_params[:attendance_data_cd] = attendance_data[class_session_count.to_s][attendance_count.to_s]
                  attendance_information_params[:insert_user_id] = User.current_user.id
                  attendance_information = AttendanceInformation.new(attendance_information_params)
                  attendance_information.save!
                end
              end
            else
              # 出席情報が変更されている場合
              if '0' != attendance_data[class_session_count.to_s][attendance_count.to_s]
                # 出席を生成、登録
                attendance_params = {}
                attendance_params[:course_id] = course_id
                attendance_params[:class_session_no] = class_session_count
                attendance_params[:attendance_count] = attendance_count
                attendance_params[:insert_user_id] = User.current_user.id
                attendance = Attendance.new(attendance_params)
                attendance.save!

                # 出席情報を生成、登録
                attendance_information_params = {}
                attendance_information_params[:attendance_id] = attendance.id
                attendance_information_params[:user_id] = user_id
                attendance_information_params[:attendance_data_cd] = attendance_data[class_session_count.to_s][attendance_count.to_s]
                attendance_information_params[:insert_user_id] = User.current_user.id
                attendance_information = AttendanceInformation.new(attendance_information_params)
                attendance_information.save!
              end
            end
          end
        end
      end
    rescue => e
      logger.error e.backtrace.join("\n")
      logger.debug(e.message)
    end

    redirect_to action: :edit_user, :user_id => user_id
  end

  def upload
    @class_session_count = params[:class_session_count].to_i
    @attendance_count = params[:attendance_count].to_i
  end

  def upload_confirm
    @class_session_count = params[:class_session_count].to_i
    @attendance_count = params[:attendance_count].to_i

    begin
      @csv = CsvAttendance.new(csv_params)

      if @csv.valid?
        FileUtils.mkdir_p(@csv.tmp_dir)
        File.open(@csv.temp_file, 'w+b') do |fp|
          fp.write @csv.file.read
        end

        # 出席情報の取得
        attendance_data = get_attendance_data

        # 解析結果
        @results = {"all" => 0, "error" => 0, "status_error" => 0, 0 => 0, 1 => 0, 2 => 0, 3 => 0}
        @success = {}

        users = {}
        @course.enrolled_users.each.with_index(1) do |user, user_index|
          users.store(user.id.to_s, user)
        end

        @csv_attendances = attendance_csv_to_hash(@csv.temp_file, users, attendance_data)

        session[:csv_attendance] = @csv.temp_file
      else
        @messages = I18n.t('registerList.PRI_REG_RESULTLIST_NOSELECTERROR')
        render :upload_result
      end
    rescue => e
      logger.error e.backtrace.join("\n")
      @messages = I18n.t('registerList.PRI_REG_RESULTLIST_NOSELECTERROR')
      render :upload_result
    end
  end

  def upload_error
    @class_session_count = params[:class_session_count].to_i
    @attendance_count = params[:attendance_count].to_i

    # 出席情報の取得
    attendance_data = get_attendance_data

    # 解析結果
    @results = {"all" => 0, "error" => 0, "status_error" => 0, 0 => 0, 1 => 0, 2 => 0, 3 => 0}
    @success = {}

    # ユーザ情報の取得
    users = {}
    @course.enrolled_users.each.with_index(1) do |user, user_index|
      users.store(user.id.to_s, user)
    end

    upload_file = "#{session[:csv_attendance]}"
    @csv_attendances = attendance_csv_to_hash(upload_file, users, attendance_data)
  end

  def update_file
    course_id = params[:course_id].to_i
    @class_session_count = params[:class_session_count].to_i
    @attendance_count = params[:attendance_count].to_i

    attendance_data = params[:attendance_data]

    @all_count = 0
    @success_count = 0
    begin
      Attendance.transaction do
        attendance_data.each do |user_id, attendance_data_cd|
          # 指定した科目と授業回数の出席を取得
          attendance = @course.attendances.where(:class_session_no => @class_session_count, :attendance_count => @attendance_count).first

          # 出席がある場合
          if attendance
            # 指定した出席と生徒の出席情報を取得
            attendance_information = attendance.attendance_information.where(:user_id => user_id).first
            # 出席情報がある場合
            if attendance_information
              if attendance_information.attendance_data_cd.to_s != attendance_data_cd
                # 出席情報を更新
                attendance_information_params = {}
                attendance_information_params[:attendance_data_cd] = attendance_data_cd
                attendance_information.update!(attendance_information_params)
                @success_count += 1
              end
            else
              # 出席情報が変更されている場合
              if '0' != attendance_data_cd
                # 出席情報を生成、登録
                attendance_information_params = {}
                attendance_information_params[:attendance_id] = attendance.id
                attendance_information_params[:user_id] = user_id
                attendance_information_params[:attendance_data_cd] = attendance_data_cd
                attendance_information_params[:insert_user_id] = User.current_user.id
                attendance_information = AttendanceInformation.new(attendance_information_params)
                attendance_information.save!
                @success_count += 1
              end
            end
          else
            # 出席情報が変更されている場合
            if '0' != attendance_data_cd
              # 出席を生成、登録
              attendance_params = {}
              attendance_params[:course_id] = course_id
              attendance_params[:class_session_no] = @class_session_count
              attendance_params[:attendance_count] = @attendance_count
              attendance_params[:insert_user_id] = User.current_user.id

              attendance = Attendance.new(attendance_params)
              attendance.save!

              # 出席情報を生成、登録
              attendance_information_params = {}
              attendance_information_params[:attendance_id] = attendance.id
              attendance_information_params[:user_id] = user_id
              attendance_information_params[:attendance_data_cd] = attendance_data_cd
              attendance_information_params[:insert_user_id] = User.current_user.id
              attendance_information = AttendanceInformation.new(attendance_information_params)
              attendance_information.save!
              @success_count += 1
            end
          end
        end

        @all_count += 1
      end
    rescue => e
      logger.debug(e.message)
    end

    render :upload_result
  end

  def attendance_csv_to_hash(upload_file, users, attendance_data)
    lineno = 0
    index = 0
    attendances = []
    accounts = []
    @errors = {}

    csv_data = CSV.parse(File.new(upload_file)) do |csv_row|
      case lineno
      when 1
        # 科目IDが違う場合
        if csv_row[1] != @course.id.to_s
          @messages = I18n.t('registerList.PRI_REG_IMPORTRESUL_SUBJECTIDRERROR')
          break
        end
      when 2
        # 授業回数が違う場合
        if csv_row[1] != @class_session_count.to_s
          @messages = I18n.t('attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_CSV_UPLOAD_ERROR1')
          break
        end
      when 3
        # 確認回数が違う場合
        if csv_row[1] != @attendance_count.to_s
          @messages = I18n.t('attendanceAdministration.ATT_ADM_CLASSSESSIONATTENDANCE_CSV_UPLOAD_ERROR2')
          break
        end
      end

      if lineno > (CsvAttendance::CSV_DATA_START_LINENO + CsvAttendance::HEADER_LINENO)
        line = {}
        line["identification_cd"] = csv_row[0]
        line["usr_id"] = csv_row[1]
        line["usr_name"] = csv_row[2]
        line["status"] = csv_row[3]
        index += 1
        attendances << line

        if users[line["usr_id"]]
          @results["all"] += 1

          unless @success[line["usr_id"]]
            if line["status"].blank?
              new_status = ""
              @results[0] += 1
              @results["status_error"] += 1
            else
              case line["status"]
              when I18n.t('attendanceAdministration.COMMONATTENDANCEADMINISTRATION_ATTENDANCE') then
                new_status = 1
                @results[1] += 1
              when I18n.t('attendanceAdministration.COMMONATTENDANCEADMINISTRATION_LATE') then
                new_status = 2
                @results[2] += 1
              when I18n.t('attendanceAdministration.COMMONATTENDANCEADMINISTRATION_ABSENT') then
                new_status = 3
                @results[3] += 1
              else
                new_status = -1
                @results[0] += 1
                @results["status_error"] += 1
              end
            end

            if attendance_data[line["usr_id"].to_i][@class_session_count][@attendance_count].blank?
              status = ""
            else
              status = attendance_data[line["usr_id"].to_i][@class_session_count][@attendance_count]
            end
            @success.store(line["usr_id"], {"user_name" => line["usr_name"], "status" => status, "new_status" => new_status})

          end
        else
          @results["error"] += 1
        end

        if users[line["usr_id"]]
          if line["status"].blank?
            new_status = 0
          else
            case line["status"]
            when I18n.t('attendanceAdministration.COMMONATTENDANCEADMINISTRATION_ATTENDANCE') then
              new_status = 1
            when I18n.t('attendanceAdministration.COMMONATTENDANCEADMINISTRATION_LATE') then
              new_status = 2
            when I18n.t('attendanceAdministration.COMMONATTENDANCEADMINISTRATION_ABSENT') then
              new_status = 3
            else
              new_status = -1
            end
          end

          if attendance_data[line["usr_id"].to_i] && attendance_data[line["usr_id"].to_i][@class_session_count][@attendance_count]
            status = attendance_data[line["usr_id"].to_i][@class_session_count][@attendance_count]
          else
            status = ""
          end

          if new_status == status
            @errors[index] = I18n.t('registerList.PRI_REG_RESULT_NOT_REGISTERED_BY_NOCHANGE')
          else
            @errors[index] = I18n.t('registerList.PRI_REG_RESULT_REGISTERED')
          end
        else
          @errors[index] = I18n.t('registerList.PRI_REG_RESULTLIST_ACOUNTERROR')
        end
      end
      lineno += 1
    end

    attendances
  end

  # 確認回数のリストを取得
  def get_attendance_count_list
    # 初期値を1に設定
    attendance_count_list = []
    for class_session_count in 0..@course.class_session_count
      attendance_count_list << 1
    end

    # 出席がある場合
    if @course.attendances.count > 0
      # 各授業回数ごとに確認回数の最大値を取得
      max_count = 1

      # 授業回数の取得
      class_session_no = @course.attendances.first.class_session_no

      @course.attendances.each do |attendance|
        # 最大値を設定
        attendance_count_list[attendance.class_session_no] = attendance.attendance_count
      end
    end

    return attendance_count_list
  end

  def get_attendance_data
    # 出席情報の配列[学生数][授業回数][確認回数の最大値]
    results = {}

    @course.enrolled_users.each do |user|
      results.store(user.id, {})
      for class_session_count in 0..@course.class_session_count
        results[user.id].store(class_session_count, {})

        @course.attendances.where(class_session_no: class_session_count).each do |attendance|
          # 出席情報があれば、出席情報コードを入れる
          attendance.attendance_information.each do |attendance_information|
            if results.has_key?(attendance_information.user_id)
              results[attendance_information.user_id][class_session_count].store(attendance.attendance_count, attendance_information.attendance_data_cd)
            end
          end
        end
      end
    end

    return results
  end

  def get_total_attendance_data(attendance_data)
    # 出席情報から出席・遅刻・欠席をカウントした配列[出席・遅刻・欠席][授業回数][確認回数の最大値]
    results = {}

    # 出席・遅刻・欠席
    num = 3

    for index in 1..num
      results.store(index, {})
      for class_session_count in 0..@course.class_session_count
        results[index].store(class_session_count, {})

        @course.attendances.where(class_session_no: class_session_count).each do |attendance|
          # 出席情報があれば、出席情報コードを入れる
          attendance.attendance_information.each do |attendance_information|
            results[index][class_session_count].store(attendance.attendance_count, 0)
          end
        end
      end
    end

    attendance_data.each do |user_id, user_class_sessions|
      user_class_sessions.each do |class_session_count, user_attendances|
        user_attendances.each do |attendance_count, attendance_data_cd|
          if attendance_data_cd == Settings.ATTENDANCEINFO_ATTENDANCEDATACD_ATTENDANCE
            results[1][class_session_count][attendance_count] += 1
          elsif attendance_data_cd == Settings.ATTENDANCEINFO_ATTENDANCEDATACD_LATE
            results[2][class_session_count][attendance_count] += 1
          elsif attendance_data_cd == Settings.ATTENDANCEINFO_ATTENDANCEDATACD_ABSENT
            results[3][class_session_count][attendance_count] += 1
          end
        end
      end
    end

    return results
  end

  private
    def csv_params
      params.require(:upload).permit(:file)
    end

    def set_class_session
      if params[:session_no]
        if params[:session_no] =~ /^[0-9]+$/ && params[:session_no].to_i <= @course.class_session_count
          @class_session = @course.class_session(params[:session_no])
          unless @class_session
            @class_session = ClassSession.new
            @class_session.class_session_day = I18n.t("common.COMMON_COUNTFORM", :param0 => params[:session_no])
            @class_session.class_session_no = params[:session_no]
          end
        else
          render :index
        end
      else
        render :index
      end
    end

    def get_collect_attendance
      attendance_collect = @course.attendances.where("class_session_no = ? AND status_cd = ?", @class_session.class_session_no, Settings.ATTENDANCE_STATUSCD_ATTENDANCE).first

      unless attendance_collect
        attendance_collect = @course.attendances.where("class_session_no = ? AND status_cd = ?", @class_session.class_session_no, Settings.ATTENDANCE_STATUSCD_LATE).first
      end

      return attendance_collect
    end
end
