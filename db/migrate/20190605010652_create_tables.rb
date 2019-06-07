class CreateTables < ActiveRecord::Migration[5.1]
  def change
    create_table "admitted_tokens", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "user_id"
      t.string "description"
      t.string "access_token", collation: "utf8_bin"
      t.datetime "expire_date"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["access_token"], name: "index_admitted_tokens_on_access_token", unique: true
    end

    create_table "announcement_mail_logs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "user_id", null: false
      t.bigint "announcement_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["announcement_id"], name: "index_announcement_mail_logs_on_announcement_id"
      t.index ["user_id"], name: "index_announcement_mail_logs_on_user_id"
    end

    create_table "announcements", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "course_id", null: false
      t.string "subject", limit: 128, null: false
      t.string "content", limit: 4096, null: false
      t.integer "mail_flag", limit: 1, null: false
      t.integer "announcement_cd", null: false
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["course_id"], name: "index_announcements_on_course_id"
    end

    create_table "answer_histories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "question_id", null: false
      t.bigint "user_id", null: false
      t.integer "answer_count", default: 0, null: false
      t.bigint "select_answer_id", null: false
      t.string "text_answer", limit: 4096
      t.integer "score"
      t.integer "self_score"
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.bigint "answer_score_id"
      t.integer "answer_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["answer_id", "answer_count"], name: "index_answer_histories_on_answer_id_and_answer_count"
      t.index ["answer_score_id", "answer_count"], name: "index_answer_histories_on_answer_score_id_and_answer_count"
      t.index ["question_id", "user_id", "answer_count"], name: "index_question_user_count_on_answer_histories"
    end

    create_table "answer_score_histories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "page_id", null: false
      t.bigint "user_id", null: false
      t.integer "total_score", default: 0, null: false
      t.integer "total_raw_score", default: 0
      t.integer "self_total_score", default: 0
      t.integer "self_user_id"
      t.string "assignment_essay_score", limit: 4096
      t.integer "answer_count", default: 0, null: false
      t.integer "pass_cd", null: false
      t.string "file_name", limit: 256
      t.string "link_name", limit: 256
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.bigint "answer_score_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["answer_score_id", "answer_count"], name: "index_answer_score_histories_on_answer_score_id_and_answer_count", unique: true  
      t.index ["page_id", "user_id", "answer_count"], name: "index_page_user_count_on_answer_histories"
    end

    create_table "answer_scores", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "page_id", null: false
      t.bigint "user_id", null: false
      t.integer "total_score", default: 0, null: false
      t.integer "total_raw_score"
      t.integer "self_total_score"
      t.integer "self_user_id"
      t.string "assignment_essay_score", limit: 128
      t.integer "answer_count", default: 0, null: false
      t.integer "pass_cd", null: false
      t.string "file_name", limit: 256
      t.string "link_name", limit: 256
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["page_id", "user_id"], name: "index_answer_scores_on_page_id_and_user_id"
      t.index ["page_id"], name: "index_answer_scores_on_page_id"
      t.index ["user_id", "page_id", "answer_count"], name: "index_answer_scores_on_user_id_and_page_id_and_answer_count"
      t.index ["user_id"], name: "index_answer_scores_on_user_id"
    end

    create_table "answers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "question_id", null: false
      t.bigint "user_id", null: false
      t.integer "answer_count", default: 0, null: false
      t.bigint "select_answer_id", null: false
      t.string "text_answer", limit: 4096
      t.integer "score"
      t.integer "self_score"
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.bigint "answer_score_id"
      t.index ["question_id", "user_id", "answer_count"], name: "index_answers_on_question_id_and_user_id_and_answer_count"
      t.index ["question_id"], name: "index_answers_on_question_id"
      t.index ["select_answer_id"], name: "index_answers_on_select_answer_id"
      t.index ["user_id"], name: "index_answers_on_user_id"
    end

    create_table "assignment_essay_comments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "answer_score_id", null: false
      t.string "memo", limit: 4096, null: false
      t.integer "mail_flag", limit: 1, default: 0, null: false
      t.datetime "mailsend_date"
      t.integer "return_flag", limit: 1, default: 0, null: false
      t.string "processed_file_name", limit: 256
      t.string "processed_link_name", limit: 256
      t.string "return_file_name", limit: 256
      t.string "return_link_name", limit: 256
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["answer_score_id"], name: "index_assignment_essay_comments_on_answer_score_id"
    end

    create_table "assignment_essay_mail_crontabs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "generic_page_id", null: false
      t.integer "finish_flag", limit: 1, default: 0, null: false
      t.datetime "end_time"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["generic_page_id"], name: "index_assignment_essay_mail_crontabs_on_generic_page_id"
    end

    create_table "assignment_essays", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "generic_page_id", null: false
      t.string "content", limit: 4096, null: false
      t.integer "view_rank", default: 0, null: false
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["generic_page_id"], name: "index_assignment_essays_on_generic_page_id"
      t.index ["view_rank"], name: "index_assignment_essays_on_view_rank"
    end

    create_table "attendance_information", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "attendance_id", null: false
      t.bigint "user_id", null: false
      t.integer "attendance_data_cd", null: false
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["attendance_id"], name: "index_attendance_information_on_attendance_id"
      t.index ["user_id"], name: "index_attendance_information_on_user_id"
    end

    create_table "attendance_keys", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.integer "course_id"
      t.timestamp "open_date", default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.integer "lesson_count", default: 0, null: false
      t.integer "save_id"
      t.string "key_word", limit: 9
      t.integer "item"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "attendances", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "course_id", null: false
      t.integer "class_session_no", null: false
      t.integer "attendance_count", default: 0, null: false
      t.integer "status_cd"
      t.datetime "attendance_time"
      t.datetime "late_time"
      t.integer "attendance_period"
      t.integer "late_period"
      t.integer "start_pass"
      t.integer "finish_pass"
      t.integer "start_flag", limit: 1, default: 0, null: false
      t.integer "stop_flag", limit: 1, default: 0, null: false
      t.integer "finish_flag", limit: 1, default: 0, null: false
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["attendance_count"], name: "index_attendances_on_attendance_count"
      t.index ["class_session_no"], name: "index_attendances_on_class_session_no"
      t.index ["course_id", "class_session_no", "attendance_count"], name: "index_attendances_course_id_class_session_no_attendance_count"
      t.index ["course_id"], name: "index_attendances_on_course_id"
    end

    create_table "bbses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "thread_id", null: false
      t.bigint "user_id", null: false
      t.bigint "parent_bbs_id"
      t.string "user_name", limit: 64, null: false
      t.string "mail", limit: 256
      t.string "url", limit: 256
      t.string "title", limit: 128, null: false
      t.string "content", limit: 4096, null: false
      t.string "ip", limit: 32
      t.string "delete_pass", limit: 64, null: false
      t.string "file_name", limit: 256
      t.string "link_name", limit: 256
      t.integer "file_size", default: 0, null: false
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["parent_bbs_id"], name: "index_bbses_on_parent_bbs_id"
      t.index ["thread_id"], name: "index_bbses_on_thread_id"
      t.index ["user_id"], name: "index_bbses_on_user_id"
    end

    create_table "class_sessions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "course_id", null: false
      t.integer "class_session_no", null: false
      t.string "class_session_title", limit: 128
      t.text "overview"
      t.string "class_session_day", limit: 128
      t.text "class_session_memo"
      t.text "class_session_memo_closed"
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["class_session_no"], name: "index_class_sessions_on_class_session_no"
      t.index ["course_id"], name: "index_class_sessions_on_course_id"
    end

    create_table "combined_record_show_flags", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "course_id", null: false
      t.integer "multiple_flag", limit: 1, default: 0, null: false
      t.integer "essay_flag", limit: 1, default: 0, null: false
      t.integer "assignment_essay_flag", limit: 1, default: 0, null: false
      t.integer "multiple_fib_flag", limit: 1, default: 0, null: false
      t.integer "questionnaire_flag", limit: 1, default: 0, null: false
      t.integer "attendance_flag", limit: 1, default: 0, null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["course_id"], name: "index_combined_record_show_flags_on_course_id"
    end

    create_table "course_access_logs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "course_id", null: false
      t.bigint "user_id", null: false
      t.string "ip", limit: 32
      t.integer "class_session_no"
      t.string "access_page", limit: 256
      t.string "query_string", limit: 256
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["course_id"], name: "index_course_access_logs_on_course_id"
      t.index ["user_id"], name: "index_course_access_logs_on_user_id"
    end

    create_table "course_assigned_users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "course_id"
      t.bigint "user_id"
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["course_id"], name: "index_course_assigned_users_on_course_id"
      t.index ["user_id"], name: "index_course_assigned_users_on_user_id"
    end

    create_table "course_enrollment_users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "course_id", null: false
      t.bigint "user_id", null: false
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["course_id", "user_id"], name: "index_course_enrollment_users_on_course_id_and_user_id"
      t.index ["course_id"], name: "index_course_enrollment_users_on_course_id"
      t.index ["user_id"], name: "index_course_enrollment_users_on_user_id"
    end

    create_table "courses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string "course_cd", limit: 128, null: false
      t.string "course_name", limit: 64, null: false
      t.text "overview"
      t.integer "school_year", null: false
      t.integer "season_cd", null: false
      t.integer "day_cd", null: false
      t.integer "hour_cd", null: false
      t.string "instructor_name", limit: 128
      t.string "major", limit: 64
      t.integer "class_session_count", default: 15, null: false
      t.integer "indirect_use_flag", limit: 1, default: 0, null: false
      t.bigint "parent_course_id"
      t.integer "group_folder_count", default: 0, null: false
      t.integer "term_flag", limit: 1, default: 0, null: false
      t.string "open_course_pass", limit: 64
      t.integer "open_course_flag", limit: 1, default: 0, null: false
      t.integer "bbs_cd"
      t.integer "chat_cd"
      t.integer "announcement_cd"
      t.integer "faq_cd"
      t.integer "open_course_bbs_flag", limit: 1, default: 0, null: false
      t.integer "open_course_chat_flag", limit: 1, default: 0, null: false
      t.integer "open_course_announcement_flag", limit: 1, default: 0, null: false
      t.integer "open_course_faq_flag", limit: 1, default: 0, null: false
      t.string "attendance_ip_list", limit: 256
      t.integer "courseware_flag", limit: 1, default: 0, null: false
      t.string "courseware_rank", limit: 64, default: "0"
      t.integer "season_cd1"
      t.integer "day_cd1"
      t.integer "hour_cd1"
      t.integer "season_cd2"
      t.integer "day_cd2"
      t.integer "hour_cd2"
      t.integer "season_cd3"
      t.integer "day_cd3"
      t.integer "hour_cd3"
      t.integer "season_cd4"
      t.integer "day_cd4"
      t.integer "hour_cd4"
      t.integer "unread_assignment_display_cd", default: 0, null: false
      t.integer "unread_faq_display_cd", default: 0, null: false
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.datetime "deleted_at"
      t.string "delete_memo", limit: 128
      t.integer "delete_user_id"
      t.index ["course_cd", "school_year", "season_cd"], name: "index_courses_on_course_cd_and_school_year_and_season_cd"
      t.index ["course_cd"], name: "index_courses_on_course_cd"
      t.index ["day_cd"], name: "index_courses_on_day_cd"
      t.index ["hour_cd"], name: "index_courses_on_hour_cd"
      t.index ["parent_course_id"], name: "index_courses_on_parent_course_id"
      t.index ["school_year"], name: "index_courses_on_school_year"
      t.index ["season_cd"], name: "index_courses_on_season_cd"
    end

    create_table "courseware_course_associations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "courseware_id", null: false
      t.bigint "course_id", null: false
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["course_id"], name: "index_courseware_course_associations_on_course_id"
      t.index ["courseware_id"], name: "index_courseware_course_associations_on_courseware_id"
    end

    create_table "courseware_user_associations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "courseware_id", null: false
      t.bigint "user_id", null: false
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["courseware_id"], name: "index_courseware_user_associations_on_courseware_id"
      t.index ["user_id"], name: "index_courseware_user_associations_on_user_id"
    end

    create_table "faq_answers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "faq_id", null: false
      t.string "answer_title", limit: 128, null: false
      t.string "answer", limit: 4096, null: false
      t.string "open_answer", limit: 4096
      t.string "open_question", limit: 4096
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["faq_id"], name: "index_faq_answers_on_faq_id"
    end

    create_table "faqs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "course_id", null: false
      t.bigint "user_id", null: false
      t.string "faq_title", limit: 128, null: false
      t.string "question", limit: 4096, null: false
      t.integer "open_flag", limit: 1, default: 0, null: false
      t.integer "response_flag", limit: 1, default: 0, null: false
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["course_id"], name: "index_faqs_on_course_id"
      t.index ["user_id"], name: "index_faqs_on_user_id"
    end

    create_table "general_announcements", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string "title", limit: 128, null: false
      t.string "content", limit: 4096, null: false
      t.integer "type_cd", null: false
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "generic_page_class_session_associations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "generic_page_id", null: false
      t.bigint "class_session_id", null: false
      t.integer "view_rank", default: 0, null: false
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["class_session_id"], name: "index_generic_page_class_session_associations_class_session_id"
      t.index ["generic_page_id"], name: "index_generic_page_class_session_associations_on_generic_page_id"
    end

    create_table "generic_page_question_associations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "generic_page_id", null: false
      t.bigint "question_id", null: false
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["generic_page_id"], name: "index_generic_page_question_associations_on_generic_page_id"
      t.index ["question_id"], name: "index_generic_page_question_associations_on_question_id"
    end

    create_table "generic_pages", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "course_id", null: false
      t.string "generic_page_title", limit: 128, null: false
      t.integer "pass_grade"
      t.integer "max_count", default: 0, null: false
      t.string "start_pass", limit: 64
      t.datetime "start_time"
      t.datetime "end_time"
      t.integer "self_flag", limit: 1, default: 0, null: false
      t.string "self_pass", limit: 64
      t.string "url_content", limit: 4096
      t.integer "type_cd"
      t.string "file_name", limit: 256
      t.string "link_name", limit: 256
      t.string "explanation_file_name", limit: 256
      t.string "explanation_link_name", limit: 256
      t.integer "edit_flag", limit: 1, default: 0, null: false
      t.integer "anonymous_flag", limit: 1, default: 0, null: false
      t.integer "timelag_flag", limit: 1, default: 0, null: false
      t.integer "pre_grading_enable_flag", limit: 1, default: 0, null: false
      t.integer "assignment_essay_return_method_cd"
      t.integer "score_open_flag", limit: 1, default: 0, null: false
      t.integer "fck_flag", limit: 1, default: 0, null: false
      t.text "material_memo"
      t.text "material_memo_closed"
      t.text "content"
      t.integer "start_flag", limit: 1, default: 0, null: false
      t.integer "stop_flag", limit: 1, default: 0, null: false
      t.integer "interview_flag", limit: 1, default: 0, null: false
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["course_id"], name: "index_generic_pages_on_course_id"
      t.index ["type_cd"], name: "index_generic_pages_on_type_cd"
    end

    create_table "group_folder_materials", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "group_folder_id", null: false
      t.bigint "user_id", null: false
      t.string "title", limit: 128, null: false
      t.string "display_pass", limit: 64
      t.string "file_name", limit: 256, null: false
      t.string "link_name", limit: 256, null: false
      t.integer "file_size", default: 0, null: false
      t.string "file_type", limit: 256
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["group_folder_id"], name: "index_group_folder_materials_on_group_folder_id"
      t.index ["user_id"], name: "index_group_folder_materials_on_user_id"
    end

    create_table "group_folders", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "course_id", null: false
      t.string "title", limit: 128
      t.string "memo", limit: 4096
      t.integer "view_rank", default: 0, null: false
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["course_id"], name: "index_group_folders_on_course_id"
    end

    create_table "helps", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string "title", limit: 256, null: false
      t.string "version", limit: 45, null: false
      t.string "link_name", limit: 256
      t.string "file_name", limit: 256
      t.integer "view_rank", default: 0, null: false
      t.integer "target_auth_cd"
      t.integer "insert_user_id"
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "locales", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string "title"
      t.string "locale"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "mobile_users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.integer "user_id"
      t.string "mobile_id", limit: 256
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "open_course_assigned_users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "course_id", null: false
      t.bigint "user_id", null: false
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["course_id"], name: "index_open_course_assigned_users_on_course_id"
      t.index ["user_id"], name: "index_open_course_assigned_users_on_user_id"
    end

    create_table "periods", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string "jigen_name", limit: 10
      t.time "start_jikoku"
      t.time "end_jikoku"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "qna_requests", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "user_id"
      t.text "question"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "qna_responses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "qna_request_id"
      t.text "answer"
      t.integer "score", default: 0
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "questions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "parent_question_id"
      t.text "content", null: false
      t.integer "pattern_cd", null: false
      t.integer "shuffle_flag", limit: 1, default: 0, null: false
      t.integer "exam_count", default: 0, null: false
      t.integer "score", default: 0, null: false
      t.integer "answer_in_full_cd"
      t.integer "random_cd"
      t.text "correct_answer_memo"
      t.text "wrong_answer_memo"
      t.integer "must_flag", limit: 1, default: 0, null: false
      t.text "answer_memo"
      t.string "file_name", limit: 256
      t.string "link_name", limit: 256
      t.integer "text_row", default: 0, null: false
      t.integer "view_rank", default: 0, null: false
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["parent_question_id"], name: "index_questions_on_parent_question_id"
      t.index ["view_rank"], name: "index_questions_on_view_rank"
    end

    create_table "roles", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string "name"
      t.string "description"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["name"], name: "index_roles_on_name"
    end

    create_table "s_maqs_answer_scores", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "page_id", null: false
      t.bigint "user_id", null: false
      t.integer "total_score", default: 0, null: false
      t.integer "total_raw_score", default: 0, null: false
      t.integer "self_total_score", default: 0, null: false
      t.integer "self_user_id"
      t.string "assignment_essay_score", limit: 128, default: "0"
      t.integer "answer_count", default: 0, null: false
      t.integer "pass_cd", null: false
      t.string "file_name", limit: 256
      t.string "link_name", limit: 256
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "select_quizzes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "question_id", null: false
      t.text "content", null: false
      t.integer "select_correct_flag", limit: 1, default: 0, null: false
      t.integer "select_mark_flag", limit: 1, default: 0, null: false
      t.integer "text_row", default: 0, null: false
      t.integer "view_rank", default: 0, null: false
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["question_id"], name: "index_select_quizzes_on_question_id"
      t.index ["view_rank"], name: "index_select_quizzes_on_view_rank"
    end

    create_table "self_studies", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string "self_study_name", limit: 64, null: false
      t.string "overview", limit: 4096
      t.string "top_link", limit: 256
      t.integer "display_flag", limit: 1, default: 1, null: false
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "self_study_access_logs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "self_study_id", null: false
      t.bigint "user_id", null: false
      t.string "ip", limit: 32
      t.string "access_page", limit: 256
      t.string "query_string", limit: 256
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["self_study_id"], name: "index_self_study_access_logs_on_self_study_id"
      t.index ["user_id"], name: "index_self_study_access_logs_on_user_id"
    end

    create_table "self_study_course_associations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "self_study_id", null: false
      t.bigint "course_id", null: false
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["course_id"], name: "index_self_study_course_associations_on_course_id"
      t.index ["self_study_id"], name: "index_self_study_course_associations_on_self_study_id"
    end

    create_table "sessions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string "session_id", null: false
      t.text "data"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
      t.index ["updated_at"], name: "index_sessions_on_updated_at"
    end

    create_table "smaqs_default_tables", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.integer "value"
      t.string "memo", limit: 256
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "sorts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.integer "course_id"
      t.integer "session_count", default: 0, null: false
      t.integer "gpid"
      t.integer "sort_n", default: 0, null: false
      t.integer "disp_flag", limit: 1, default: 0, null: false
      t.integer "memo_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "students", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string "user_id", limit: 50, default: "", null: false
      t.integer "course_id"
      t.integer "session_count"
      t.integer "gpid"
      t.integer "year"
      t.integer "month"
      t.integer "day"
      t.string "status", limit: 256, default: ""
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["user_id"], name: "index_students_on_user_id"
    end

    create_table "sub_attendances", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.integer "course_id"
      t.timestamp "save_date", default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.integer "save_id"
      t.string "key_word", limit: 256
      t.string "ip_address", limit: 256
      t.integer "user_id"
      t.string "latd", limit: 20
      t.string "latm", limit: 20
      t.string "lats", limit: 20
      t.string "lond", limit: 20
      t.string "lonm", limit: 20
      t.string "lons", limit: 20
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "sub_questions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.integer "generic_page_id"
      t.integer "start_flag", limit: 1, default: 0, null: false
      t.integer "stop_flag", limit: 1, default: 0, null: false
      t.integer "result_flag", limit: 1, default: 0, null: false
      t.integer "password"
      t.integer "open_ques_id"
      t.string "status", limit: 256
      t.integer "send_p", default: 0, null: false
      t.integer "start_p", default: 0, null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "system_logs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "user_id"
      t.string "account", limit: 64, null: false
      t.string "password", limit: 128, null: false
      t.string "ip", limit: 32
      t.integer "result_flag", limit: 1, default: 0, null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["created_at"], name: "index_system_logs_on_created_at"
      t.index ["user_id"], name: "index_system_logs_on_user_id"
    end

    create_table "teachers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.integer "course_id"
      t.integer "session_count"
      t.integer "year"
      t.integer "month"
      t.integer "day"
      t.string "status", limit: 256
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "threads", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "user_id", null: false
      t.bigint "course_id", null: false
      t.string "user_name", limit: 64, null: false
      t.string "title", limit: 128, null: false
      t.string "ip", limit: 32
      t.string "delete_pass", limit: 64, null: false
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["course_id"], name: "index_threads_on_course_id"
      t.index ["user_id"], name: "index_threads_on_user_id"
    end

    create_table "user_images", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "user_id"
      t.integer "image_type", null: false
      t.string "mount_url", null: false
      t.integer "exp_cd", null: false
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["user_id"], name: "index_user_images_on_user_id"
    end

    create_table "user_roles", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.integer "user_id"
      t.integer "role_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id"
    end

    create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string "account", limit: 64, default: "", null: false
      t.string "email", limit: 256, default: "", null: false
      t.string "encrypted_password", limit: 128, default: "", null: false
      t.string "reset_password_token"
      t.datetime "reset_password_sent_at"
      t.datetime "remember_created_at"
      t.integer "sign_in_count", default: 0, null: false
      t.datetime "current_sign_in_at"
      t.datetime "last_sign_in_at"
      t.string "current_sign_in_ip"
      t.string "last_sign_in_ip"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "user_name", limit: 64, null: false
      t.string "kana_name", limit: 64
      t.string "name_no_prefix", limit: 128
      t.string "display_name", limit: 64
      t.integer "sex_cd", null: false
      t.datetime "birth_date"
      t.string "email_mobile", limit: 256
      t.integer "role_id"
      t.integer "move_cd"
      t.datetime "move_date"
      t.integer "information_cd"
      t.integer "term_flag", limit: 1, default: 0, null: false
      t.integer "myfolder_button_flag", limit: 1, default: 0, null: false
      t.integer "updated_type"
      t.datetime "effective_date"
      t.string "effective_memo", limit: 128
      t.string "insert_memo", limit: 128
      t.integer "insert_user_id"
      t.string "update_memo", limit: 128
      t.integer "update_user_id"
      t.datetime "deleted_at"
      t.string "delete_memo", limit: 128
      t.integer "delete_user_id"
      t.datetime "deleted_res_at"
      t.string "delete_res_memo", limit: 128
      t.string "locale"
      t.string "uid"
      t.string "provider"
      t.index ["account"], name: "index_users_on_account", unique: true
      t.index ["name_no_prefix"], name: "index_users_on_name_no_prefix"
      t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
      t.index ["user_name"], name: "index_users_on_user_name"
    end

    create_table "weekly_classes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.integer "course_id"
      t.date "open_date"
      t.integer "lesson_count", default: 0, null: false
      t.string "select_item", limit: 256
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
