#--
# Copyright (c) 2019 Fuyuki Academy
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

module Teacher::QuestionsHelper
  def question_checked(form_param, index, quiz = nil)
    if form_param && form_param['quizzes_attributes'] && form_param['quizzes_attributes'][index.to_s]
      attr = form_param['quizzes_attributes'][index.to_s]
      return true if Settings.SELECT_SELECTCORRECTFLG_CORRECT.to_s == attr["select_correct_flag"].to_s || Settings.SELECT_SELECTMARKFLG_ON.to_s == attr["select_mark_flag"].to_s
    elsif quiz
      return true if quiz.select_correct_flag == Settings.SELECT_SELECTCORRECTFLG_CORRECT || quiz.select_mark_flag == Settings.SELECT_SELECTMARKFLG_ON
    end
  end

  def question_options_for_select(question)
    quizzes = []
    selected_id = ""

    question.select_quizzes.each do |quiz|
      quizzes << [quiz.content, quiz.id]
      if quiz.select_correct_flag == Settings.SELECT_SELECTCORRECTFLG_CORRECT || quiz.select_mark_flag == Settings.SELECT_SELECTMARKFLG_ON
        selected_id = quiz.id
      end
    end
    quizzes << [t("materials_registration.COMMONMATERIALSREGISTRATION_OTHER"), Answer::OTHER_ANSWER_ID] if question.text_flag == Settings.SELECT_TEXTROW_TEXT
    options_for_select(quizzes, :selected => selected_id)
  end

  def question_file_checked(quiz)
    return true if quiz['select_correct_flag'] == "1" || quiz['select_mark_flag'] == '1'
  end

  def question_file_options_for_select(question)
    quizzes = []
    selected_id = ""

    question['sels'].each.with_index do |quiz, index|
      quizzes << [quiz['content'], index]
      if quiz['select_correct_flag'] == '1' || quiz['select_mark_flag'] == '1'
        selected_id = index
      end
    end
    options_for_select(quizzes, :selected => selected_id)
  end
end
