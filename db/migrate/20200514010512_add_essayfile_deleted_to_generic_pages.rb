class AddEssayfileDeletedToGenericPages < ActiveRecord::Migration[5.1]
  def change
    add_column :generic_pages, :essayfile_deleted, :boolean, default: false, null: false
  end
end
