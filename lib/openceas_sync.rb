class OpenceasSync < Admin::UploadsController
  CONTENT_TYPE_USERS = 1
  CONTENT_TYPE_COURSES = 2
  CONTENT_TYPE_COURSE_ASSIGNS = 3
  CONTENT_TYPE_ENROLLMENTS = 4

  def self.bulk_registration(type = nil)
    puts "##########################################################"
    puts "OpenceasSync: Started at #{cretae_timestamp}"
    puts "##########################################################"
    puts ""

    # 設定読み込み
    settings = load_settings()

    # 実行ユーザ情報
    verified_user = User.find(settings["execution_user_id"]) 
    User.current_user = verified_user

    uploads = Uploads.new

    # ユーザ
    if type == CONTENT_TYPE_USERS || type.nil?
      user_list = suffix_slash(settings["infile_path"], true) + settings["filename"]["user_list"]
      if File.exist?(user_list)
        uploads.user_upload(user_list)
      
        # バックアップ
        file_backup(settings["infile_path"], settings["backup_path"], settings["filename"]["user_list"])
      else
        raise "ユーザリストが存在しません。 [#{user_list}]"
      end
    end

    # 科目
    if type == CONTENT_TYPE_COURSES || type.nil?
      course_list = suffix_slash(settings["infile_path"], true) + settings["filename"]["course_list"]
      if File.exist?(course_list)
        uploads.course_upload(course_list)
      
        # バックアップ
        file_backup(settings["infile_path"], settings["backup_path"], settings["filename"]["course_list"])
      else
        raise "科目リストが存在しません。 [#{course_list}]"
      end
    end

    # 科目担任関連
    if type == CONTENT_TYPE_COURSE_ASSIGNS || type.nil?
      course_assign_list = suffix_slash(settings["infile_path"], true) + settings["filename"]["course_assign_list"]
      if File.exist?(course_assign_list)
        uploads.course_assign_upload(course_assign_list)
      
        # バックアップ
        file_backup(settings["infile_path"], settings["backup_path"], settings["filename"]["course_assign_list"])
      else
        raise "科目担任関連リストが存在しません。 [#{course_assign_list}]"
      end
    end

    # 履修情報
    if type == CONTENT_TYPE_ENROLLMENTS || type.nil?
      enrollment_list = suffix_slash(settings["infile_path"], true) + settings["filename"]["enrollment_list"]
      if File.exist?(enrollment_list)
        uploads.enrollment_upload(enrollment_list)
      
        # バックアップ
        file_backup(settings["infile_path"], settings["backup_path"], settings["filename"]["enrollment_list"])
      else
        raise "履修情報リストが存在しません。 [#{enrollment_list}]"
      end
    end

    puts ""
    puts "##########################################################"
    puts "OpenceasSync: Ended at #{cretae_timestamp}"
    puts "##########################################################"

  rescue => e
    puts ""
    puts "##########################################################"
    puts "*** OpenceasSync: Failed at #{cretae_timestamp}"
    puts "#{e.message}"
    puts "##########################################################"
  end

  def self.import_users
    bulk_registration(CONTENT_TYPE_USERS)
  end

  def self.import_courses
    bulk_registration(CONTENT_TYPE_COURSES)
  end

  def self.import_course_assigns
    bulk_registration(CONTENT_TYPE_COURSE_ASSIGNS)
  end

  def self.import_enrollments
    bulk_registration(CONTENT_TYPE_ENROLLMENTS)
  end

  class Uploads < Admin::UploadsController
    def initialize 
      super
    end

    # ユーザアップロード
    def user_upload(user_list)
      @users = user_csv_to_hash(user_list)

      if @errors.count == 0
        import_users
        puts "ユーザリスト（#{user_list}）を処理しました。"
      else
        error_messages = create_error_messages(@errors)
        raise error_messages
      end

      rescue => e
        puts e.message
    end

    # 科目アップロード
    def course_upload(course_list)
      @courses = course_csv_to_hash(course_list)

      if @errors.count == 0
        import_courses
        puts "科目リスト（#{course_list}）を処理しました。"
      else
        error_messages = create_error_messages(@errors)
        raise error_messages
      end

      rescue => e
        puts e.message
    end

    # 科目担任関連アップロード
    def course_assign_upload(course_assign_list)
      @course_assigns = course_assigned_csv_to_hash(course_assign_list)

      if @errors.count == 0
        import_course_assigns
        puts "科目担任関連リスト（#{course_assign_list}）を処理しました。"
      else
        error_messages = create_error_messages(@errors)
        raise error_messages
      end

      rescue => e
        puts e.message
    end

    # 履修情報アップロード
    def enrollment_upload(enrollment_list)
      @course_enrollments = course_enrollment_csv_to_hash(enrollment_list)

      if @errors.count == 0
        import_course_enrollments
        puts "履修情報リスト（#{enrollment_list}）を処理しました。"
      else
        error_messages = create_error_messages(@errors)
        raise error_messages
      end

      rescue => e
        puts e.message
    end

    def create_error_messages(errors)
      messages = ""
      errors.each do | key, value |
        messages += "\n" if messages.present?
        messages += "#{key}行目：#{value}"
      end
      messages
    end
  end

  private
    def self.cretae_timestamp()
      t = Time.new
      t.strftime("%Y-%m-%d %H:%M:%S")
    end

    def self.load_settings
      settings = YAML.load_file("config/openceas_sync.yml")[Rails.env]
    end

    def self.file_backup(infile_path, backup_path, filename)
      t = Time.new
      infilename = "#{suffix_slash(infile_path, true)}#{filename}"
      backup_path = "#{backup_path}/#{t.strftime('%Y%m%d')}"
      create_dir(backup_path)
      backup_filename = "#{suffix_slash(backup_path, true)}#{filename}_#{t.strftime('%Y%m%d%H%M%S')}"

      FileUtils.mv(infilename, backup_filename) if FileTest.exist?(infilename)
    end

    def self.create_dir(file_dir)
      FileUtils.mkdir_p(file_dir) unless FileTest.exist?(file_dir)
    end

    def self.suffix_slash(path, is_root=false)
      if !is_root && path[0, 1] == "/"
        path.slice!(0, 1)
      end
      if path[path.length - 1, 1] != "/"
        path = path + "/"
      end

      path
    end
end
