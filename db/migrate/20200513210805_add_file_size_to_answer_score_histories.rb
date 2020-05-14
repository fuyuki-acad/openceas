class AddFileSizeToAnswerScoreHistories < ActiveRecord::Migration[5.1]
  def change
    add_column :answer_score_histories, :file_size, :integer
    add_column :answer_score_histories, :file_deleted, :boolean, default: false
  end
end
