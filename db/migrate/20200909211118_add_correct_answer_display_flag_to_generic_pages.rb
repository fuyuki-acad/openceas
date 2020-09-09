class AddCorrectAnswerDisplayFlagToGenericPages < ActiveRecord::Migration[5.1]
  def change
    add_column :generic_pages, :correct_answer_display_flag, :boolean, default: false
  end
end
