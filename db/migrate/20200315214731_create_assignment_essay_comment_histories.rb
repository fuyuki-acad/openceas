class CreateAssignmentEssayCommentHistories < ActiveRecord::Migration[5.1]
  def change
    create_table :assignment_essay_comment_histories do |t|
      t.bigint "answer_score_history_id", null: false
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

      t.timestamps
    end
  end
end
