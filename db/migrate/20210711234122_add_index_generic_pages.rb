class AddIndexGenericPages < ActiveRecord::Migration[5.1]
  def change
    add_index :generic_pages, [:end_time]
    add_index :generic_pages, [:type_cd, :course_id, :end_time]
  end
end
