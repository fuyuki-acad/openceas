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

module CompoundsHelper
  def compound_answer(question, answers)
    selected_answer = ""

    ## チェックボックスの時
    if question.pattern_cd == Settings.QUESTION_PATTERNCD_CHECK
      if answers && answers[question.id.to_s]
        selected_answer = ""
        answers[question.id.to_s].each do |answer|
          selected_answer += answer.select_quiz.content.html_safe + "<br />".html_safe
        end
      end

    ## 記述の時
    elsif question.pattern_cd == Settings.QUESTION_PATTERNCD_ESSAY
      if answers && answers[question.id.to_s]
        selected_answer = simple_format(answers[question.id.to_s].text_answer)
      end

    ## ラジオボタンの時
    ## リストボックスの時
    else
      if answers && answers[question.id.to_s]
        selected_answer = answers[question.id.to_s].select_quiz.content if answers[question.id.to_s] && answers[question.id.to_s].select_quiz
      end
    end

    selected_answer.html_safe
  end

  def compound_answer_correct?(question, answers)
    if question.pattern_cd == Settings.QUESTION_PATTERNCD_CHECK
      if answers && answers[question.id.to_s] && answers[question.id.to_s][0]
        return true if answers[question.id.to_s][0].score > 0
      end
    else
      if answers && answers[question.id.to_s]
        return true if answers[question.id.to_s].score > 0
      end
    end
    false
  end

  def compound_answer_score(question, answers)
    if question.pattern_cd == Settings.QUESTION_PATTERNCD_CHECK
      if answers && answers[question.id.to_s] && answers[question.id.to_s][0]
        return answers[question.id.to_s][0].score
      end
    else
      if answers && answers[question.id.to_s]
        return answers[question.id.to_s].score
      end
    end
  end

  def compound_answer_self_score(question, answers)
    if question.pattern_cd == Settings.QUESTION_PATTERNCD_CHECK
      if answers && answers[question.id.to_s] && answers[question.id.to_s][0]
        return answers[question.id.to_s][0].self_score
      end
    else
      if answers && answers[question.id.to_s]
        return answers[question.id.to_s].self_score
      end
    end
  end

  def can_display_correct_answer?(generic_page, latest_score)
    if generic_page.correct_answer_display_flag == 1 
      return true if @generic_page.passed?(current_user.id) || generic_page.max_count <= latest_score.answer_count
    end

    false
  end

end
