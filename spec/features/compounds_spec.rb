require 'rails_helper'

RSpec.feature "Compounds", type: :feature do
  let(:student) { create(:student_user) }

  describe "複合テスト実施", js: true do
    before do
      User.current_user = student
      @course = create(:course, :year_of_2019)
      @class_session_no = 2
      @class_session = create(:class_session, course_id: @course.id, class_session_no: @class_session_no)
      create(:course_enrollment_user, course_id: @course.id, user_id: student.id)
    end

    context '未受験' do
      scenario "期限前" do
        @compound = create(:compound, course_id: @course.id, start_time: Time.new + 1.day)
        create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @compound.id)

        act_as student do
          #複合テストページ
          visit compound_path(@compound)

          expect(page.html.strip).to have_content ApplicationController.helpers.strip_tags(
            I18n.t("execution.MAT_EXE_MUL_ERROREXECUTEMULTIPLEFIB_NOTREADYSTARTTIME_html", :param0 => I18n.l(@compound.start_time)))
        end
      end

      scenario "期限終了", js: true do
        @compound = create(:compound, course_id: @course.id, end_time: Time.new - 1.day)
        create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @compound.id)

        act_as student do
          #複合テストページ
          visit compound_path(@compound)

          expect(page.html.strip).to have_content ApplicationController.helpers.strip_tags(
            I18n.t("execution.MAT_EXE_MUL_ERROREXECUTEMULTIPLEFIB_ALREADYPASSEDENDTIME_html", :param0 => I18n.l(@compound.end_time)))
        end
      end

      context '有効期間内' do
        scenario "設問なし", js: true do
          @compound = create(:compound, course_id: @course.id, start_time: Time.new - 1.day, end_time: Time.new + 1.day)
          create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @compound.id)

          act_as student do
              #複合テストページ
              visit compound_path(@compound)

            expect(page).to have_content I18n.t("execution.MAT_EXE_MUL_EXECUTEMULTIPLEFIBMAIN_NOTFOUND")
          end
        end

        context "開始パスワード有り" do
          before do
            @compound = create(:compound, course_id: @course.id, start_time: Time.new - 1.day, end_time: Time.new + 1.day, start_pass: "12345")
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @compound.id)
              @parent_question = create(:parent_question)
            @compound.questions << @parent_question
            create(:question, parent_question_id: @parent_question.id, generic_page_type_cd: @compound.type_cd, 
              quizzes_attributes: {
                "1" => { 'content' => "選択肢1-1", 'select_correct_flag' => "1" },
                "2" => { 'content' => "選択肢1-2", 'select_correct_flag' => "0" },
                "3" => { 'content' => "選択肢1-3", 'select_correct_flag' => "0" },
                "4" => { 'content' => "選択肢1-4", 'select_correct_flag' => "0" }
              }
            )
            create(:question, parent_question_id: @parent_question.id, generic_page_type_cd: @compound.type_cd, 
              quizzes_attributes: {
                "1" => { 'content' => "選択肢2-1", 'select_correct_flag' => "0" },
                "2" => { 'content' => "選択肢2-2", 'select_correct_flag' => "1" },
                "3" => { 'content' => "選択肢2-3", 'select_correct_flag' => "0" },
                "4" => { 'content' => "選択肢2-4", 'select_correct_flag' => "0" }
              }
            )
            create(:question, parent_question_id: @parent_question.id, generic_page_type_cd: @compound.type_cd, 
              quizzes_attributes: {
                "1" => { 'content' => "選択肢3-1", 'select_correct_flag' => "0" },
                "2" => { 'content' => "選択肢3-2", 'select_correct_flag' => "0" },
                "3" => { 'content' => "選択肢3-3", 'select_correct_flag' => "1" },
                "4" => { 'content' => "選択肢3-4", 'select_correct_flag' => "0" }
              }
            )
          end

          scenario "合格" do
            act_as student do
              #複合テストページ
              visit compound_path(@compound)

              #パスワード空値
              fill_in 'start_pass', with: ""
              click_button I18n.t('execution.COMMONMATERIALSEXECUTION_ATTESTATION')
              expect(page).to have_content I18n.t("execution.COMMONMATERIALSEXECUTION_STARTPASSWORDCHECK1")

              #パスワード誤り
              fill_in 'start_pass', with: "xxxxxxxx"
              click_button I18n.t('execution.COMMONMATERIALSEXECUTION_ATTESTATION')
              expect(page).to have_content I18n.t("execution.COMMONMATERIALSEXECUTION_STARTPASSWORDCHECK2")

              #パスワード一致
              fill_in 'start_pass', with: @compound.start_pass
              click_button I18n.t('execution.COMMONMATERIALSEXECUTION_ATTESTATION')
              expect(page).to have_content I18n.t("common.COMMON_CONFIRM")

              #確認画面へ
              value = "answers_" + @parent_question.questions[0].id.to_s + "_select_answer_id_" + @parent_question.questions[0].select_quizzes[0].id.to_s
              find_by_id(value).click
              value = "answers_" + @parent_question.questions[1].id.to_s + "_select_answer_id_" + @parent_question.questions[1].select_quizzes[1].id.to_s
              find_by_id(value).click
              value = "answers_" + @parent_question.questions[2].id.to_s + "_select_answer_id_" + @parent_question.questions[2].select_quizzes[3].id.to_s
              find_by_id(value).click
              find_by_id("submit_execution").click
              expect(page).to have_content I18n.t("execution.MAT_EXE_COM_EXECUTECOMPOUND_CHANGE")

              #入力画面へ戻る（回答を変更する）
              click_link I18n.t('execution.MAT_EXE_COM_EXECUTECOMPOUND_CHANGE')
              expect(page).to have_content I18n.t("common.COMMON_CONFIRM")

              #確認画面へ
              value = "answers_" + @parent_question.questions[2].id.to_s + "_select_answer_id_" + @parent_question.questions[2].select_quizzes[2].id.to_s
              find_by_id(value).click
              find_by_id("submit_execution").click
              expect(page).to have_content I18n.t("execution.MAT_EXE_COM_EXECUTECOMPOUND_CHANGE")

              #登録＆合格
              page.accept_confirm(I18n.t("execution.MAT_EXE_COM_EXECUTECOMPOUND_JAVASCRIPT1")) {
                find("input[type=submit").click
              }
              expect(page).to have_content ApplicationController.helpers.strip_tags(I18n.t("execution.MAT_EXE_COM_GRADEEXECUTECOMPOUND_PASS_html"))
            end
          end

          scenario "不合格" do
            act_as student do
              #複合テストページ
              visit compound_path(@compound)

              #パスワード一致
              fill_in 'start_pass', with: @compound.start_pass
              click_button I18n.t('execution.COMMONMATERIALSEXECUTION_ATTESTATION')
              expect(page).to have_content I18n.t("common.COMMON_CONFIRM")

              #確認画面へ
              value = "answers_" + @parent_question.questions[0].id.to_s + "_select_answer_id_" + @parent_question.questions[0].select_quizzes[0].id.to_s
              find_by_id(value).click
              value = "answers_" + @parent_question.questions[1].id.to_s + "_select_answer_id_" + @parent_question.questions[1].select_quizzes[2].id.to_s
              find_by_id(value).click
              value = "answers_" + @parent_question.questions[2].id.to_s + "_select_answer_id_" + @parent_question.questions[2].select_quizzes[3].id.to_s
              find_by_id(value).click
              find_by_id("submit_execution").click
              expect(page).to have_content I18n.t("execution.MAT_EXE_COM_EXECUTECOMPOUND_CHANGE")

              #登録＆不合格
              page.accept_confirm(I18n.t("execution.MAT_EXE_COM_EXECUTECOMPOUND_JAVASCRIPT1")) {
                find("input[type=submit").click
              }
              expect(page).to have_content ApplicationController.helpers.strip_tags(I18n.t("execution.MAT_EXE_COM_GRADEEXECUTECOMPOUND_NOTPASS_html"))
            end
          end

          scenario "一時保存後、合格" do
            act_as student do
              #複合テストページ
              visit compound_path(@compound)

              #パスワード一致
              fill_in 'start_pass', with: @compound.start_pass
              click_button I18n.t('execution.COMMONMATERIALSEXECUTION_ATTESTATION')
              expect(page).to have_content I18n.t("common.COMMON_CONFIRM")

              #一時保存
              value = "answers_" + @parent_question.questions[0].id.to_s + "_select_answer_id_" + @parent_question.questions[0].select_quizzes[0].id.to_s
              find_by_id(value).click
              value = "answers_" + @parent_question.questions[1].id.to_s + "_select_answer_id_" + @parent_question.questions[1].select_quizzes[1].id.to_s
              find_by_id(value).click
              value = "answers_" + @parent_question.questions[2].id.to_s + "_select_answer_id_" + @parent_question.questions[2].select_quizzes[2].id.to_s
              find_by_id(value).click
              first("input[type=submit]").click
              expect(page).to have_content I18n.t("execution.COMMONMATERIALSEXECUTION_TEMP_SAVE_SUCCESS")

              #ログアウト
              logout

              #ログイン
              login student

              #複合テストページ
              visit compound_path(@compound)

              #パスワード一致
              fill_in 'start_pass', with: @compound.start_pass
              click_button I18n.t('execution.COMMONMATERIALSEXECUTION_ATTESTATION')
              expect(page).to have_content I18n.t("common.COMMON_CONFIRM")

              #確認画面へ
              find_by_id("submit_execution").click
              expect(page).to have_content I18n.t("execution.MAT_EXE_COM_EXECUTECOMPOUND_CHANGE")

              #登録＆合格
              page.accept_confirm(I18n.t("execution.MAT_EXE_COM_EXECUTECOMPOUND_JAVASCRIPT1")) {
                find("input[type=submit").click
              }
              expect(page).to have_content ApplicationController.helpers.strip_tags(I18n.t("execution.MAT_EXE_COM_GRADEEXECUTECOMPOUND_PASS_html"))
            end
          end

          scenario '登録時：期限切れ' do
            act_as student do
              #複合テストページ
              visit compound_path(@compound)

              #パスワード一致
              fill_in 'start_pass', with: @compound.start_pass
              click_button I18n.t('execution.COMMONMATERIALSEXECUTION_ATTESTATION')
              expect(page).to have_content I18n.t("common.COMMON_CONFIRM")

              #確認画面へ
              value = "answers_" + @parent_question.questions[0].id.to_s + "_select_answer_id_" + @parent_question.questions[0].select_quizzes[0].id.to_s
              find_by_id(value).click
              value = "answers_" + @parent_question.questions[1].id.to_s + "_select_answer_id_" + @parent_question.questions[1].select_quizzes[1].id.to_s
              find_by_id(value).click
              value = "answers_" + @parent_question.questions[2].id.to_s + "_select_answer_id_" + @parent_question.questions[2].select_quizzes[2].id.to_s
              find_by_id(value).click
              find_by_id("submit_execution").click
              expect(page).to have_content I18n.t("execution.MAT_EXE_COM_EXECUTECOMPOUND_CHANGE")

              #期限切れに設定
              @compound.end_time = Time.new - 1.day
              @compound.save

              #登録＆期限切れエラー
              page.accept_confirm(I18n.t("execution.MAT_EXE_COM_EXECUTECOMPOUND_JAVASCRIPT1")) {
                find("input[type=submit").click
              }

              expect(page.html.strip).to have_content ApplicationController.helpers.strip_tags(
                I18n.t("execution.MAT_EXE_MUL_ERROREXECUTEMULTIPLEFIB_ALREADYPASSEDENDTIME_html", :param0 => I18n.l(@compound.end_time)))
            end
          end
        end
      end
    end

    context '受験済み' do
      before do
        @compound = create(:compound, course_id: @course.id, end_time: Time.new - 1.day)
        @parent_question = create(:parent_question)
        @compound.questions << @parent_question
        create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @compound.id)
      end

      context '1回受験済み：期限終了：最大受験回数１回' do
        before do
          #設問（ラジオボタンのみ）
          create_list(:question, 3, parent_question_id: @parent_question.id, generic_page_type_cd: @compound.type_cd, 
            quizzes_attributes: {
              "1" => { 'content' => "選択肢１", 'select_correct_flag' => "0" },
              "2" => { 'content' => "選択肢２", 'select_correct_flag' => "0" },
              "3" => { 'content' => "選択肢３", 'select_correct_flag' => "0" },
              "4" => { 'content' => "選択肢４", 'select_correct_flag' => "1" }
            }
          )
        end

        scenario '合格' do
          create(:passed_answer_score, page_id:@compound.id, user_id: student.id)

          act_as student do
            #複合テストページ
            visit compound_path(@compound)

            expect(page.html.strip).to have_content ApplicationController.helpers.strip_tags(
              I18n.t("execution.MAT_EXE_MUL_ERROREXECUTEMULTIPLEFIB_ALREADYPASSEDENDTIME_html", :param0 => I18n.l(@compound.end_time))
            )
          end
        end

        scenario '不合格' do
          create(:failed_answer_score, page_id:@compound.id, user_id: student.id)

          act_as student do
            #複合テストページ
            visit compound_path(@compound)

            expect(page.html.strip).to have_content ApplicationController.helpers.strip_tags(
              I18n.t("execution.MAT_EXE_MUL_ERROREXECUTEMULTIPLEFIB_ALREADYPASSEDENDTIME_html", :param0 => I18n.l(@compound.end_time))
            )
          end
        end
      end

    end
  end
end