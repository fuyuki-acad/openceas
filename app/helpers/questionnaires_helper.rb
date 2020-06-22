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

module QuestionnairesHelper
  def checked(quiz, answers, question_id)
    if answers.kind_of?(Hash) && answers.count == 0
      return true if quiz.select_mark_flag == Settings.SELECT_SELECTMARKFLG_ON
    else
      if question_id && answers[question_id.to_s]
        answer = answers[question_id.to_s]
        if answer.kind_of?(Array)
          answer.each do |select_answer|
            return true if quiz.id.to_s == select_answer["select_answer_id"].to_s
          end
          return nil
        elsif answer
          return true if quiz.id.to_s == answer["select_answer_id"].to_s
        end
      end
    end
  end

  def checked_other(answers, question_id)
    if answers && answers[question_id.to_s]
      answer = answers[question_id.to_s]
      if answer.kind_of?(Array)
        answer.each do |select_answer|
          return true if select_answer["select_answer_id"].to_s == Answer::OTHER_ANSWER_ID
        end
        return nil
      else
        return true if Answer::OTHER_ANSWER_ID == answer["select_answer_id"].to_s
      end
    end
  end

  def quiz_options_options_for_select(question, answer)
    quizzes = question.select_quizzes.map {|quiz| [quiz.content, quiz.id]}
    quizzes << [t("materials_registration.COMMONMATERIALSREGISTRATION_OTHER"), Answer::OTHER_ANSWER_ID] if question.text_flag == Settings.SELECT_TEXTROW_TEXT
    options_for_select(quizzes, :selected => selected_item(question, answer))
  end

  def selected_item(question, answer)
    if answer
      answer["select_answer_id"].to_s
    else
      question.select_quizzes.each do |quiz|
        return quiz.id.to_s if quiz.select_mark_flag == Settings.SELECT_SELECTMARKFLG_ON
      end
    end
  end

  def answered_text_value(answers, question_id)
    text = ""
    if answers && answers[question_id.to_s]
      answer = answers[question_id.to_s]
      if answer.kind_of?(Array)
        answer.each do |select_answer|
          if select_answer["select_answer_id"].to_s == Answer::OTHER_ANSWER_ID
            text = select_answer["text_answer"]
            break
          end
        end
      else
        text = answer["text_answer"]
      end
    end

    text
  end

  def confirm_answer(question, answers)
    selected_answer = ""

    ## チェックボックスの時
    if question.pattern_cd == Settings.QUESTION_PATTERNCD_CHECK
      if answers[question.id.to_s]
        selected_answer = ""
        answers[question.id.to_s].each do |answer|
          if answer.select_answer_id.to_s == Answer::OTHER_ANSWER_ID
            selected_answer += t("materials_registration.COMMONMATERIALSREGISTRATION_OTHER") +
            t("common.COMMON_BR_html") + t("common.COMMON_PARANTHESISLEFT") + answer.text_answer + t("common.COMMON_PARANTHESISRIGHT") + "<br />".html_safe
          elsif answer.select_answer_id
            selected_answer += answer.select_quiz.content.html_safe + "<br />".html_safe
          end
        end
      else
        selected_answer = "（" + t("execution.COMMONMATERIALSEXECUTION_NOTANSWER") + "）"
      end

    ## 記述の時
    elsif question.pattern_cd == Settings.QUESTION_PATTERNCD_ESSAY
      if answers[question.id.to_s]
        selected_answer = answers[question.id.to_s].text_answer
      else
        selected_answer = "（" + t("execution.COMMONMATERIALSEXECUTION_NOTANSWER") + "）"
      end

    ## ラジオボタンの時
    ## リストボックスの時
    else
      if answers[question.id.to_s]
        if answers[question.id.to_s].select_answer_id.to_s == Answer::OTHER_ANSWER_ID
          selected_answer = t("materials_registration.COMMONMATERIALSREGISTRATION_OTHER") +
          t("common.COMMON_BR_html") + t("common.COMMON_PARANTHESISLEFT") + answers[question.id.to_s].text_answer + t("common.COMMON_PARANTHESISRIGHT")
        elsif answers[question.id.to_s].select_answer_id
          selected_answer = answers[question.id.to_s].select_quiz.content
        else
          selected_answer = "（" + t("execution.COMMONMATERIALSEXECUTION_NOTANSWER") + "）"
        end
      else
        selected_answer = "（" + t("execution.COMMONMATERIALSEXECUTION_NOTANSWER") + "）"
      end
    end

    selected_answer.html_safe
  end
end
