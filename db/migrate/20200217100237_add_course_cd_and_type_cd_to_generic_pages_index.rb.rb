class AddCourseCdAndTypeCdToGenericPagesIndex < ActiveRecord::Migration[5.1]
  def change
    add_index :generic_pages, [:course_id, :type_cd]
  end
end
