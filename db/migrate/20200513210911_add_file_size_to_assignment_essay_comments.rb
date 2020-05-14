class AddFileSizeToAssignmentEssayComments < ActiveRecord::Migration[5.1]
  def change
    add_column :assignment_essay_comments, :file_size, :integer
    add_column :assignment_essay_comments, :file_deleted, :boolean, default: false
  end
end
