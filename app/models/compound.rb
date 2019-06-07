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

class Compound < GenericPage
  ## 設問構成コード
	#** 設問なし * *#
	QUESTIONCOMPOSITIONCD_NOTHING = 0
	#** 選択式のみ * *#
	QUESTIONCOMPOSITIONCD_MULTIPLEONLY = 1
	#** 記述式のみ * *#
	QUESTIONCOMPOSITIONCD_ESSAYONLY = 2
	#** 複合式 * *#
	QUESTIONCOMPOSITIONCD_COMPOUND = 3

  def get_question_composition
    result = Compound::QUESTIONCOMPOSITIONCD_NOTHING
    has_multiple = false
    has_essay = false

    ## 大問のリストを取得
    self.parent_questions.each do |parent|
      parent.questions.each do |question|
        case question.pattern_cd
        when Settings.QUESTION_PATTERNCD_ESSAY
          ## 記述式の設問があればtrue
          has_essay = true

        when Settings.QUESTION_PATTERNCD_RADIO, Settings.QUESTION_PATTERNCD_ONELIST, Settings.QUESTION_PATTERNCD_CHECK
          ## 選択式の設問があればtrue
          has_multiple = true
        end
      end
    end

    if has_multiple && has_essay
      ## 選択式＆記述式
      result = QUESTIONCOMPOSITIONCD_COMPOUND

    elsif has_multiple && !has_essay
      ## 選択式のみ
      result = QUESTIONCOMPOSITIONCD_MULTIPLEONLY

    elsif !has_multiple && has_essay
      ## 記述式のみ
      result = QUESTIONCOMPOSITIONCD_ESSAYONLY
    end

    return result
  end
end
