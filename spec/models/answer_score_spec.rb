require 'rails_helper'

RSpec.describe AnswerScore, type: :model do
  let(:student) { create(:student_user) }
  let(:no_ext_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', 'test'), 'text/txt') }
  let(:exe_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', 'test.exe'), 'text/txt') }
  let(:size_0_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', 'file_size_0.txt'), 'text/txt') }
  let(:test_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', 'test.txt'), 'text/txt') }

  before do
    User.current_user = student
    @course = create(:course, :year_of_2019)
  end

  describe 'レポート' do
    before do
      @essay = create(:essay, course_id: @course.id)
    end

    context 'バリデーション' do
      before do
        @answer_score = build(:answer_score, page_id: @essay.id, user_id: student.id)
      end

      it "ファイル" do
        #ファイルなし
        @answer_score.file = nil
        @answer_score.valid?
        expect(@answer_score.errors.messages[:file_name]).to include I18n.t("execution.MAT_EXE_ASS_EXECUTEASSIGNMENTESSAY_ERRORTYPE1")

        #拡張子なし
        @answer_score.file = no_ext_file
        @answer_score.valid?
        expect(@answer_score.errors.messages[:file_name]).to include I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE3")

        #拡張子exe
        @answer_score.file = exe_file
        @answer_score.valid?
        expect(@answer_score.errors.messages[:file_name]).to include I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE8")

        #size 0
        @answer_score.file = size_0_file
        @answer_score.valid?
        expect(@answer_score.errors.messages[:base]).to include I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE19")
      end

      it "正常" do
        @answer_score.file = test_file
        @answer_score.valid?
        expect(@answer_score.errors.count).to eq 0
        expect(@answer_score).to be_valid
      end
    end

    context '保存' do
      it '新規登録' do
        answer_score = build(:answer_score, user_id: student.id, file: test_file)
        answer_score.generic_page = @essay

        expect{
          answer_score.save
        }.to change(AnswerScore, :count).by(1)

        histories = AnswerScoreHistory.where(answer_score_id: answer_score.id).order('answer_count DESC')

        expect(histories.count).to eq 1

        expect(histories[0].total_score).to eq answer_score.total_score
        expect(histories[0].total_raw_score).to eq answer_score.total_raw_score
        expect(histories[0].self_total_score).to eq answer_score.self_total_score
        expect(histories[0].assignment_essay_score).to eq answer_score.assignment_essay_score
        expect(histories[0].pass_cd).to eq answer_score.pass_cd
        expect(histories[0].file_name).to eq answer_score.file_name
        expect(histories[0].link_name).to eq answer_score.link_name
        expect(histories[0].file_size).to eq answer_score.file_size
      end

      context '更新' do
        before do
          @answer_score = create(:answer_score, page_id: @essay.id, user_id: student.id, file: test_file)
        end

        it 'answer_count変更なし' do
          @answer_score.total_score = 99
          @answer_score.total_raw_score = 88

          expect{
            @answer_score.save
          }.to change(AnswerScore, :count).by(0)

          histories = AnswerScoreHistory.where(answer_score_id: @answer_score.id).order('answer_count DESC')

          expect(histories.count).to eq 1
  
          expect(histories[0].total_score).to eq @answer_score.total_score
          expect(histories[0].total_raw_score).to eq @answer_score.total_raw_score
          expect(histories[0].self_total_score).to eq @answer_score.self_total_score
          expect(histories[0].assignment_essay_score).to eq @answer_score.assignment_essay_score
          expect(histories[0].pass_cd).to eq @answer_score.pass_cd
          expect(histories[0].file_name).to eq @answer_score.file_name
          expect(histories[0].link_name).to eq @answer_score.link_name
          expect(histories[0].file_size).to eq @answer_score.file_size
        end

        it 'answer_count変更あり' do
          @answer_score.answer_count = @answer_score.answer_count + 1
          @answer_score.total_score = 99
          @answer_score.total_raw_score = 88

          expect{
            @answer_score.save
          }.to change(AnswerScore, :count).by(0)
          
          histories = AnswerScoreHistory.where(answer_score_id: @answer_score.id).order('answer_count DESC')

          expect(histories.count).to eq 2
  
          expect(histories[0].total_score).to eq @answer_score.total_score
          expect(histories[0].total_raw_score).to eq @answer_score.total_raw_score
          expect(histories[0].self_total_score).to eq @answer_score.self_total_score
          expect(histories[0].assignment_essay_score).to eq @answer_score.assignment_essay_score
          expect(histories[0].pass_cd).to eq @answer_score.pass_cd
          expect(histories[0].file_name).to eq @answer_score.file_name
          expect(histories[0].link_name).to eq @answer_score.link_name
          expect(histories[0].file_size).to eq @answer_score.file_size

          expect(histories[1].total_score).to_not eq @answer_score.total_score
          expect(histories[1].total_raw_score).to_not eq @answer_score.total_raw_score
        end
      end
    end
  end

  describe 'レポート以外' do
    before do
      @compound = create(:compound, course_id: @course.id)
    end
    
    context 'バリデーション' do
      before do
        @answer_score = build(:answer_score, page_id: @compound.id, user_id: student.id)
      end
  
      it "正常" do
        @answer_score.valid?
        expect(@answer_score.errors.count).to eq 0
        expect(@answer_score).to be_valid

        @answer_score.file = test_file
        @answer_score.valid?
        expect(@answer_score.errors.count).to eq 0
        expect(@answer_score).to be_valid
      end
    end
  end

end