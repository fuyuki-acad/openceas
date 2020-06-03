class ModifyFieldsOnCourseAccessLogs < ActiveRecord::Migration[5.1]
  def up
    change_column :course_access_logs,  :access_page,   :string,  limit: 2048
    change_column :course_access_logs,  :query_string,  :string,  limit: 2048
  end

  def down
    change_column :course_access_logs,  :access_page,   :string,  limit: 256
    change_column :course_access_logs,  :query_string,  :string,  limit: 256
  end
end
