class AssignmentEssayCommentHistory < ApplicationRecord
  include UploadFileModule

  belongs_to  :answer_score_history

  def get_file_path
    essay_path = self.get_essay_path(self.answer_score_history.generic_page.course)
    essay_path + self.processed_link_name.to_s
  end
end
