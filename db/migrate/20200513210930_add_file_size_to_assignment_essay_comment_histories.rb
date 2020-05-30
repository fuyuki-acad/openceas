class AddFileSizeToAssignmentEssayCommentHistories < ActiveRecord::Migration[5.1]
  def change
    add_column :assignment_essay_comment_histories, :file_size, :integer
    add_column :assignment_essay_comment_histories, :file_deleted, :boolean, default: false
  end
end
