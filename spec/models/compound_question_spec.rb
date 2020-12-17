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

require 'rails_helper'

RSpec.describe Question, type: :model do
  before do
    User.current_user = create(:teacher_user)
    @course = create(:course, :year_of_2019)
    @compound = build(:compound, course_id: @course.id)
  end

  describe '大問' do
    context 'バリデーション' do
      before do
        @parent_question = build(:parent_question)
      end

      it "正常" do
        @parent_question.valid?
        expect(@parent_question.errors.count).to eq 0
        expect(@parent_question).to be_valid
      end

      it "記述部" do
        @parent_question.content = nil
        @parent_question.valid?
        expect(@parent_question.errors.messages[:base]).to include I18n.t("materials_registration.MAT_REG_REGISTERPARENTQUESTION_ERROR1")
      end
    end
  end

  describe '設問' do
    context 'バリデーション' do
      context '設問タイプ：単一選択(RADIO)' do
        before do
          @question = build(:question, generic_page_type_cd: Settings.GENERICPAGE_TYPECD_COMPOUNDCODE,
            pattern_cd: Settings.QUESTION_PATTERNCD_RADIO,
            quizzes_attributes: {
              "1" => { "content" => "選択肢１", 'select_correct_flag' => "0" },
              "2" => { "content" => "選択肢２", 'select_correct_flag' => "0" },
              "3" => { "content" => "選択肢３", 'select_correct_flag' => "0" },
              "4" => { "content" => "選択肢４", 'select_correct_flag' => "1" }
            })
        end

        it "正常" do
          @question.valid?
          expect(@question.errors.count).to eq 0
          expect(@question).to be_valid
        end

        it "設問文" do
          @question.content = nil
          @question.valid?
          expect(@question.errors.messages[:base]).to include I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_ERROR4")
        end

        it "選択肢" do
          #選択肢なし
          @question.quizzes_attributes = {}
          @question.valid?
          expect(@question.errors.messages[:base]).to include I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_ERROR3")

          #選択肢文言なし
          @question.quizzes_attributes = {
            "1" => { "content" => "", 'select_correct_flag' => "1" },
            "2" => { "content" => "選択肢２", 'select_correct_flag' => "0" },
            "3" => { "content" => "選択肢３", 'select_correct_flag' => "0" },
            "4" => { "content" => "選択肢４", 'select_correct_flag' => "0" }
          }
          @question.valid?
          expect(@question.errors.messages[:base]).to include I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_ERROR6")

          #正答なし
          @question.quizzes_attributes = {
            "1" => { "content" => "選択肢１", 'select_correct_flag' => "0" },
            "2" => { "content" => "選択肢２", 'select_correct_flag' => "0" },
            "3" => { "content" => "選択肢３", 'select_correct_flag' => "0" },
            "4" => { "content" => "選択肢４", 'select_correct_flag' => "0" }
          }
          @question.valid?
          expect(@question.errors.messages[:base]).to include I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_ERROR3")

          #複数正答
          @question.quizzes_attributes = {
            "1" => { "content" => "選択肢１", 'select_correct_flag' => "1" },
            "2" => { "content" => "選択肢２", 'select_correct_flag' => "1" },
            "3" => { "content" => "選択肢３", 'select_correct_flag' => "0" },
            "4" => { "content" => "選択肢４", 'select_correct_flag' => "0" }
          }
          @question.valid?
          expect(@question.errors.messages[:base]).to include I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_ERROR2")
        end
      end

      context '設問タイプ：単一選択(LIST)' do
        before do
          @question = build(:question, generic_page_type_cd: Settings.GENERICPAGE_TYPECD_COMPOUNDCODE,
            pattern_cd: Settings.QUESTION_PATTERNCD_ONELIST,
            quizzes_attributes: {
              "1" => { "content" => "選択肢１", 'select_correct_flag' => "0" },
              "2" => { "content" => "選択肢２", 'select_correct_flag' => "0" },
              "3" => { "content" => "選択肢３", 'select_correct_flag' => "0" },
              "4" => { "content" => "選択肢４", 'select_correct_flag' => "1" }
            })
        end

        it "正常" do
          @question.valid?
          expect(@question.errors.count).to eq 0
          expect(@question).to be_valid
        end

        it "設問文" do
          @question.content = nil
          @question.valid?
          expect(@question.errors.messages[:base]).to include I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_ERROR4")
        end

        it "選択肢" do
          #選択肢なし
          @question.quizzes_attributes = {}
          @question.valid?
          expect(@question.errors.messages[:base]).to include I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_ERROR3")

          #選択肢文言なし
          @question.quizzes_attributes = {
            "1" => { "content" => "", 'select_correct_flag' => "1" },
            "2" => { "content" => "選択肢２", 'select_correct_flag' => "0" },
            "3" => { "content" => "選択肢３", 'select_correct_flag' => "0" },
            "4" => { "content" => "選択肢４", 'select_correct_flag' => "0" }
          }
          @question.valid?
          expect(@question.errors.messages[:base]).to include I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_ERROR6")

          #正答なし
          @question.quizzes_attributes = {
            "1" => { "content" => "選択肢１", 'select_correct_flag' => "0" },
            "2" => { "content" => "選択肢２", 'select_correct_flag' => "0" },
            "3" => { "content" => "選択肢３", 'select_correct_flag' => "0" },
            "4" => { "content" => "選択肢４", 'select_correct_flag' => "0" }
          }
          @question.valid?
          expect(@question.errors.messages[:base]).to include I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_ERROR3")

          #複数正答
          @question.quizzes_attributes = {
            "1" => { "content" => "選択肢１", 'select_correct_flag' => "1" },
            "2" => { "content" => "選択肢２", 'select_correct_flag' => "1" },
            "3" => { "content" => "選択肢３", 'select_correct_flag' => "0" },
            "4" => { "content" => "選択肢４", 'select_correct_flag' => "0" }
          }
          @question.valid?
          expect(@question.errors.messages[:base]).to include I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_ERROR2")
        end
      end

      context '設問タイプ：複数選択' do
        before do
          @question = build(:question, generic_page_type_cd: Settings.GENERICPAGE_TYPECD_COMPOUNDCODE,
            pattern_cd: Settings.QUESTION_PATTERNCD_CHECK,
            quizzes_attributes: {
              "1" => { "content" => "選択肢１", 'select_correct_flag' => "0" },
              "2" => { "content" => "選択肢２", 'select_correct_flag' => "1" },
              "3" => { "content" => "選択肢３", 'select_correct_flag' => "0" },
              "4" => { "content" => "選択肢４", 'select_correct_flag' => "1" }
            })
        end

        it "正常" do
          @question.valid?
          expect(@question.errors.count).to eq 0
          expect(@question).to be_valid
        end

        it "設問文" do
          @question.content = nil
          @question.valid?
          expect(@question.errors.messages[:base]).to include I18n.t("common.COMMON_CONTENTCHECK")
        end

        it "選択肢" do
          #選択肢なし
          @question.quizzes_attributes = {}
          @question.valid?
          expect(@question.errors.messages[:base]).to include I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_ERROR3")

          #選択肢文言なし
          @question.quizzes_attributes = {
            "1" => { "content" => "", 'select_correct_flag' => "1" },
            "2" => { "content" => "選択肢２", 'select_correct_flag' => "0" },
            "3" => { "content" => "選択肢３", 'select_correct_flag' => "0" },
            "4" => { "content" => "選択肢４", 'select_correct_flag' => "0" }
          }
          @question.valid?
          expect(@question.errors.messages[:base]).to include I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_ERROR6")

          #正答なし
          @question.quizzes_attributes = {
            "1" => { "content" => "選択肢１", 'select_correct_flag' => "0" },
            "2" => { "content" => "選択肢２", 'select_correct_flag' => "0" },
            "3" => { "content" => "選択肢３", 'select_correct_flag' => "0" },
            "4" => { "content" => "選択肢４", 'select_correct_flag' => "0" }
          }
          @question.valid?
          expect(@question.errors.messages[:base]).to include I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_ERROR3")
        end
      end

      context '設問タイプ：記述' do
        before do
          parent_question = create(:parent_question)
          parent_question.generic_pages << @compound
          @question = build(:question, parent_question_id: parent_question.id, generic_page_type_cd: Settings.GENERICPAGE_TYPECD_COMPOUNDCODE,
            pattern_cd: Settings.QUESTION_PATTERNCD_ESSAY)
        end

        it "正常" do
          @question.valid?
          expect(@question.errors.count).to eq 0
          expect(@question).to be_valid
        end

        it "設問文" do
          @question.content = nil
          @question.valid?
          expect(@question.errors.messages[:base]).to include I18n.t("common.COMMON_CONTENTCHECK")
        end

        it "補足文" do
          @question.answer_memo = nil
          @question.valid?
          expect(@question.errors.messages[:base]).to include I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_ERROR5")
        end
      end
    end

    describe '登録' do
      before do
        parent_question = create(:parent_question)
        parent_question.generic_pages << @compound
        @question = build(:question, parent_question_id: parent_question.id, generic_page_type_cd: Settings.GENERICPAGE_TYPECD_COMPOUNDCODE,
          pattern_cd: Settings.QUESTION_PATTERNCD_ONELIST,
          quizzes_attributes: {
            "1" => { "content" => "選択肢１", 'select_correct_flag' => "0" },
            "2" => { "content" => "選択肢２", 'select_correct_flag' => "0" },
            "3" => { "content" => "選択肢３", 'select_correct_flag' => "0" },
            "4" => { "content" => "選択肢４", 'select_correct_flag' => "1" }
          })
      end

      it "新規登録" do
        expect{
          @question.save
        }.to change(Question, :count).by(1)

        expect(@question.all_quizzes.count).to eq 4
      end

      it '更新' do
        expect{
          @question.save
        }.to change(Question, :count).by(1)

        expect(@question.all_quizzes.count).to eq 4

        quizzes = {}
        @question.all_quizzes.each.with_index do |select_quiz, index|
          quizzes[index] = { id: select_quiz.id, "content" => select_quiz.content , 'select_correct_flag' => select_quiz.text_row }
        end
        @question.quizzes_attributes = quizzes

        expect{
          @question.save
        }.to change(Question, :count).by(0)

        expect(@question.all_quizzes.count).to eq 4
      end
    end
  end

end