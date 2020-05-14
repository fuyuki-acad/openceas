class AddFileSizeToAnswerScores < ActiveRecord::Migration[5.1]
  def change
    add_column :answer_scores, :file_size, :integer
    add_column :answer_scores, :file_deleted, :boolean, default: false
  end
end
