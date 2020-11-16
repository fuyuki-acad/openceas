require 'rails_helper'

RSpec.describe Answer, type: :model do
  let(:student) { create(:student_user) }

  before do
    User.current_user = student
    @course = create(:course, :year_of_2019)
    @questionnaire = create(:questionnaire, course_id: @course.id)
    @parent_question = create(:parent_question)
    @parent_question.generic_pages << @questionnaire
  end

  context 'バリデーション' do
    context '記述' do
      before do
        @question = create(:questionnaire_question, parent_question_id: @parent_question.id, generic_page_type_cd: Settings.GENERICPAGE_TYPECD_QUESTIONNAIRECODE,
          pattern_cd: Settings.QUESTION_PATTERNCD_ESSAY, must_flag: Settings.QUESTION_MUSTFLG_MUST)
        @answer = build(:answer, question_id: @question.id, user_id: student.id, answer_count: 1)
      end

      it "必須あり：エラー" do
        @answer.text_answer = nil
        @answer.select_answer_id = nil
        @answer.valid?
        expect(@answer.errors.messages[:base]).to include '"' + @question.content.html_safe + '"' + I18n.t("execution.MAT_EXE_QUE_EXECUTEQUESTIONNAIRE_ERROR1")
      end

      it "必須あり：正常" do
        @answer.text_answer = "回答"
        @answer.select_answer_id = nil
        @answer.valid?
        expect(@answer.errors.count).to eq 0
        expect(@answer).to be_valid
      end

      it "必須なし：正常" do
        @question.must_flag = Settings.QUESTION_MUSTFLG_OPTIONAL
        @question.save

        @answer.text_answer = nil
        @answer.select_answer_id = nil
        @answer.valid?
        expect(@answer.errors.count).to eq 0
        expect(@answer).to be_valid
      end
    end

    context '設問タイプ：単一選択(LIST)' do
      before do
        @question = create(:questionnaire_question, parent_question_id: @parent_question.id, generic_page_type_cd: Settings.GENERICPAGE_TYPECD_QUESTIONNAIRECODE,
          pattern_cd: Settings.QUESTION_PATTERNCD_CHECK, must_flag: Settings.QUESTION_MUSTFLG_MUST)
        @answer = build(:answer, question_id: @question.id, user_id: student.id, answer_count: 1)
      end

      it "正常" do
        @answer.text_answer = nil
        @answer.select_answer_id = nil
        @answer.valid?
        expect(@answer.errors.count).to eq 0
        expect(@answer).to be_valid
      end
    end

    context '設問タイプ：単一選択(RADIO)' do
      before do
        @question = create(:questionnaire_question, parent_question_id: @parent_question.id, generic_page_type_cd: Settings.GENERICPAGE_TYPECD_QUESTIONNAIRECODE,
          pattern_cd: Settings.QUESTION_PATTERNCD_RADIO, must_flag: Settings.QUESTION_MUSTFLG_MUST)
        @answer = build(:answer, question_id: @question.id, user_id: student.id, answer_count: 1)
      end

      it "必須あり：エラー" do
        @answer.text_answer = nil
        @answer.select_answer_id = nil
        @answer.valid?
        expect(@answer.errors.messages[:base]).to include '"' + @question.content.html_safe + '"' + I18n.t("execution.MAT_EXE_QUE_EXECUTEQUESTIONNAIRE_ERROR1")
      end

      it "必須あり：正常" do
        @answer.text_answer = nil
        @answer.select_answer_id = 1
        @answer.valid?
        expect(@answer.errors.count).to eq 0
        expect(@answer).to be_valid
      end

      it "必須なし：正常" do
        @question.must_flag = Settings.QUESTION_MUSTFLG_OPTIONAL
        @question.save

        @answer.text_answer = nil
        @answer.select_answer_id = nil
        @answer.valid?
        expect(@answer.errors.count).to eq 0
        expect(@answer).to be_valid
      end
    end
  end

  context '保存' do
    it '新規登録' do
      @question = create(:questionnaire_question, parent_question_id: @parent_question.id, generic_page_type_cd: Settings.GENERICPAGE_TYPECD_QUESTIONNAIRECODE,
        pattern_cd: Settings.QUESTION_PATTERNCD_ESSAY)
      @answer = build(:answer, question_id: @question.id, user_id: student.id, answer_count: 1, select_answer_id: 0)

      expect{
        @answer.save
      }.to change(Answer, :count).by(1)

      histories = AnswerHistory.where(answer_id: @answer.id).order('answer_count DESC')

      expect(histories.count).to eq 1

      expect(histories[0].select_answer_id).to eq @answer.select_answer_id
      expect(histories[0].text_answer).to eq @answer.text_answer
      expect(histories[0].self_score).to eq @answer.self_score
    end

    context '更新' do
      before do
        @question = create(:questionnaire_question, parent_question_id: @parent_question.id, generic_page_type_cd: Settings.GENERICPAGE_TYPECD_QUESTIONNAIRECODE,
          pattern_cd: Settings.QUESTION_PATTERNCD_ESSAY)
        @answer = create(:answer, question_id: @question.id, user_id: student.id, answer_count: 1, select_answer_id: 0)
        end

      it 'answer_count変更なし' do
        @answer.select_answer_id = 99
        @answer.text_answer = "update text"

        expect{
          @answer.save
        }.to change(Answer, :count).by(0)

        histories = AnswerHistory.where(answer_id: @answer.id).order('answer_count DESC')

        expect(histories.count).to eq 1

        expect(histories[0].select_answer_id).to eq @answer.select_answer_id
        expect(histories[0].text_answer).to eq @answer.text_answer
        expect(histories[0].self_score).to eq @answer.self_score
        end

      it 'answer_count変更あり' do
        @answer.answer_count = @answer.answer_count + 1
        @answer.select_answer_id = 99
        @answer.text_answer = "update text"

        expect{
          @answer.save
        }.to change(Answer, :count).by(0)
        
        histories = AnswerHistory.where(answer_id: @answer.id).order('answer_count DESC')

        expect(histories.count).to eq 2

        expect(histories[0].select_answer_id).to eq @answer.select_answer_id
        expect(histories[0].text_answer).to eq @answer.text_answer
        expect(histories[0].self_score).to eq @answer.self_score
  
        expect(histories[1].select_answer_id).to_not eq @answer.select_answer_id
        expect(histories[1].text_answer).to_not eq @answer.text_answer
      end
    end
  end

end