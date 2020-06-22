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

class ClassSessionsController < ApplicationController
  before_action :require_assigned
  before_action :set_course, only: [:index, :show, :announcement, :faq, :specific_page, :collect_attendance, :start_collect_attendance, :stop_collect_attendance, :start_collect_late, :recollect_or_delete_attendance, :recollect_attendance, :recollect_late, :delete_attendance, :confirm_attendance]
  before_action :set_generic_page, only: [:compond, :essay]
  before_action :set_class_session, only: [:show, :collect_attendance, :start_collect_attendance, :stop_collect_attendance, :start_collect_late, :recollect_or_delete_attendance, :recollect_attendance, :recollect_late, :delete_attendance, :confirm_attendance]

  def index
    @class_sessions = {}
    @course.class_sessions.each do |session|
      @class_sessions[session.class_session_no] = session
    end

    create_access_log(@course.id)
  end

  def show
  end

  def announcement
    @announcements = Announcement.
      where("announcements.course_id = ? AND announcements.announcement_cd = ?", @course.id, Settings.COURSE_ANNOUNCEMENTCD_NORMAL).
      order("announcements.updated_at desc").page(params[:page])
  end

  def specific_page
    @specific_page = SpecificPage.find(params[:course_id])
    if @specific_page.get_specific_page_url
      redirect_to @specific_page.get_specific_page_url
    end
  end

  def compond
  end

  def collect_attendance
    from_flag = 0
    to_another_flag = 0
    @attendance_period = 15
    @late_period = 15

    # 収集中の確認回数
    @collect_attendance_count

    # 収集の状態を表すコード
    @attendance_cd = "collect"

    if from_flag != 1
      # 授業実施画面から実行した場合
      # 1はありえない(2017/08)
      if to_another_flag != 1
        # 別授業へ行かない場合
        # 1はありえない(2017/08)
        @attendance_cd = params[:attendance_cd]
      else
        # 別授業へ行く場合
        @attendance_cd = "toAnother"
      end

      if @attendance_cd == "toAnother"
#        # 別授業の収集中画面へ行く時はその授業回数を取得
      else
#        # そうでない時は戻す
        @attendance_cd = "collect"
      end
    end

    # 収集中の出席を取得
    @attendance = get_collect_attendance

    if @attendance
      # 収集中でない時
    else
      # 出席／遅刻収集中の時
      # 収集する最新の出席回数を取得
      attendances = @course.attendances.where("class_session_no = ?", @class_session.class_session_no)

      if @attendance_cd == ATTENDANCE_CD_RECOLLECT || @attendance_cd == ATTENDANCE_CD_RECOLLECTLATE
        # 各授業の出席のリストを取得
      else
        @attendance_count = 1
        @attendance_count = attendances.count + 1 if attendances.count > 0
      end

      # 収集時間の初期値を設定
      if attendances.count < @attendance_count
        # 新しい確認回数の場合は新しく出席を作成
        attendance_params = {}
        attendance_params[:course_id] = @course.id
        attendance_params[:class_session_no] = @class_session.class_session_no
        attendance_params[:attendance_count] = @attendance_count
        attendance_params[:insert_user_id] = current_user.id
        @attendance = Attendance.new(attendance_params)
#        @attendance.save!
      else
        # 再収集の時か
        # 最収集は廃止
      end
    end
  end

  ATTENDANCE_CD_ATTENDANCE = "attendance"
  ATTENDANCE_CD_LATE = "late"
  ATTENDANCE_CD_END = "end"
  ATTENDANCE_CD_RECOLLECT = "recollectAttendance"
  ATTENDANCE_CD_RECOLLECTLATE = "recollectLate"
  ATTENDANCE_CD_RECOLLECT_OR_DELETE = "recollectOrDelete"
  ATTENDANCE_CD_DELETE = "delete"
  ATTENDANCE_CD_ERROR = "error"

  def start_collect_attendance
    @attendance_cd = params[:attendance_cd]
    @attendance_count = params[:attendance_count]
    @attendance_period = params[:attendance_period]
    @late_period = params[:late_period]

    attendance_params = {}
    attendance_params[:course_id] = @course.id
    attendance_params[:class_session_no] = @class_session.class_session_no
    attendance_params[:attendance_count] = @attendance_count
    attendance_params[:insert_user_id] = current_user.id
    @attendance = Attendance.new(attendance_params)

    # 出席／遅刻収集時間や収集開始時間などをset
#    date = Date.today.to_time
    date = Time.zone.now

    # 他で出席を取っていないかを確認
    # 収集中の出席を取得
    collecting_attendance = get_collect_attendance

    # 出席確認状況コード
    status_cd = ""

    # 他で出席／遅刻収集中の時
    if collecting_attendance && (collecting_attendance.status_cd == Settings.ATTENDANCE_STATUSCD_ATTENDANCE || collecting_attendance.status_cd == Settings.ATTENDANCE_STATUSCD_LATE)
      # 遅刻時間を過ぎている場合は収集終了
      if collecting_attendance.late_time.since(@late_period.to_i.minute) < date
        stop_collect_attendance
      else
        @attendance = collecting_attendance
        render :collect_attendance
      end
      return
    end

    @attendance.attendance_time = date
    @attendance.attendance_period = @attendance_period
    @attendance.late_time = @attendance.attendance_time.since(@attendance_period.to_i.minute)
    @attendance.late_period = @late_period
    if (collecting_attendance)
      @attendance.attendance_count = collecting_attendance.attendance_count + 1
    else
      @attendance.attendance_count = 1
    end
    @attendance.class_session_no = @class_session.class_session_no
    @attendance.insert_user_id = current_user.id
    @attendance.course_id = @course.id

    # 出席収集期間が0に設定されていない時
    if @attendance_period != 0
      # 出席収集中のフラグをセット
      @attendance.status_cd = Settings.ATTENDANCE_STATUSCD_ATTENDANCE

      # 出席をsaveもしくはupdateする
      if @attendance.save!
        # 再収集の場合
        # 欠席・遅刻で登録されている出席情報を初期化する
        AttendanceInformation.where(attendance_id: @attendance).destroy_all
      else
        @attendance_cd = ATTENDANCE_CD_ERROR
        return
      end

      # 残り収集時間・分を計算
      @rest_time = get_rest_time
      @rest_minute = @rest_time.ceil
#      @rest_minute = get_rest_minute

      # 残り収集時間・分をput
      @attendance_cd = ATTENDANCE_CD_ATTENDANCE
    else
      # すぐに遅刻収集へ
      start_collect_late
    end

    render :collect_attendance
  end

  def stop_collect_attendance
    @attendance = @course.attendances.where("class_session_no = ? AND attendance_count = ?", @class_session.class_session_no, params[:attendance_count]).first
    @attendance_count = params[:attendance_count]

    # 収集中でない、に設定
    @attendance.status_cd = Settings.ATTENDANCE_STATUSCD_NOTCOLLECTING
    # 出席をsaveもしくはupdateする
    if @attendance.save!
      # 再収集でない(saveした)場合
#      // saveしたcollectAttendanceを取得(collectAttendanceにはまだidがないため)
    else
      @attendance_cd = ATTENDANCE_CD_ERROR
      return
    end

    # 出席確認していない学生を欠席で登録
    @course.enrolled_users.each do |user|
      collect_attendance = AttendanceInformation.where("attendance_id = ? AND attendance_information.user_id = ?", @attendance.id, user.id).first
      unless collect_attendance
        attendance_information_params = {}
        attendance_information_params[:attendance_id] = @attendance.id
        attendance_information_params[:user_id] = user.id
        attendance_information_params[:attendance_data_cd] = Settings.ATTENDANCEINFO_ATTENDANCEDATACD_ABSENT
        attendance_information_params[:insert_user_id] = current_user.id
        attendance_information = AttendanceInformation.new(attendance_information_params)
        attendance_information.save!
      end
    end

    # コードを出席収集終了に設定
    @attendance_cd = ATTENDANCE_CD_END

    # 欠席者のリストを取得＆put

    @class_sessions = {}
    @course.class_sessions.each do |session|
      @class_sessions[session.class_session_no] = session
    end
logger.debug("Hello, world!")
logger.debug("#{@class_sessions}")
logger.debug("Hello, world!")

    render :collect_attendance
  end

  def start_collect_late
# stop_flag, to_another_flag実装までの暫定対応
    stop_flag = 0

    @attendance_cd = params[:attendance_cd]
    @attendance_count = params[:attendance_count]
    @attendance = @course.attendances.where("class_session_no = ? AND attendance_count = ?", @class_session.class_session_no, params[:attendance_count]).first

    # 違う遅刻収集時間が選択されていたら
    if params[:late_period] != @attendance.late_period
      @attendance.late_period = params[:late_period]
    end

    # 遅刻収集期間が0に設定されていない時
    if params[:late_period].to_i > 0
      # 遅刻収集開始時間、遅刻収集期間をset
      date = Time.zone.now
      @attendance.late_time = date

      # 今すぐ遅刻収集開始ボタンを押した時
      if stop_flag == 1
        @attendance.attendance_period = 0
      end

      # 遅刻収集中に設定
      @attendance.status_cd = Settings.ATTENDANCE_STATUSCD_LATE

      # 出席をsaveもしくはupdateする
      if @attendance.save!
        # 再収集の場合
        # 欠席で登録されている出席情報を初期化する
      else
        @attendance_cd = ATTENDANCE_CD_ERROR
        return
      end

      # 残り収集時間・分を計算
      @rest_time = get_rest_time
      @rest_minute = @rest_time.ceil
#      @rest_minute = get_rest_minute
      # 遅刻収集中に変更
      @attendance_cd = ATTENDANCE_CD_LATE
    else
      # すぐに収集を終了する
      stop_collect_attendance
    end

    render :collect_attendance
  end

  def recollect_or_delete_attendance
    @attendances = @course.attendances.where("class_session_no = ?", @class_session.class_session_no)
    @attendance_cd = ATTENDANCE_CD_RECOLLECT_OR_DELETE
    @attendance_count = params[:attendance_count]

    render :collect_attendance
  end

  def recollect_attendance
    @attendance_count = params[:attendance_count]
    @attendance = @course.attendances.where("class_session_no = ? AND attendance_count = ?", @class_session.class_session_no, @attendance_count).first

    # 以前収集した収集期間を設定
    @attendance_period = @attendance.attendance_period
    @late_period = @attendance.late_period
    @recollect_attendance_count = @attendance.attendance_count

    # フラグを出席情報再収集に設定
    @attendance_cd = ATTENDANCE_CD_RECOLLECT

    # 削除されていないかを確認
    @attendance = @course.attendances.where("class_session_no = ? AND attendance_count = ?", @class_session.class_session_no, @attendance_count).first
    unless @attendance
      # 出席情報を削除
      AttendanceInformation.where(attendance_id: @attendance).destroy_all
      @attendance_cd = ATTENDANCE_CD_LATE
    end

    render :collect_attendance
  end

  def recollect_late
    @attendance_count = params[:attendance_count]
    @attendance = @course.attendances.where("class_session_no = ? AND attendance_count = ?", @class_session.class_session_no, @attendance_count).first

    # 以前収集した収集期間を設定
    @late_period = @attendance.late_period
    @recollect_attendance_count = @attendance.attendance_count

    # フラグを遅刻情報再収集に設定
    @attendance_cd = ATTENDANCE_CD_RECOLLECTLATE

    # 削除されていないかを確認
    @attendance = @course.attendances.where("class_session_no = ? AND attendance_count = ?", @class_session.class_session_no, @attendance_count).first
    unless @attendance
      # 出席情報を削除
      AttendanceInformation.where(attendance_id: @attendance).destroy_all
      @attendance_cd = ATTENDANCE_CD_LATE
    end

    render :collect_attendance
  end

  def delete_attendance
    @attendance_count = params[:attendance_count]
    # 削除されていないかを確認
    @attendance = @course.attendances.where("class_session_no = ? AND attendance_count = ?", @class_session.class_session_no, @attendance_count).first
    if @attendance
      # 出席情報を削除
      AttendanceInformation.where(attendance_id: @attendance).destroy_all
      @attendance.delete
    end
    # 出席情報削除完了に設定
    @attendance_cd = ATTENDANCE_CD_DELETE

    render :collect_attendance
  end

  def prepare_help
  end

  def get_collect_attendance
    attendance_collect = @course.attendances.where("class_session_no = ?", @class_session.class_session_no).order(attendance_count: "DESC").first

    return attendance_collect
  end

  def get_rest_time
    # 収集開始時間
    collect_time = 0
    # 収集期間
    collect_period = 0
    # 現在の時間
    date = Time.zone.now
#    time = (new Date()).getTime();

    if @attendance.status_cd == Settings.ATTENDANCE_STATUSCD_ATTENDANCE
      # 出席収集中の時
      collect_time = @attendance.attendance_time
      collect_period = @attendance.attendance_period
    elsif @attendance.status_cd == Settings.ATTENDANCE_STATUSCD_LATE
      # 遅刻収集中の時
      collect_time = @attendance.late_time
      collect_period = @attendance.late_period
    end

    # 残り時間を計算
    rest_time = collect_time + collect_period - date;

    return rest_time;
  end

  def get_rest_minute
    rest_minute = 0

    conversion = 60000
    # おおまかな残り分を計算
    if @rest_minute % conversion == 0
      rest_minute = (@rest_minute / conversion).to_i
    else
      rest_minute = (@rest_minute / conversion + 1).to_i
    end

    return rest_minute;
  end








  def confirm_attendance
    # 履修管理者または担任者の時
    if current_user.role_id == Settings.USR_AUTHCD_ADMINISTRATOR || current_user.role_id == Settings.USR_AUTHCD_INSTRUCTOR
      @attendance_register_cd = "administratorOrInstructor";
    # 学生の時
    elsif current_user.role_id == Settings.USR_AUTHCD_STUDENT
      # リモートホストのIPアドレスを取得
      remote_ip = request.env["HTTP_X_FORWARDED_FOR"] || request.remote_ip
      # 有効なIPアドレスでない時
      if remote_ip == 1
        @attendance_register_cd = "remoteAddressError";
      # 有効なIPアドレスの時
      else
        collect_attendance = @course.attendances.where("class_session_no = ? AND (status_cd = ? OR status_cd = ?)", @class_session.class_session_no, Settings.ATTENDANCE_STATUSCD_ATTENDANCE, Settings.ATTENDANCE_STATUSCD_LATE).first
        if collect_attendance
          # 出席／遅刻情報収集中の時
          if @class_session.class_session_no != collect_attendance.class_session_no
            @attendance_register_cd = "notCollecting";
          else
status_flag = true
            attendance_info = collect_attendance.attendance_information.where(:user_id => current_user.id).first
            # 出席情報がある時
            if attendance_info
              # 出席収集中の時
              if collect_attendance.status_cd == Settings.ATTENDANCE_STATUSCD_ATTENDANCE
                # 出席登録されている場合
                if collect_attendance.status_cd == Settings.ATTENDANCEINFO_ATTENDANCEDATACD_ATTENDANCE
status_flag = false;
                end
              # 遅刻収集中の時
              elsif collect_attendance.status_cd == Settings.ATTENDANCE_STATUSCD_LATE
                # 出席もしくは遅刻登録されている場合
                if collect_attendance.status_cd == Settings.ATTENDANCEINFO_ATTENDANCEDATACD_ATTENDANCE || collect_attendance.status_cd == Settings.ATTENDANCEINFO_ATTENDANCEDATACD_LATE
status_flag = false;
                end
              end
            end

            if status_flag
              # 出席情報収集中の時
              if collect_attendance.status_cd == Settings.ATTENDANCE_STATUSCD_ATTENDANCE
                @attendance_register_cd = ATTENDANCE_CD_ATTENDANCE
              # 遅刻情報収集中の時
              elsif collect_attendance.status_cd == Settings.ATTENDANCE_STATUSCD_LATE
                @attendance_register_cd = "late";
              end

              # 出席情報を登録
              attendance_information = AttendanceInformation.where("attendance_id = ? AND attendance_information.user_id = ?", collect_attendance.id, current_user.id).first

              if attendance_information
                # 出席情報がある時はupdate
                attendance_information.attendance_data_cd = collect_attendance.status_cd
                attendance_information.save!
              else
                # 出席情報がない時はsave
                attendance_information_params = {}
                attendance_information_params[:attendance_id] = collect_attendance.id
                attendance_information_params[:user_id] = current_user.id
                attendance_information_params[:attendance_data_cd] = collect_attendance.status_cd
                attendance_information_params[:insert_user_id] = current_user.id
                attendance_information = AttendanceInformation.new(attendance_information_params)
                attendance_information.save!
              end
            else
              @attendance_register_cd = "registered";
            end
          end
        else
          # 出席／遅刻情報収集中でない時
          @attendance_register_cd = "notCollecting";
        end
      end
    end
  end

  private
    def set_generic_page
      @generic_page = GenericPage.find(params[:generic_page_id])
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
end
