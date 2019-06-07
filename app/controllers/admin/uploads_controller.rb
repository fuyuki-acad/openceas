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

class Admin::UploadsController < ApplicationController
  BUS_SER_IMP_IMP_INSERTSTATUSCD = "1"
  BUS_SER_IMP_IMP_UPDATESTATUSCD = "2"
  BUS_SER_IMP_IMP_LOGICALDELETESTATUSCD = "3"
  BUS_SER_IMP_IMP_DELETESTATUSCD = "4"
  BUS_SER_IMP_IMP_NAMENOPREFIXUPDATESTATUSCD = "6"

  #
  # ユーザリストアップロード
  #
  def user
  end

  def user_sample_file
    sample_file(CsvUser::CSV_FILE_TYPE)
  end

  def user_confirm
    begin
      @csv = CsvUser.new(csv_params)

      if @csv.valid?
        if @csv.not_overwrite && !Dir["#{@csv.temp_file}"].empty?
          @messages = I18n.t('registerList.PRI_REG_RESULTLIST_NOTOVERWRITEERROR')
          render :user_result
        else
          FileUtils.mkdir_p(@csv.tmp_dir)
          File.open(@csv.temp_file, 'w+b') do |fp|
            fp.write @csv.file.read
          end
          session[:cav_user] = @csv.temp_file
        end
      else
        @messages = I18n.t('registerList.PRI_REG_RESULTLIST_NOSELECTERROR')
        render :user_result
      end
    rescue => e
      logger.error e.backtrace.join("\n")
      @messages = I18n.t('registerList.PRI_REG_RESULTLIST_NOSELECTERROR')
      render :user_result
    end
  end

  def user_import_file
    begin
      upload_file = "#{session[:cav_user]}"

      @users = user_csv_to_hash(upload_file)
      @error_code = 0

      # 読込行数を超えているかチェック
      raise I18n.t("registerList.PRI_REG_IMPORTRESUL_LIMITOVERERROR_html") if @users.count > CsvUser::BUS_UTI_CSV_LIMITCOUNT

      if @errors.count == 0
        import_users

        @error_code = 1
        @messages = I18n.t('registerList.PRI_REG_IMPORTRESUL_SUCCESS_html')
      else
        @error_code = 2
        @messages = I18n.t('registerList.PRI_REG_IMPORTRESUL_ERROR_html')
      end
    rescue => e
      logger.error e.backtrace.join("\n")
      @messages = e.message
    end
  end

  def user_error_list
    upload_file = "#{session[:cav_user]}"
    @users = user_csv_to_hash(upload_file)
    render :error_list
  end

  def user_destroy_file
    csv_user = CsvUser.new
    FileUtils.rm(Dir.glob("#{csv_user.tmp_dir}*.*"))
    @messages = I18n.t('registerList.PRI_REG_RESULTLIST_DELETE')
    render :user_result
   end

  def user_csv_to_hash(upload_file)
    lineno = 0
    users = []
    accounts = []
    @errors = {}

    csv_data = CSV.parse(File.new(upload_file)) do |csv_row|
      line = {}
      line["identification_cd"] = csv_row[0]
      line["status_cd"] = csv_row[1]
      line["account"] = csv_row[2]
      line["passwd"] = csv_row[3]
      line["name_no_prefix"] = csv_row[4]
      line["usr_name"] = csv_row[5]
      line["kana_name"] = csv_row[6]
      line["auth_cd"] = csv_row[7]
      line["sex_cd"] = csv_row[8]
      line["birth_date"] = csv_row[9]
      line["mail"] = csv_row[10]
      line["move_cd"] = csv_row[11]
      line["move_date"] = csv_row[12]
      line["efective_date"] = csv_row[13]
      users << line
      lineno += 1

      # ファイル内に同じキー項目を持つものがある場合
      if accounts.include?(line["account"])
        @errors[lineno] = I18n.t('registerList.PRI_REG_RESULTLIST_DUPLICATIONINFILEERROR')
        next
      end

      # 入力項目のバリデーション
      # ファイル内に同じキー項目を持つものがある場合
      find_user = User.find_by(:account => line["account"])

      # キー項目のバリデーション
      # 項目数が正しくない場合
      if line.count != CsvUser::BUS_UTI_CSV_COLUMNCOUNT
        @errors[lineno] = I18n.t('registerList.PRI_REG_RESULTLIST_COLUMNCOUNTERROR')
        next
      end

      # 識別子コードが入力されていない場合
      if line["identification_cd"].blank?
        @errors[lineno] = I18n.t('registerList.PRI_REG_RESULTLIST_IDENTIFICATIONCDNULLERROR')
        next
      end

      # 識別子コードが正しくない場合
      if line["identification_cd"] != CsvUser::BUS_SER_IMP_IMP_IDENTIFICATIONCD
        @errors[lineno] = I18n.t('registerList.PRI_REG_RESULTLIST_IDENTIFICATIONCDERROR')
        next
      end

      # ステータスコードが入力されていない場合
      if line["status_cd"].blank?
        @errors[lineno] = I18n.t('registerList.PRI_REG_RESULTLIST_STATUSCDNULLERROR')
        next
      end

      # アカウントのバリデーション
      # アカウントが入力されていない場合
      if line["account"].blank?
        @errors[lineno] = I18n.t('registerUsrList1.PRI_REG_RESULTLIST_ACCOUNTNULLERROR')
        next
      end

      # アカウントが設定文字数より多い
      if line["account"].length > CsvUser::BUS_SER_IMP_IMP_ACCOUNTMAXLENGTH
        @errors[lineno] = I18n.t('registerUsrList1.PRI_REG_RESULTLIST_ACCOUNTLONGERROR')
        next
      end

      # アカウントに指定文字以外が含まれている場合
      if CsvUser::BUS_SER_IMP_IMP_ACCOUNTFORMAT.match(line["account"])
        @errors[lineno] = I18n.t('registerUsrList1.PRI_REG_RESULTLIST_ACCOUNTFORMATERROR')
        next
      end

      case line["status_cd"]
      when BUS_SER_IMP_IMP_INSERTSTATUSCD,
           BUS_SER_IMP_IMP_UPDATESTATUSCD,
           BUS_SER_IMP_IMP_LOGICALDELETESTATUSCD then
        # パスワードのバリデーション
        if line["passwd"].blank?
          @errors[lineno] = I18n.t('registerUsrList1.PRI_REG_RESULTLIST_PASSWDNULLERROR')
          next
        end

        # パスワードが設定文字数より少ない場合
        if line["passwd"].length < CsvUser::BUS_SER_IMP_IMP_PASSWDMIMLENGTH
          @errors[lineno] = I18n.t('registerUsrList1.PRI_REG_RESULTLIST_PASSWDSHORTERROR')
          next
        end

        # パスワードが設定文字数より多い場合
        if line["passwd"].length > CsvUser::BUS_SER_IMP_IMP_PASSWDMAXLENGTH
          @errors[lineno] = I18n.t('registerUsrList1.PRI_REG_RESULTLIST_PASSWDLONGERROR')
          next
        end

        # パスワードに指定文字以外が含まれている場合
        if /[[:punct:]]/.match(line["passwd"])
          @errors[lineno] = I18n.t('registerUsrList1.PRI_REG_RESULTLIST_PASSWDFORMATERROR')
          next
        end

        # 氏名（漢字）のバリデーション
        # 氏名（漢字）が入力されていない場合
        if line["usr_name"].blank?
          @errors[lineno] = I18n.t('registerUsrList1.PRI_REG_RESULTLIST_USRNAMENULLERROR')
          next
        end

        # 氏名（漢字）が設定文字数より多い場合
        if line["usr_name"].length > CsvUser::BUS_SER_IMP_IMP_USRNAMEMAXLENGTH
          @errors[lineno] = I18n.t('registerUsrList1.PRI_REG_RESULTLIST_USRNAMELONGERROR')
          next
        end

        # 氏名（カナ）のバリデーション
        # 氏名（カナ）が設定文字数より多い場合
        if line["kana_name"] && line["kana_name"].length > CsvUser::BUS_SER_IMP_IMP_KANANAMEMAXLENGTH
          @errors[lineno] = I18n.t('registerUsrList1.BUS_SER_IMP_IMP_KANANAMELONGERROR')
          next
        end

        # 権限コードのバリデーション
        if line["auth_cd"].blank?
          @errors[lineno] = I18n.t('registerUsrList1.PRI_REG_RESULTLIST_AUTHCDNULLERROR')
          next
        end

        # 権限コードが指定以外の場合
        if !(line["auth_cd"] == Settings.USR_AUTHCD_ADMINISTRATOR.to_s ||
             line["auth_cd"] == Settings.USR_AUTHCD_INSTRUCTOR.to_s ||
             line["auth_cd"] == Settings.USR_AUTHCD_STUDENT.to_s)
          @errors[lineno] = I18n.t('registerUsrList1.PRI_REG_RESULTLIST_AUTHCDERROR')
          next
        end

        # 性別コードのバリデーション
        if !(line["sex_cd"] == Settings.USR_SEXCD_UNKOWN.to_s ||
             line["sex_cd"] == Settings.USR_SEXCD_MALE.to_s ||
             line["sex_cd"] == Settings.USR_SEXCD_FEMALE.to_s)
          @errors[lineno] = I18n.t('registerUsrList1.PRI_REG_RESULTLIST_SEXCDERROR')
          next
        end

        # 誕生日のバリデーション
        if !line["birth_date"].blank?
          begin
            Date.parse(line["birth_date"])
          rescue => e
            logger.error e.backtrace.join("\n")
            @errors[lineno] = I18n.t('registerUsrList1.PRI_REG_RESULTLIST_BIRTHDATEFORMATERROR')
            next
          end
        end

        # メールのバリデーション
        # メールが設定文字数より多い場合
        if line["mail"] && line["mail"].length > CsvUser::BUS_SER_IMP_IMP_MAILMAXLENGTH
          @errors[lineno] = I18n.t('registerUsrList1.PRI_REG_RESULTLIST_MAILLONGERROR')
          next
        end

        # メールの形式が正しくない場合
        if !line["mail"].blank?
          if CsvUser::BUS_SER_IMP_IMP_MAILFORMAT !~ line["mail"]
            @errors[lineno] = I18n.t('registerUsrList1.PRI_REG_RESULTLIST_MAILFORMATERROR')
            next
          end
        end

        # 移動コードのバリデーション
        if !line["move_cd"].blank?
          # 移動コードが指定以外の場合
          if !(line["move_cd"] == Settings.USR_MOVECD_ABSENCEMOVECD.to_s ||
               line["move_cd"] == Settings.USR_MOVECD_LEAVEMOVECD.to_s ||
               line["move_cd"] == Settings.USR_MOVECD_EXPELMOVECD.to_s ||
               line["move_cd"] == Settings.USR_MOVECD_MOVEOUTMOVECD.to_s ||
               line["move_cd"] == Settings.USR_MOVECD_GRADUATIONMOVECD.to_s)
            @errors[lineno] = I18n.t('registerUsrList1.PRI_REG_RESULTLIST_MOVECDERROR')
            next
          else
            # 移動日の形式が正しくない場合
            if !line["move_date"].blank?
              begin
                Date.parse(line["move_date"])
              rescue => e
                @errors[lineno] = I18n.t('registerUsrList1.BUS_SER_IMP_IMP_MOVEDATEFORMATERROR')
                next
              end
            end
          end
        end

        # 有効日のバリデーション
        if !line["efective_date"].blank?
          begin
            Date.parse(line["efective_date"])
          rescue => e
            @errors[lineno] = I18n.t('registerUsrList1.PRI_REG_RESULTLIST_EFFECTIVEDATEFORMATERROR')
            next
          end
        end
      when BUS_SER_IMP_IMP_NAMENOPREFIXUPDATESTATUSCD
        # 名列番号順のバリデーション
        # 名列番号順が入力されていない場合
        if line["name_no_prefix"].blank?
          @errors[lineno] = I18n.t('registerUsrList1.PRI_REG_RESULTLIST_NAMENOPREFIXNULLERROR')
          next
        end

        # 名列番号順が設定文字数より多い場合
        if line["name_no_prefix"].length > CsvUser::BUS_SER_IMP_IMP_NAMENOPREFIXMAXLENGTH
          @errors[lineno] = I18n.t('registerUsrList1.PRI_REG_RESULTLIST_NAMENOPREFIXLONGERROR')
          next
        end
      end

      # ステータスコードによって処理を分岐
      case line["status_cd"]
      when BUS_SER_IMP_IMP_INSERTSTATUSCD then
        if !find_user.blank?
          @errors[lineno] = I18n.t('registerUsrList1.PRI_REG_RESULTLIST_ACCOUNTDUPLICATIONERROR')+"("+line["account"]+")"
          next
        end
      when BUS_SER_IMP_IMP_UPDATESTATUSCD,
           BUS_SER_IMP_IMP_NAMENOPREFIXUPDATESTATUSCD,
           BUS_SER_IMP_IMP_LOGICALDELETESTATUSCD,
           BUS_SER_IMP_IMP_DELETESTATUSCD then
        if find_user.blank?
          @errors[lineno] = I18n.t('registerUsrList1.PRI_REG_RESULTLIST_ACCOUNTNOTFOUNDERROR')
          next
        end
      end

      accounts << line["account"]
    end

    users
  end

  def import_users
    User.transaction do
      begin
        @users.each do |user|
          # ステータスコードによって処理を分岐
          case user["status_cd"]
            when BUS_SER_IMP_IMP_INSERTSTATUSCD then
              find_user = User.new(set_user_params(user))
              find_user.save
            when BUS_SER_IMP_IMP_UPDATESTATUSCD,
                 BUS_SER_IMP_IMP_NAMENOPREFIXUPDATESTATUSCD,
                 BUS_SER_IMP_IMP_LOGICALDELETESTATUSCD then
              user[:update_user_id] = User.current_user.id
              find_user = User.find_by(:account => user["account"])
              find_user.update(set_user_params(user))
            when BUS_SER_IMP_IMP_DELETESTATUSCD then
              find_user = User.find_by(:account => user["account"])
              find_user.destroy
          end
        end
      rescue => e
        logger.error e.backtrace.join("\n")
        raise ActiveRecord::Rollback
        @messages = e.message
      end
    end
  end

  def set_user_params(user)
    params = {}

    params[:account] = user["account"]
    params[:password] = user["passwd"]
    params[:name_no_prefix] = user["name_no_prefix"]
    params[:user_name] = user["usr_name"]
    params[:kana_name] = user["kana_name"]
    params[:display_name] = user["usr_name"]
    params[:role_id] = user["auth_cd"]
    params[:sex_cd] = user["sex_cd"]
    params[:birth_date] = user["birth_date"]
    params[:email] = user["mail"].blank? ? "" : user["mail"]
    params[:move_cd] = user["move_cd"]
    params[:move_date] = user["move_date"]
    params[:effective_date] = user["efective_date"]

    # ステータスコードによって処理を分岐
    case user["status_cd"]
    when BUS_SER_IMP_IMP_INSERTSTATUSCD then
      params[:term_flag] = Settings.USR_TERMFLG_EFFECTIVE
      params[:insert_user_id] = User.current_user.id
    when BUS_SER_IMP_IMP_UPDATESTATUSCD,
         BUS_SER_IMP_IMP_NAMENOPREFIXUPDATESTATUSCD then
      params[:update_user_id] = User.current_user.id
    when BUS_SER_IMP_IMP_LOGICALDELETESTATUSCD then
      params[:update_user_id] = User.current_user.id
    end

    params
  end


  #
  # 科目リストアップロード
  #
  def course
  end

  def course_sample_file
    sample_file(CsvCourse::CSV_FILE_TYPE)
  end

  def course_confirm
    begin
      @csv = CsvCourse.new(csv_params)

      if @csv.valid?
        if @csv.not_overwrite && !Dir["#{@csv.temp_file}"].empty?
          @messages = I18n.t('registerList.PRI_REG_RESULTLIST_NOTOVERWRITEERROR')
          render :course_result
        else
          FileUtils.mkdir_p(@csv.tmp_dir)
          File.open(@csv.temp_file, 'w+b') do |fp|
            fp.write @csv.file.read
          end
          session[:csv_course] = @csv.temp_file
        end
      else
        @messages = I18n.t('registerList.PRI_REG_RESULTLIST_NOSELECTERROR')
        render :course_result
      end
    rescue => e
      logger.error e.backtrace.join("\n")
      @messages = I18n.t('registerList.PRI_REG_RESULTLIST_NOSELECTERROR')
      render :user_result
    end
  end

  def course_import_file
    begin
      upload_file = "#{session[:csv_course]}"

      @courses = course_csv_to_hash(upload_file)
      @error_code = 0

      # 読込行数を超えているかチェック
      raise I18n.t("registerList.PRI_REG_IMPORTRESUL_LIMITOVERERROR_html") if @courses.count > CsvCourse::BUS_UTI_CSV_LIMITCOUNT

      if @errors.count == 0
        import_courses

        @error_code = 1
        @messages = I18n.t('registerList.PRI_REG_IMPORTRESUL_SUCCESS_html')
      else
        @error_code = 2
        @messages = I18n.t('registerList.PRI_REG_IMPORTRESUL_ERROR_html')
      end
    rescue => e
      logger.error e.backtrace.join("\n")
      @messages = e.message
    end
  end

  def course_error_list
    upload_file = "#{session[:csv_course]}"
    @courses = course_csv_to_hash(upload_file)
    render :error_list
  end

  def course_destroy_file
    csv_course = CsvCourse.new
    FileUtils.rm(Dir.glob("#{csv_course.tmp_dir}*.*"))
    @messages = I18n.t('registerList.PRI_REG_RESULTLIST_DELETE')
    render :course_result
  end

  def course_csv_to_hash(upload_file)
    lineno = 0
    courses = []
    course_keys = []
    @errors = {}

    csv_data = CSV.parse(File.new(upload_file)) do |csv_row|
      line = {}
      line["identification_cd"] = csv_row[0]
      line["status_cd"] = csv_row[1]
      line["course_cd_key"] = csv_row[2]
      line["course_name_key"] = csv_row[3]
      line["school_year_key"] = csv_row[4]
      line["season_cd_key"] = csv_row[5]
      line["major_key"] = csv_row[6]
      line["instructor_name_key"] = csv_row[7]
      line["day_cd_key"] = csv_row[8]
      line["hour_cd_key"] = csv_row[9]
      line["effective_date_key"] = csv_row[10]
      line["season_cd_key1"] = csv_row[11]
      line["day_cd_key1"] = csv_row[12]
      line["hour_cd_key1"] = csv_row[13]
      line["season_cd_key2"] = csv_row[14]
      line["day_cd_key2"] = csv_row[15]
      line["hour_cd_key2"] = csv_row[16]
      line["season_cd_key3"] = csv_row[17]
      line["day_cd_key3"] = csv_row[18]
      line["hour_cd_key3"] = csv_row[19]
      line["season_cd_key4"] = csv_row[20]
      line["day_cd_key4"] = csv_row[21]
      line["hour_cd_key4"] = csv_row[22]
      courses << line
      lineno += 1

      if course_keys.include?(line["course_cd_key"] + line["school_year_key"] + line["season_cd_key"])
        @errors[lineno] = I18n.t('registerList.PRI_REG_RESULTLIST_DUPLICATIONINFILEERROR')
        next
      end

      # 入力項目のバリデーション
      # ファイル内に同じキー項目を持つものがある場合
      find_course = Course.find_by(:course_cd => line["course_cd_key"],
                                   :school_year => line["school_year_key"],
                                   :season_cd => line["season_cd_key"])

      # キー項目のバリデーション
      # 項目数が正しくない場合
      if line.count != CsvCourse::BUS_UTI_CSV_COLUMNCOUNT
        @errors[lineno] = I18n.t('registerList.PRI_REG_RESULTLIST_COLUMNCOUNTERROR')
        next
      end

      # 識別子コードが入力されていない場合
      if line["identification_cd"].blank?
        @errors[lineno] = I18n.t('registerList.PRI_REG_RESULTLIST_IDENTIFICATIONCDNULLERROR')
        next
      end

      # 識別子コードが正しくない場合
      if line["identification_cd"] != CsvCourse::BUS_SER_IMP_IMP_IDENTIFICATIONCD
        @errors[lineno] = I18n.t('registerList.PRI_REG_RESULTLIST_IDENTIFICATIONCDERROR')
        next
      end

      # ステータスコードが入力されていない場合
      if line["status_cd"].blank?
        @errors[lineno] = I18n.t('registerList.PRI_REG_RESULTLIST_STATUSCDNULLERROR')
        next
      end

      # 科目コードのバリデーション
      # 科目コードが入力されていない場合
      if line["course_cd_key"].blank?
        @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_COURSECDNULLERROR')
        next
      end

      # 科目コードが設定文字数より多い場合
      if line["course_cd_key"].length > CsvCourse::BUS_SER_IMP_IMP_COURSECDMAXLENGTH
        @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_COURSECDLONGERROR')
        next
      end

      # 科目コードに指定文字以外が含まれている場合
      if CsvCourse::BUS_SER_IMP_IMP_COURSECDFORMAT.match(line["course_cd_key"])
        @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_COURSECDFORMATERROR')
        next
      end

      # 年度のバリデーション
      # 年度が入力されていない場合
      if line["school_year_key"].blank?
        @errors[lineno] = I18n.t('registerCourseList1.BUS_SER_IMP_IMP_SCHOOLYEARNULLERROR')
        next
      end

      # 年度が数字4桁以外の場合
      if line["school_year_key"] !~ CsvCourse::BUS_SER_IMP_IMP_SCHOOLYEARFORMAT
        @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_SCHOOLYEARFORMATERROR')
        next
      end

      # 学期のバリデーション
      # 学期が入力されていない場合
      if line["season_cd_key"].blank?
        line["season_cd_key"] = Settings.COURSE_SEASONCD_INDEFINITE
      end

      # 学期が指定以外の場合
      if !(line["season_cd_key"] == Settings.COURSE_SEASONCD_INDEFINITE.to_s ||
           line["season_cd_key"] == Settings.COURSE_SEASONCD_SPRING.to_s ||
           line["season_cd_key"] == Settings.COURSE_SEASONCD_SUMMER.to_s ||
           line["season_cd_key"] == Settings.COURSE_SEASONCD_AUTUMN.to_s ||
           line["season_cd_key"] == Settings.COURSE_SEASONCD_WINTER.to_s ||
           line["season_cd_key"] == Settings.COURSE_SEASONCD_FIRSTTERM.to_s ||
           line["season_cd_key"] == Settings.COURSE_SEASONCD_LASTTERM.to_s ||
           line["season_cd_key"] == Settings.COURSE_SEASONCD_CONCENTRATION.to_s ||
           line["season_cd_key"] == Settings.COURSE_SEASONCD_OVERYEAR.to_s ||
           line["season_cd_key"] == Settings.COURSE_SEASONCD_OTHER.to_s)
        @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_SEASONCDERROR')
        next
      end

      # 学期1が入力されている場合チェック
      if !line["season_cd_key1"].blank?
        # 学期1が指定以外の場合
        if !(line["season_cd_key1"] == Settings.COURSE_SEASONCD_INDEFINITE.to_s ||
             line["season_cd_key1"] == Settings.COURSE_SEASONCD_SPRING.to_s ||
             line["season_cd_key1"] == Settings.COURSE_SEASONCD_SUMMER.to_s ||
             line["season_cd_key1"] == Settings.COURSE_SEASONCD_AUTUMN.to_s ||
             line["season_cd_key1"] == Settings.COURSE_SEASONCD_WINTER.to_s ||
             line["season_cd_key1"] == Settings.COURSE_SEASONCD_FIRSTTERM.to_s ||
             line["season_cd_key1"] == Settings.COURSE_SEASONCD_LASTTERM.to_s ||
             line["season_cd_key1"] == Settings.COURSE_SEASONCD_CONCENTRATION.to_s ||
             line["season_cd_key1"] == Settings.COURSE_SEASONCD_OTHER.to_s)
          @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_SEASONCDERROR')
          next
        end
      end

      # 学期2が入力されている場合チェック
      if !line["season_cd_key2"].blank?
        # 学期2が指定以外の場合
        if !(line["season_cd_key2"] == Settings.COURSE_SEASONCD_INDEFINITE.to_s ||
             line["season_cd_key2"] == Settings.COURSE_SEASONCD_SPRING.to_s ||
             line["season_cd_key2"] == Settings.COURSE_SEASONCD_SUMMER.to_s ||
             line["season_cd_key2"] == Settings.COURSE_SEASONCD_AUTUMN.to_s ||
             line["season_cd_key2"] == Settings.COURSE_SEASONCD_WINTER.to_s ||
             line["season_cd_key2"] == Settings.COURSE_SEASONCD_FIRSTTERM.to_s ||
             line["season_cd_key2"] == Settings.COURSE_SEASONCD_LASTTERM.to_s ||
             line["season_cd_key2"] == Settings.COURSE_SEASONCD_CONCENTRATION.to_s ||
             line["season_cd_key2"] == Settings.COURSE_SEASONCD_OTHER.to_s)
          @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_SEASONCDERROR')
          next
        end
      end

      # 学期3が入力されている場合チェック
      if !line["season_cd_key3"].blank?
        # 学期3が指定以外の場合
        if !(line["season_cd_key3"] == Settings.COURSE_SEASONCD_INDEFINITE.to_s ||
             line["season_cd_key3"] == Settings.COURSE_SEASONCD_SPRING.to_s ||
             line["season_cd_key3"] == Settings.COURSE_SEASONCD_SUMMER.to_s ||
             line["season_cd_key3"] == Settings.COURSE_SEASONCD_AUTUMN.to_s ||
             line["season_cd_key3"] == Settings.COURSE_SEASONCD_WINTER.to_s ||
             line["season_cd_key3"] == Settings.COURSE_SEASONCD_FIRSTTERM.to_s ||
             line["season_cd_key3"] == Settings.COURSE_SEASONCD_LASTTERM.to_s ||
             line["season_cd_key3"] == Settings.COURSE_SEASONCD_CONCENTRATION.to_s ||
             line["season_cd_key3"] == Settings.COURSE_SEASONCD_OTHER.to_s)
          @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_SEASONCDERROR')
          next
        end
      end

      # 学期4が入力されている場合チェック
      if !line["season_cd_key4"].blank?
        # 学期4が指定以外の場合
        if !(line["season_cd_key4"] == Settings.COURSE_SEASONCD_INDEFINITE.to_s ||
             line["season_cd_key4"] == Settings.COURSE_SEASONCD_SPRING.to_s ||
             line["season_cd_key4"] == Settings.COURSE_SEASONCD_SUMMER.to_s ||
             line["season_cd_key4"] == Settings.COURSE_SEASONCD_AUTUMN.to_s ||
             line["season_cd_key4"] == Settings.COURSE_SEASONCD_WINTER.to_s ||
             line["season_cd_key4"] == Settings.COURSE_SEASONCD_FIRSTTERM.to_s ||
             line["season_cd_key4"] == Settings.COURSE_SEASONCD_LASTTERM.to_s ||
             line["season_cd_key4"] == Settings.COURSE_SEASONCD_CONCENTRATION.to_s ||
             line["season_cd_key4"] == Settings.COURSE_SEASONCD_OTHER.to_s)
          @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_SEASONCDERROR')
          next
        end
      end

      case line["status_cd"]
      when BUS_SER_IMP_IMP_INSERTSTATUSCD
        # 科目名のバリデーション
        # 科目名が入力されていない場合
        if line["course_name_key"].blank?
          @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_COURSENAMENULLERROR')
          next
        end

        # 科目名が指定文字数より多い場合
        if line["course_name_key"] && line["course_name_key"].length > CsvCourse::BUS_SER_IMP_IMP_COURSENAMEMAXLENGTH
          @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_COURSENAMELONGERROR')
          next
        end

        # 学科のバリデーション
        # 学科が指定文字数より多い場合
        if line["major_key"] && line["major_key"].length > CsvCourse::BUS_SER_IMP_IMP_MAJORMAXLENGTH
          @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_MAJORLONGERROR')
          next
        end

        # 担任者名のバリデーション
        # 担任者名が指定文字数より多い場合
        if line["instructor_name_key"] && line["instructor_name_key"].length > CsvCourse::BUS_SER_IMP_IMP_INSTRUCTORNAMEMAXLENGTH
          @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_INSTRUCTORNAMELONGERROR')
          next
        end

        # 曜日のバリデーション
        # 曜日が指定以外の場合
        if !(line["day_cd_key"].blank? ||
             line["day_cd_key"] == Settings.COURSE_DAYCD_INDEFINITE.to_s ||
             line["day_cd_key"] == Settings.COURSE_DAYCD_SUN.to_s ||
             line["day_cd_key"] == Settings.COURSE_DAYCD_MON.to_s ||
             line["day_cd_key"] == Settings.COURSE_DAYCD_TUE.to_s ||
             line["day_cd_key"] == Settings.COURSE_DAYCD_WED.to_s ||
             line["day_cd_key"] == Settings.COURSE_DAYCD_THU.to_s ||
             line["day_cd_key"] == Settings.COURSE_DAYCD_FRI.to_s ||
             line["day_cd_key"] == Settings.COURSE_DAYCD_SAT.to_s)
          @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_DAYCDERROR')
          next
        end

        # 時限のバリデーション
        # 時限が指定以外の場合
        if !(line["hour_cd_key"].blank? ||
             line["hour_cd_key"] == Settings.COURSE_HOURCD_INDEFINITE.to_s ||
             line["hour_cd_key"] == Settings.COURSE_HOURCD_FIRST.to_s ||
             line["hour_cd_key"] == Settings.COURSE_HOURCD_SECOND.to_s ||
             line["hour_cd_key"] == Settings.COURSE_HOURCD_THIRD.to_s ||
             line["hour_cd_key"] == Settings.COURSE_HOURCD_FOURTH.to_s ||
             line["hour_cd_key"] == Settings.COURSE_HOURCD_FIFTH.to_s ||
             line["hour_cd_key"] == Settings.COURSE_HOURCD_SIXTH.to_s ||
             line["hour_cd_key"] == Settings.COURSE_HOURCD_SEVENTH.to_s ||
             line["hour_cd_key"] == Settings.COURSE_HOURCD_EIGHTH.to_s)
          @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_HOURCDERROR')
          next
        end

        # 有効日のバリデーション
        if !line["effective_date_key"].blank?
          if !Date.valid_date?(line["effective_date_key"][0, 4].to_i,
                               line["effective_date_key"][4, 2].to_i,
                               line["effective_date_key"][6, 2].to_i)
            @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_EFFECTIVEDATEFORMATERROR')
            next
          end
        end

        # 曜日1のバリデーション
        if !(line["day_cd_key1"].blank? ||
             line["day_cd_key1"] == Settings.COURSE_DAYCD_INDEFINITE.to_s ||
             line["day_cd_key1"] == Settings.COURSE_DAYCD_SUN.to_s ||
             line["day_cd_key1"] == Settings.COURSE_DAYCD_MON.to_s ||
             line["day_cd_key1"] == Settings.COURSE_DAYCD_TUE.to_s ||
             line["day_cd_key1"] == Settings.COURSE_DAYCD_WED.to_s ||
             line["day_cd_key1"] == Settings.COURSE_DAYCD_THU.to_s ||
             line["day_cd_key1"] == Settings.COURSE_DAYCD_FRI.to_s ||
             line["day_cd_key1"] == Settings.COURSE_DAYCD_SAT.to_s)
          @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_DAYCDERROR')
          next
        end

        # 曜日2のバリデーション
        if !(line["day_cd_key2"].blank? ||
             line["day_cd_key2"] == Settings.COURSE_DAYCD_INDEFINITE.to_s ||
             line["day_cd_key2"] == Settings.COURSE_DAYCD_SUN.to_s ||
             line["day_cd_key2"] == Settings.COURSE_DAYCD_MON.to_s ||
             line["day_cd_key2"] == Settings.COURSE_DAYCD_TUE.to_s ||
             line["day_cd_key2"] == Settings.COURSE_DAYCD_WED.to_s ||
             line["day_cd_key2"] == Settings.COURSE_DAYCD_THU.to_s ||
             line["day_cd_key2"] == Settings.COURSE_DAYCD_FRI.to_s ||
             line["day_cd_key2"] == Settings.COURSE_DAYCD_SAT.to_s)
          @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_DAYCDERROR')
          next
        end

        # 曜日3のバリデーション
        if !(line["day_cd_key3"].blank? ||
             line["day_cd_key3"] == Settings.COURSE_DAYCD_INDEFINITE.to_s ||
             line["day_cd_key3"] == Settings.COURSE_DAYCD_SUN.to_s ||
             line["day_cd_key3"] == Settings.COURSE_DAYCD_MON.to_s ||
             line["day_cd_key3"] == Settings.COURSE_DAYCD_TUE.to_s ||
             line["day_cd_key3"] == Settings.COURSE_DAYCD_WED.to_s ||
             line["day_cd_key3"] == Settings.COURSE_DAYCD_THU.to_s ||
             line["day_cd_key3"] == Settings.COURSE_DAYCD_FRI.to_s ||
             line["day_cd_key3"] == Settings.COURSE_DAYCD_SAT.to_s)
          @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_DAYCDERROR')
          next
        end

        # 曜日4のバリデーション
        if !(line["day_cd_key4"].blank? ||
             line["day_cd_key4"] == Settings.COURSE_DAYCD_INDEFINITE.to_s ||
             line["day_cd_key4"] == Settings.COURSE_DAYCD_SUN.to_s ||
             line["day_cd_key4"] == Settings.COURSE_DAYCD_MON.to_s ||
             line["day_cd_key4"] == Settings.COURSE_DAYCD_TUE.to_s ||
             line["day_cd_key4"] == Settings.COURSE_DAYCD_WED.to_s ||
             line["day_cd_key4"] == Settings.COURSE_DAYCD_THU.to_s ||
             line["day_cd_key4"] == Settings.COURSE_DAYCD_FRI.to_s ||
             line["day_cd_key4"] == Settings.COURSE_DAYCD_SAT.to_s)
          @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_DAYCDERROR')
          next
        end

        # 時限1のバリデーション
        if !(line["hour_cd_key1"].blank? ||
             line["hour_cd_key1"] == Settings.COURSE_HOURCD_INDEFINITE.to_s ||
             line["hour_cd_key1"] == Settings.COURSE_HOURCD_FIRST.to_s ||
             line["hour_cd_key1"] == Settings.COURSE_HOURCD_SECOND.to_s ||
             line["hour_cd_key1"] == Settings.COURSE_HOURCD_THIRD.to_s ||
             line["hour_cd_key1"] == Settings.COURSE_HOURCD_FOURTH.to_s ||
             line["hour_cd_key1"] == Settings.COURSE_HOURCD_FIFTH.to_s ||
             line["hour_cd_key1"] == Settings.COURSE_HOURCD_SIXTH.to_s ||
             line["hour_cd_key1"] == Settings.COURSE_HOURCD_SEVENTH.to_s ||
             line["hour_cd_key1"] == Settings.COURSE_HOURCD_EIGHTH.to_s)
          @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_HOURCDERROR')
          next
        end

        # 時限2のバリデーション
        if !(line["hour_cd_key2"].blank? ||
             line["hour_cd_key2"] == Settings.COURSE_HOURCD_INDEFINITE.to_s ||
             line["hour_cd_key2"] == Settings.COURSE_HOURCD_FIRST.to_s ||
             line["hour_cd_key2"] == Settings.COURSE_HOURCD_SECOND.to_s ||
             line["hour_cd_key2"] == Settings.COURSE_HOURCD_THIRD.to_s ||
             line["hour_cd_key2"] == Settings.COURSE_HOURCD_FOURTH.to_s ||
             line["hour_cd_key2"] == Settings.COURSE_HOURCD_FIFTH.to_s ||
             line["hour_cd_key2"] == Settings.COURSE_HOURCD_SIXTH.to_s ||
             line["hour_cd_key2"] == Settings.COURSE_HOURCD_SEVENTH.to_s ||
             line["hour_cd_key2"] == Settings.COURSE_HOURCD_EIGHTH.to_s)
          @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_HOURCDERROR')
          next
        end

        # 時限3のバリデーション
        if !(line["hour_cd_key3"].blank? ||
             line["hour_cd_key3"] == Settings.COURSE_HOURCD_INDEFINITE.to_s ||
             line["hour_cd_key3"] == Settings.COURSE_HOURCD_FIRST.to_s ||
             line["hour_cd_key3"] == Settings.COURSE_HOURCD_SECOND.to_s ||
             line["hour_cd_key3"] == Settings.COURSE_HOURCD_THIRD.to_s ||
             line["hour_cd_key3"] == Settings.COURSE_HOURCD_FOURTH.to_s ||
             line["hour_cd_key3"] == Settings.COURSE_HOURCD_FIFTH.to_s ||
             line["hour_cd_key3"] == Settings.COURSE_HOURCD_SIXTH.to_s ||
             line["hour_cd_key3"] == Settings.COURSE_HOURCD_SEVENTH.to_s ||
             line["hour_cd_key3"] == Settings.COURSE_HOURCD_EIGHTH.to_s)
          @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_HOURCDERROR')
          next
        end

        # 時限4のバリデーション
        if !(line["hour_cd_key4"].blank? ||
             line["hour_cd_key4"] == Settings.COURSE_HOURCD_INDEFINITE.to_s ||
             line["hour_cd_key4"] == Settings.COURSE_HOURCD_FIRST.to_s ||
             line["hour_cd_key4"] == Settings.COURSE_HOURCD_SECOND.to_s ||
             line["hour_cd_key4"] == Settings.COURSE_HOURCD_THIRD.to_s ||
             line["hour_cd_key4"] == Settings.COURSE_HOURCD_FOURTH.to_s ||
             line["hour_cd_key4"] == Settings.COURSE_HOURCD_FIFTH.to_s ||
             line["hour_cd_key4"] == Settings.COURSE_HOURCD_SIXTH.to_s ||
             line["hour_cd_key4"] == Settings.COURSE_HOURCD_SEVENTH.to_s ||
             line["hour_cd_key4"] == Settings.COURSE_HOURCD_EIGHTH.to_s)
          @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_HOURCDERROR')
          next
        end
      end

      # ステータスコードによって処理を分岐
      case line["status_cd"]
      when BUS_SER_IMP_IMP_INSERTSTATUSCD then
        if !find_course.blank?
          @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_COURSEDUPLICATIONERROR')+":"+
                            line["school_year_key"]+","+line["course_cd_key"]+":"+line["season_cd_key"]
          next
        end
      when BUS_SER_IMP_IMP_UPDATESTATUSCD,
           BUS_SER_IMP_IMP_LOGICALDELETESTATUSCD,
           BUS_SER_IMP_IMP_DELETESTATUSCD then
        if find_course.blank?
          @errors[lineno] = I18n.t('registerCourseList1.PRI_REG_RESULTLIST_COURSENOTFOUNDERROR')
          next
        end
      end

      course_keys << line["course_cd_key"] + line["school_year_key"] + line["season_cd_key"]
    end

    courses
  end

  def import_courses
    Course.transaction do
      begin
        @courses.each do |course|
          # ステータスコードによって処理を分岐
          case course["status_cd"]
          when BUS_SER_IMP_IMP_INSERTSTATUSCD then
            find_course = Course.new(set_course_params(course))
            find_course.save
            create_class_sessions(find_course)
          when BUS_SER_IMP_IMP_UPDATESTATUSCD,
               BUS_SER_IMP_IMP_LOGICALDELETESTATUSCD then
            find_course = Course.find_by(:course_cd => course["course_cd_key"],
                                         :school_year => course["school_year_key"],
                                         :season_cd => course["season_cd_key"])
            find_course.update(set_course_params(course))
            create_class_sessions(find_course)
          when BUS_SER_IMP_IMP_DELETESTATUSCD then
            find_course = Course.find_by(:course_cd => course["course_cd_key"],
                                         :school_year => course["school_year_key"],
                                         :season_cd => course["season_cd_key"])
            find_course.destroy
          end
        end
      rescue => e
        logger.error e.backtrace.join("\n")
        raise ActiveRecord::Rollback
        @messages = e.message
      end
    end
  end

  def set_course_params(course)
    params = {}

    # 科目情報を設定
    params[:course_cd] = course["course_cd_key"]
    params[:course_name] = course["course_name_key"]
    params[:school_year] = course["school_year_key"]
    params[:season_cd] = course["season_cd_key"]
    params[:major] = course["major_key"]
    params[:instructor_name] = course["instructor_name_key"]
    if course["day_cd_key"].blank?
      if course["day_cd_key1"].blank?
        params[:day_cd] = course["day_cd_key"]
      else
        params[:day_cd] = course["day_cd_key1"]
      end
    else
      params[:day_cd] = course["day_cd_key"]
    end
    if course["hour_cd_key"].blank?
      if course["hour_cd_key1"].blank?
        params[:hour_cd] = course["hour_cd_key"]
        else
        params[:hour_cd] = course["hour_cd_key1"]
      end
    else
      params[:hour_cd] = course["hour_cd_key"]
    end
    params[:effective_date] = course["effective_date_key"]
    params[:indirect_use_flag] = false
    params[:term_flag] = true
    params[:class_session_count] = 15
    params[:open_course_flag] = false
    params[:bbs_cd] = 1
    params[:chat_cd] = 1
    params[:announcement_cd] = 1
    params[:faq_cd] = 1
    params[:open_course_bbs_flag] = false
    params[:open_course_chat_flag] = false
    params[:open_course_announcement_flag] = false
    params[:open_course_faq_flag] = false
    # 学習コースウェアフラグ追加
    params[:courseware_flag] = false
    if course["day_cd_key1"].blank? &&
       course["hour_cd_key1"].blank? &&
       course["season_cd_key1"].blank?
      params[:day_cd2] = course["day_cd_key1"]
      params[:hour_cd2] = course["hour_cd_key1"]
      params[:season_cd2] = course["season_cd_key1"]
    else
      params[:day_cd1] = course["day_cd_key1"]
      params[:hour_cd1] = course["hour_cd_key1"]
      params[:season_cd1] = course["season_cd_key1"]
    end
    params[:day_cd2] = course["day_cd_key2"]
    params[:hour_cd2] = course["hour_cd_key2"]
    params[:season_cd2] = course["season_cd_key2"]

    params[:day_cd3] = course["day_cd_key3"]
    params[:hour_cd3] = course["hour_cd_key3"]
    params[:season_cd3] = course["season_cd_key3"]

    params[:day_cd4] = course["day_cd_key4"]
    params[:hour_cd4] = course["hour_cd_key4"]
    params[:season_cd4] = course["season_cd_key4"]

    # ステータスコードによって処理を分岐
    case course["status_cd"]
    when BUS_SER_IMP_IMP_INSERTSTATUSCD then
      params[:term_flag] = Settings.USR_TERMFLG_EFFECTIVE
      params[:insert_user_id] = User.current_user.id
    when BUS_SER_IMP_IMP_UPDATESTATUSCD then
      params[:update_user_id] = User.current_user.id
    when BUS_SER_IMP_IMP_LOGICALDELETESTATUSCD then
      params[:update_user_id] = User.current_user.id
    when BUS_SER_IMP_IMP_DELETESTATUSCD then
    end
    params[:overview] = ""

    return params
  end

  def create_class_sessions(course)
    for class_session_count in 0..course.class_session_count
      unless course.class_session(class_session_count)
        class_session = ClassSession.new
        class_session.course_id = course.id
        class_session.class_session_no = class_session_count
        if class_session_count == 0
          class_session.class_session_day = I18n.t("select_class_session.MAT_ALL_SELECTCLASSSESSION_CLASSSESSIONOVERVIEWTEXT1")
        else
          class_session.class_session_day = "#{I18n.t("common.COMMON_NO2")}#{class_session_count}#{I18n.t("common.COMMON_COUNT2")}"
        end
        class_session.save!
      end
    end
  end



  #
  # 科目担任関連リストアップロード
  #
  def course_assign
  end

  def course_assign_sample_file
    sample_file(CsvCourseAssigned::CSV_FILE_TYPE)
  end

  def course_assign_confirm
    begin
      @csv = CsvCourseAssigned.new(csv_params)

      if @csv.valid?
        if @csv.not_overwrite && !Dir["#{@csv.temp_file}"].empty?
          @messages = I18n.t('registerList.PRI_REG_RESULTLIST_NOTOVERWRITEERROR')
          render :course_assign_result
        else
          FileUtils.mkdir_p(@csv.tmp_dir)
          File.open(@csv.temp_file, 'w+b') do |fp|
            fp.write @csv.file.read
          end
          session[:course_assign_file] = @csv.temp_file
        end
      else
        @messages = I18n.t('registerList.PRI_REG_RESULTLIST_NOSELECTERROR')
        render :course_assign_result
      end
    rescue => e
      logger.error e.backtrace.join("\n")
      @messages = I18n.t('registerList.PRI_REG_RESULTLIST_NOSELECTERROR')
      render :course_assign_result
    end
  end

  def course_assign_import_file
    begin
      upload_file = "#{session[:course_assign_file]}"

      @course_assigns = course_assigned_csv_to_hash(upload_file)
      @error_code = 0

      # 読込行数を超えているかチェック
      raise I18n.t("registerList.PRI_REG_IMPORTRESUL_LIMITOVERERROR_html") if @course_assigns.count > CsvCourseAssigned::BUS_UTI_CSV_LIMITCOUNT

      if @errors.count == 0
        import_course_assigns

        @error_code = 1
        @messages = I18n.t('registerList.PRI_REG_IMPORTRESUL_SUCCESS_html')
      else
        @error_code = 2
        @messages = I18n.t('registerList.PRI_REG_IMPORTRESUL_ERROR_html')
      end
    rescue => e
      logger.error e.backtrace.join("\n")
      @messages = e.message
    end
  end

  def course_assign_error_list
    upload_file = "#{session[:course_assign_file]}"
    @course_assigns = course_assigned_csv_to_hash(upload_file)
    render :error_list
  end

  def course_assign_destroy_file
    csv_course_assigned = CsvCourseAssigned.new
    FileUtils.rm(Dir.glob("#{csv_course_assigned.tmp_dir}*.*"))
    @messages = I18n.t('registerList.PRI_REG_RESULTLIST_DELETE')
    render :course_assign_result
  end

  def course_assigned_csv_to_hash(upload_file)
    lineno = 0
    course_assigns = []
    course_assigned_users = []
    @errors = {}

    csv_data = CSV.parse(File.new(upload_file)) do |csv_row|
      line = {}
      line["identification_cd"] = csv_row[0]
      line["status_cd"] = csv_row[1]
      line["account"] = csv_row[2]
      line["course_cd"] = csv_row[3]
      line["school_year"] = csv_row[4]
      line["season_cd"] = csv_row[5]
      line["effective_date"] = csv_row[6]
      course_assigns << line
      lineno += 1

      if course_assigned_users.include?(line["account"] + line["course_cd"] + line["school_year"] + line["season_cd"])
        @errors[lineno] = I18n.t('registerList.PRI_REG_RESULTLIST_DUPLICATIONINFILEERROR')
        next
      end

      # 入力項目のバリデーション
      # ファイル内に同じキー項目を持つものがある場合
      find_user = User.find_by(:account => line["account"])
      find_course = Course.find_by(:course_cd => line["course_cd"], :school_year => line["school_year"], :season_cd => line["season_cd"])
      if find_user && find_course
        find_course_assigned_user = CourseAssignedUser.find_by(:user_id => find_user.id, :course_id => find_course.id)
      end

      # キー項目のバリデーション
      # 項目数が正しくない場合
      if line.count != CsvCourseAssigned::BUS_UTI_CSV_COLUMNCOUNT
        @errors[lineno] = I18n.t('registerList.PRI_REG_RESULTLIST_COLUMNCOUNTERROR')
        next
      end

      # 識別子コードが入力されていない場合
      if line["identification_cd"].blank?
        @errors[lineno] = I18n.t('registerList.PRI_REG_RESULTLIST_IDENTIFICATIONCDNULLERROR')
        next
      end

      # 識別子コードが正しくない場合
      if line["identification_cd"] != CsvCourseAssigned::BUS_SER_IMP_IMP_IDENTIFICATIONCD
        @errors[lineno] = I18n.t('registerList.PRI_REG_RESULTLIST_IDENTIFICATIONCDERROR')
        next
      end

      # ステータスコードが入力されていない場合
      if line["status_cd"].blank?
        @errors[lineno] = I18n.t('registerList.PRI_REG_RESULTLIST_STATUSCDNULLERROR')
        next
      end

      # アカウントのバリデーション
      # アカウントが入力されていない場合
      if line["account"].blank?
        @errors[lineno] = I18n.t('registerCourseAssignedList1.PRI_REG_RESULTLIST_ACCOUNTNULLERROR')
        next
      end

      # アカウントが設定文字数より多い
      if line["account"].length > CsvCourseAssigned::BUS_SER_IMP_IMP_ACCOUNTMAXLENGTH
        @errors[lineno] = I18n.t('registerCourseAssignedList1.PRI_REG_RESULTLIST_ACCOUNTLONGERROR')
        next
      end

      # アカウントに半角英数字・句読文字以外が含まれている場合
      if CsvCourseAssigned::BUS_SER_IMP_IMP_ACCOUNTFORMAT.match(line["account"])
        @errors[lineno] = I18n.t('registerCourseAssignedList1.PRI_REG_RESULTLIST_ACCOUNTFORMATERROR')
        next
      end

      # 科目コードのバリデーション
      # 科目コードが入力されていない場合
      if line["course_cd"].blank?
        @errors[lineno] = I18n.t('registerCourseAssignedList1.PRI_REG_RESULTLIST_COURSECDNULLERROR')
        next
      end

      # 科目コードが設定文字数より多い場合
      if line["course_cd"].length > CsvCourseAssigned::BUS_SER_IMP_IMP_COURSECDMAXLENGTH
        @errors[lineno] = I18n.t('registerCourseAssignedList1.PRI_REG_RESULTLIST_COURSECDLONGERROR')
        next
      end

      # 科目コードに指定文字以外が含まれている場合
      if CsvCourseAssigned::BUS_SER_IMP_IMP_COURSECDFORMAT.match(line["course_cd"])
        @errors[lineno] = I18n.t('registerCourseAssignedList1.PRI_REG_RESULTLIST_COURSECDFORMATERROR')
        next
      end

      # 年度のバリデーション
      if line["school_year"].blank?
        @errors[lineno] = I18n.t('registerCourseAssignedList1.PRI_REG_RESULTLIST_SCHOOLYEARNULLERROR')
        next
      end

      # 年度が数字4桁以外の場合
      if line["school_year"] !~ CsvCourseAssigned::BUS_SER_IMP_IMP_SCHOOLYEARFORMAT
        @errors[lineno] = I18n.t('registerCourseAssignedList1.PRI_REG_RESULTLIST_SCHOOLYEARFORMATERROR')
        next
      end

      # 学期のバリデーション
      if line["season_cd"].blank?
        @errors[lineno] = I18n.t('registerCourseAssignedList1.PRI_REG_RESULTLIST_SEASONCDNULLERROR')
        next
      end

      # 学期が指定以外の場合
      if !(line["season_cd"] == Settings.COURSE_SEASONCD_INDEFINITE.to_s ||
           line["season_cd"] == Settings.COURSE_SEASONCD_SPRING.to_s ||
           line["season_cd"] == Settings.COURSE_SEASONCD_SUMMER.to_s ||
           line["season_cd"] == Settings.COURSE_SEASONCD_AUTUMN.to_s ||
           line["season_cd"] == Settings.COURSE_SEASONCD_WINTER.to_s ||
           line["season_cd"] == Settings.COURSE_SEASONCD_FIRSTTERM.to_s ||
           line["season_cd"] == Settings.COURSE_SEASONCD_LASTTERM.to_s ||
           line["season_cd"] == Settings.COURSE_SEASONCD_CONCENTRATION.to_s ||
           line["season_cd"] == Settings.COURSE_SEASONCD_OVERYEAR.to_s ||
           line["season_cd"] == Settings.COURSE_SEASONCD_OTHER.to_s)
        @errors[lineno] = I18n.t('registerCourseAssignedList1.PRI_REG_RESULTLIST_SEASONCDERROR')
        next
      end

      case line["season_cd"]
      when BUS_SER_IMP_IMP_INSERTSTATUSCD
        # 有効日のバリデーション
        if !line["effective_date"].blank?
          if !Date.valid_date?(line["effective_date"][0, 4].to_i,
                               line["effective_date"][4, 2].to_i,
                               line["effective_date"][6, 2].to_i)
            @errors[lineno] = I18n.t('registerCourseAssignedList1.PRI_REG_RESULTLIST_EFFECTIVEDATEFORMATERROR')
            next
          end
        end
      end

      # ステータスコードによって処理を分岐
      case line["status_cd"]
      when BUS_SER_IMP_IMP_INSERTSTATUSCD then
        # 指定されたアカウントのユーザが登録されていない場合
        if find_user.blank?
          @errors[lineno] = I18n.t('registerCourseAssignedList1.PRI_REG_RESULTLIST_ACCOUNTNOTFOUNDERROR')+":"+line["account"]
          next
        end
        # 指定された科目が登録されていない場合
        if find_course.blank?
          @errors[lineno] = I18n.t('registerCourseAssignedList1.PRI_REG_RESULTLIST_COURSENOTFOUNDERROR')+":"+
                                   line["course_cd"]+","+line["school_year"]+","+line["season_cd"]
          next
        end
        # 指定された科目担任関連情報が既に登録されている場合
        if !find_course_assigned_user.blank?
          @errors[lineno] = I18n.t('registerCourseAssignedList1.PRI_REG_RESULTLIST_COURSEASSIGNEDNOTFOUNDERROR')+":"+
                                   line["account"]+","+line["course_cd"]+","+line["school_year"]+","+line["season_cd"]
          next
        end
      when BUS_SER_IMP_IMP_UPDATESTATUSCD,
           BUS_SER_IMP_IMP_LOGICALDELETESTATUSCD,
           BUS_SER_IMP_IMP_DELETESTATUSCD
        # 指定された科目担任関連情報が既に登録されていない場合
        if find_course_assigned_user.blank?
          @errors[lineno] = I18n.t('registerCourseAssignedList1.PRI_REG_RESULTLIST_COURSEASSIGNEDNOTFOUNDERROR')+":"+
                                   line["account"]+","+line["course_cd"]+","+line["school_year"]+","+line["season_cd"]
          next
        end
      end

      course_assigned_users << line["account"] + line["course_cd"] + line["school_year"] + line["season_cd"]
    end
    course_assigns
  end

  def import_course_assigns
    CourseAssignedUser.transaction do
      begin
        @course_assigns.each do |course_assign|
          find_user = User.find_by(:account => course_assign["account"])
          find_course = Course.find_by(:course_cd => course_assign["course_cd"], :school_year => course_assign["school_year"], :season_cd => course_assign["season_cd"])
          if find_user && find_course
            find_course_assigned_user = CourseAssignedUser.find_by(:user_id => find_user.id, :course_id => find_course.id)
          end

          # ステータスコードによって処理を分岐
          case course_assign["status_cd"]
          when BUS_SER_IMP_IMP_INSERTSTATUSCD then
            course_assigned_user = CourseAssignedUser.new(set_course_assigned_user_params(course_assign, find_user, find_course))
            course_assigned_user.save
          when BUS_SER_IMP_IMP_UPDATESTATUSCD,
               BUS_SER_IMP_IMP_LOGICALDELETESTATUSCD then
            find_course_assigned_user.update(set_course_assigned_user_params(course_assign, find_user, find_course))
          when BUS_SER_IMP_IMP_DELETESTATUSCD then
            find_course_assigned_user.destroy
          end
        end
      rescue => e
        logger.error e.backtrace.join("\n")
        raise ActiveRecord::Rollback
        @messages = e.message
      end
    end
  end

  def set_course_assigned_user_params(course_assign, find_user, find_course)
    params = {}

    # 科目情報を設定
    params[:course_id] = find_course.id
    params[:user_id] = find_user.id
    params[:effective_date] = course_assign["effective_date"]

    # ステータスコードによって処理を分岐
    case course_assign["status_cd"]
    when BUS_SER_IMP_IMP_INSERTSTATUSCD then
      params[:insert_user_id] = User.current_user.id
    when BUS_SER_IMP_IMP_UPDATESTATUSCD then
      params[:update_user_id] = User.current_user.id
    when BUS_SER_IMP_IMP_LOGICALDELETESTATUSCD then
      params[:update_user_id] = User.current_user.id
    when BUS_SER_IMP_IMP_DELETESTATUSCD then
    end

    return params
  end



  #
  # 履修情報リストアップロード
  #
  def course_enrollment
  end

  def course_enrollment_sample_file
    sample_file(CsvCourseEnrollment::CSV_FILE_TYPE)
  end

  def course_enrollment_confirm
    begin
      @csv = CsvCourseEnrollment.new(csv_params)

      if @csv.valid?
        if @csv.not_overwrite && !Dir["#{@csv.temp_file}"].empty?
          @messages = I18n.t('registerList.PRI_REG_RESULTLIST_NOTOVERWRITEERROR')
          render :course_enrollment_result
        else
          FileUtils.mkdir_p(@csv.tmp_dir)
          File.open(@csv.temp_file, 'w+b') do |fp|
            fp.write @csv.file.read
          end
          session[:course_enrollment_file] = @csv.temp_file
        end
      else
        @messages = I18n.t('registerList.PRI_REG_RESULTLIST_NOSELECTERROR')
        render :course_enrollment_result
      end
    rescue => e
      logger.error e.backtrace.join("\n")
      @messages = I18n.t('registerList.PRI_REG_RESULTLIST_NOSELECTERROR')
      render :course_enrollment_result
    end
  end

  def course_enrollment_import_file
    begin
      upload_file = "#{session[:course_enrollment_file]}"

      @course_enrollments = course_enrollment_csv_to_hash(upload_file)
      @error_code = 0

      # 読込行数を超えているかチェック
      raise I18n.t("registerList.PRI_REG_IMPORTRESUL_LIMITOVERERROR_html") if @course_enrollments.count > CsvCourseEnrollment::BUS_UTI_CSV_LIMITCOUNT

      if @errors.count == 0
        import_course_enrollments

        @error_code = 1
        @messages = I18n.t('registerList.PRI_REG_IMPORTRESUL_SUCCESS_html')
      else
        @error_code = 2
        @messages = I18n.t('registerList.PRI_REG_IMPORTRESUL_ERROR_html')
      end
    rescue => e
      logger.error e.backtrace.join("\n")
      @messages = e.message
    end
  end

  def course_enrollment_destroy_file
    csv_course_enrollment = CsvCourseEnrollment.new
    FileUtils.rm(Dir.glob("#{csv_course_enrollment.tmp_dir}*.*"))
    @messages = I18n.t('registerList.PRI_REG_RESULTLIST_DELETE')
    render :course_enrollment_result
  end

  def course_enrollment_error_list
    course_enrollment_import_file
    render :error_list
  end

  def course_enrollment_csv_to_hash(upload_file)
    lineno = 0
    course_enrollments = []
    course_enrollment_users = []
    @errors = {}

    csv_data = CSV.parse(File.new(upload_file)) do |csv_row|
      line = {}
      line["identification_cd"] = csv_row[0]
      line["status_cd"] = csv_row[1]
      line["account"] = csv_row[2]
      line["course_cd"] = csv_row[3]
      line["school_year"] = csv_row[4]
      line["season_cd"] = csv_row[5]
      line["effective_date"] = csv_row[6]
      course_enrollments << line
      lineno += 1

      if course_enrollment_users.include?(line["account"]+line["course_cd"]+line["school_year"]+line["season_cd"])
        @errors[lineno] = I18n.t('registerList.PRI_REG_RESULTLIST_DUPLICATIONINFILEERROR')
        next
      end

      # 入力項目のバリデーション
      # ファイル内に同じキー項目を持つものがある場合
      find_user = User.find_by(:account => line["account"])
      find_course = Course.find_by(:course_cd => line["course_cd"], :school_year => line["school_year"], :season_cd => line["season_cd"])
      if find_user && find_course
        find_course_enrollment_user = CourseEnrollmentUser.find_by(:user_id => find_user.id, :course_id => find_course.id)
      end

      # キー項目のバリデーション
      # 項目数が正しくない場合
      if line.count != CsvCourseEnrollment::BUS_UTI_CSV_COLUMNCOUNT
        @errors[lineno] = I18n.t('registerList.PRI_REG_RESULTLIST_COLUMNCOUNTERROR')
        next
      end

      # 識別子コードが入力されていない場合
      if line["identification_cd"].blank?
        @errors[lineno] = I18n.t('registerList.PRI_REG_RESULTLIST_IDENTIFICATIONCDNULLERROR')
        next
      end

      # 識別子コードが正しくない場合
      if line["identification_cd"] != CsvCourseEnrollment::BUS_SER_IMP_IMP_IDENTIFICATIONCD
        @errors[lineno] = I18n.t('registerList.PRI_REG_RESULTLIST_IDENTIFICATIONCDERROR')
        next
      end

      # ステータスコードが入力されていない場合
      if line["status_cd"].blank?
        @errors[lineno] = I18n.t('registerList.PRI_REG_RESULTLIST_STATUSCDNULLERROR')
        next
      end

      # アカウントのバリデーション
      # アカウントが入力されていない場合
      if line["account"].blank?
        @errors[lineno] = I18n.t('registerCourseEnrollmentList1.PRI_REG_RESULTLIST_ACCOUNTNULLERROR')
        next
      end

      # アカウントが設定文字数より多い
      if line["account"].length > CsvCourseEnrollment::BUS_SER_IMP_IMP_ACCOUNTMAXLENGTH
        @errors[lineno] = I18n.t('registerCourseEnrollmentList1.PRI_REG_RESULTLIST_ACCOUNTLONGERROR')
        next
      end

      # アカウントに半角英数字・句読文字以外が含まれている場合
      if CsvCourseEnrollment::BUS_SER_IMP_IMP_ACCOUNTFORMAT.match(line["account"])
        @errors[lineno] = I18n.t('registerCourseEnrollmentList1.PRI_REG_RESULTLIST_ACCOUNTFORMATERROR')
        next
      end

      # 科目コードのバリデーション
      # 科目コードが入力されていない場合
      if line["course_cd"].blank?
        @errors[lineno] = I18n.t('registerCourseEnrollmentList1.PRI_REG_RESULTLIST_COURSECDNULLERROR')
        next
      end

      # 科目コードが設定文字数より多い場合
      if line["course_cd"].length > CsvCourseEnrollment::BUS_SER_IMP_IMP_COURSECDMAXLENGTH
        @errors[lineno] = I18n.t('registerCourseEnrollmentList1.PRI_REG_RESULTLIST_COURSECDLONGERROR')
        next
      end

      # 科目コードに指定文字以外が含まれている場合
      if CsvCourseEnrollment::BUS_SER_IMP_IMP_COURSECDFORMAT.match(line["course_cd"])
        @errors[lineno] = I18n.t('registerCourseEnrollmentList1.PRI_REG_RESULTLIST_COURSECDFORMATERROR')
        next
      end

      # 年度のバリデーション
      # 年度が入力されていない場合
      if line["school_year"].blank?
        @errors[lineno] = I18n.t('registerCourseEnrollmentList1.PRI_REG_RESULTLIST_SCHOOLYEARNULLERROR')
        next
      end

      # 年度が数字4桁以外の場合
      if line["school_year"] !~ CsvCourseEnrollment::BUS_SER_IMP_IMP_SCHOOLYEARFORMAT
        @errors[lineno] = I18n.t('registerCourseEnrollmentList1.PRI_REG_RESULTLIST_SCHOOLYEARFORMATERROR')
        next
      end

      # 学期のバリデーション
      # 学期が入力されていない場合
      if line["season_cd"].blank?
        @errors[lineno] = I18n.t('registerCourseEnrollmentList1.PRI_REG_RESULTLIST_SEASONCDNULLERROR')
        next
      end

      # 学期が指定以外の場合
      if !(line["season_cd"] == Settings.COURSE_SEASONCD_INDEFINITE.to_s ||
           line["season_cd"] == Settings.COURSE_SEASONCD_SPRING.to_s ||
           line["season_cd"] == Settings.COURSE_SEASONCD_SUMMER.to_s ||
           line["season_cd"] == Settings.COURSE_SEASONCD_AUTUMN.to_s ||
           line["season_cd"] == Settings.COURSE_SEASONCD_WINTER.to_s ||
           line["season_cd"] == Settings.COURSE_SEASONCD_FIRSTTERM.to_s ||
           line["season_cd"] == Settings.COURSE_SEASONCD_LASTTERM.to_s ||
           line["season_cd"] == Settings.COURSE_SEASONCD_CONCENTRATION.to_s ||
           line["season_cd"] == Settings.COURSE_SEASONCD_OVERYEAR.to_s ||
           line["season_cd"] == Settings.COURSE_SEASONCD_OTHER.to_s)
        @errors[lineno] = I18n.t('registerCourseEnrollmentList1.PRI_REG_RESULTLIST_SEASONCDERROR')
        next
      end

      case line["status_cd"]
      when BUS_SER_IMP_IMP_INSERTSTATUSCD
        # 有効日のバリデーション
        if !line["effective_date"].blank?
          if !Date.valid_date?(line["effective_date"][0, 4].to_i,
                               line["effective_date"][4, 2].to_i,
                               line["effective_date"][6, 2].to_i)
            @errors[lineno] = I18n.t('registerCourseEnrollmentList1.PRI_REG_RESULTLIST_EFFECTIVEDATEFORMATERROR')
            next
          end
        end
      end

      # ステータスコードによって処理を分岐
      case line["status_cd"]
      when BUS_SER_IMP_IMP_INSERTSTATUSCD then
        # 指定されたアカウントのユーザが登録されていない場合
        if find_user.blank?
          @errors[lineno] = I18n.t('registerCourseEnrollmentList1.PRI_REG_RESULTLIST_ACCOUNTNOTFOUNDERROR')
          next
        end

        # 指定された科目が登録されていない場合
        if find_course.blank?
          @errors[lineno] = I18n.t('registerCourseEnrollmentList1.PRI_REG_RESULTLIST_COURSENOTFOUNDERROR')+":"+
                                   line["course_cd"]+","+line["school_year"]+","+line["season_cd"]
          next
        end

        # 指定された科目担任関連情報が既に登録されている場合
        if !find_course_enrollment_user.blank?
          @errors[lineno] = I18n.t('registerCourseAssignedList1.PRI_REG_RESULTLIST_COURSEASSIGNEDDUPLICATIONERROR')+":"+
                                   line["account"]+","+line["course_cd"]+","+line["school_year"]+","+line["season_cd"]
          next
        end
      when BUS_SER_IMP_IMP_UPDATESTATUSCD,
           BUS_SER_IMP_IMP_LOGICALDELETESTATUSCD,
           BUS_SER_IMP_IMP_DELETESTATUSCD
        # 指定された科目担任関連情報が既に登録されている場合
        if find_course_enrollment_user.blank?
          @errors[lineno] = I18n.t('registerCourseAssignedList1.PRI_REG_RESULTLIST_COURSEASSIGNEDDUPLICATIONERROR')+":"+
                                   line["account"]+","+line["course_cd"]+","+line["school_year"]+","+line["season_cd"]
          next
        end
      end

      course_enrollment_users << line["account"]+line["course_cd"]+line["school_year"]+line["season_cd"]
    end

    course_enrollments
  end

  def import_course_enrollments
    CourseEnrollmentUser.transaction do
      begin
        @course_enrollments.each do |course_enrollment|
          find_user = User.find_by(:account => course_enrollment["account"])
          find_course = Course.find_by(:course_cd => course_enrollment["course_cd"], :school_year => course_enrollment["school_year"], :season_cd => course_enrollment["season_cd"])
          if find_user && find_course
            find_course_enrollment_user = CourseEnrollmentUser.find_by(:user_id => find_user.id, :course_id => find_course.id)
          end

          # ステータスコードによって処理を分岐
          case course_enrollment["status_cd"]
          when BUS_SER_IMP_IMP_INSERTSTATUSCD then
            course_enrollment_user = CourseEnrollmentUser.new(set_course_enrollments_user_params(course_enrollment, find_user, find_course))
            course_enrollment_user.save
          when BUS_SER_IMP_IMP_UPDATESTATUSCD then
            find_course_enrollment_user.update(set_course_enrollments_user_params(course_enrollment, find_user, find_course))
          when BUS_SER_IMP_IMP_LOGICALDELETESTATUSCD then
            find_course_enrollment_user.update(set_course_enrollments_user_params(course_enrollment, find_user, find_course))
          when BUS_SER_IMP_IMP_DELETESTATUSCD then
            find_course_enrollment_user.destroy
          end

        end
      rescue => e
        logger.error e.backtrace.join("\n")
        raise ActiveRecord::Rollback
        @messages = e.message
      end
    end
  end

  def set_course_enrollments_user_params(course_enrollment, find_user, find_course)
    params = {}

    # 科目情報を設定
    params[:course_id] = find_course.id
    params[:user_id] = find_user.id
    params[:effective_date] = course_enrollment["effective_date"]

    # ステータスコードによって処理を分岐
    case course_enrollment["status_cd"]
    when BUS_SER_IMP_IMP_INSERTSTATUSCD then
      params[:insert_user_id] = User.current_user.id
    when BUS_SER_IMP_IMP_UPDATESTATUSCD then
      params[:update_user_id] = User.current_user.id
    when BUS_SER_IMP_IMP_LOGICALDELETESTATUSCD then
      params[:update_user_id] = User.current_user.id
    when BUS_SER_IMP_IMP_DELETESTATUSCD then
    end

    return params
  end



  #
  # 共通処理
  #
  def sample_file(file_type)
    case file_type
    when CsvUser::CSV_FILE_TYPE then
      file_name = CsvUser::CSV_SAMPLE_FILE
    when CsvCourse::CSV_FILE_TYPE then
      file_name = CsvCourse::CSV_SAMPLE_FILE
    when CsvCourseAssigned::CSV_FILE_TYPE then
      file_name = CsvCourseAssigned::CSV_SAMPLE_FILE
    when CsvCourseEnrollment::CSV_FILE_TYPE then
      file_name = CsvCourseEnrollment::CSV_SAMPLE_FILE
    end

    file_path = Rails.root.join('public', 'download', 'sample', file_name)
    if File.exist?(file_path)
      file_stat = File::stat(file_path)
      send_file(file_path, :filename => file_name, :length => file_stat.size)
    else
      render text: t("page_management.MAT_COM_MYFOLDER_NOCONTENTS")
    end
  end

  private
    def csv_params
      params.require(:upload).permit(:file, :not_overwrite)
    end
end
