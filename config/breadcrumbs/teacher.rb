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

#
# 授業資料
#
crumb :materials do
  link t("common.COMMON_COURSESELECT"), teacher_materials_path
  parent :root
end

crumb :material do |course|
  link t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_NAVI"), teacher_material_path(course)
  parent :materials, course
end

crumb :new_material do |course|
  link t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_MATERIALNEWWINDOW"), teacher_path(course)
  parent :material, course
end

crumb :edit_material do |material|
  link t("page_management.MAT_REG_MAT_EDITMATEIRAL_TITLE"), teacher_path(material.course, material)
  parent :material, material.course
end

crumb :select_course_material do |course|
  link t("common.COMMON_COURSESELECT"), teacher_select_course_material_path(course)
  parent :material, course
end

crumb :select_page_material do |course, origin|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLECOPY_MATERIAL"), teacher_select_page_material_path({:course_id => course.id, :origin_id => origin.id})
  parent :select_course_material, course
end

crumb :new_url_material do |material|
  link t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_URLNEWWINDOW"), teacher_new_url_material_path(material.course)
  parent :material, material.course
end

crumb :edit_url_material do |material|
  link t("page_management.MAT_REG_MAT_EDITURL_TITLE"), teacher_path(material)
  parent :material, material.course
end

crumb :select_url_course_material do |course|
  link t("common.COMMON_COURSESELECT"), teacher_select_url_course_material_path(course)
  parent :material, course
end

crumb :select_url_page_material do |course, origin|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLECOPY_MATERIAL"), teacher_select_url_page_material_path({:course_id => course.id, :origin_id => origin.id})
  parent :select_url_course_material, course
end


#
# 複合式テスト作成
#
crumb :compounds do
  link t("common.COMMON_COURSESELECT"), teacher_compounds_path
  parent :root
end

crumb :compound do |course|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEREGISTRATIONCOMPOUND"), teacher_compound_path(course)
  parent :compounds
end

crumb :new_compound do |course|
  link t("materials_registration.MAT_REG_COM_REGISTERCOMPOUND_NEWWINDOW"), teacher_new_compound_path(course)
  parent :compound, course
end

crumb :edit_compound do |compound|
  link t("materials_registration.MAT_REG_COM_REGISTERCOMPOUND_NEWWINDOW"), teacher_edit_compound_path(compound)
  parent :compound, compound.course
end

crumb :select_course_compound do |course|
  link t("common.COMMON_COURSESELECT"), teacher_select_course_compound_path(course)
  parent :compound, course
end

crumb :select_page_compound do |course, origin|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLECOPY_COMPOUND"), teacher_select_page_compound_path({:course_id => course.id, :origin_id => origin.id})
  parent :select_course_compound, course
end

crumb :select_upload_file_compound do |course|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEUPLOADMATERIALS"), teacher_select_upload_file_compound_path(course)
  parent :compound, course
end

crumb :confirm_upload_file_compound do |course|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEFILEUPLOAD"), teacher_confirm_upload_file_compound_path(course)
  parent :select_upload_file_compound, course
end

# 大問題
crumb :question do |generic_page|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_MAKEPARENTQUESTION"), teacher_question_path(generic_page)
  parent :compound, generic_page.course
end

# 設問
crumb :new_question do |generic_page, question|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_MAKEQUESTION"), teacher_new_question_path(generic_page, question)
  parent :question, generic_page
end

crumb :select_upload_question do |generic_page|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEUPLOADMATERIALS"), teacher_select_upload_question_path(generic_page)
  parent :question, generic_page
end

crumb :confirm_upload_question do |generic_page|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEFILEUPLOAD"), teacher_confirm_upload_question_path(generic_page)
  parent :select_upload_question, generic_page
end

crumb :finish_upload_question do |generic_page|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEFILEUPLOAD"), teacher_confirm_upload_question_path(generic_page)
  parent :select_upload_question, generic_page
end

#
# 記号入力式テスト作成
#
crumb :multiplefibs do
  link t("common.COMMON_COURSESELECT"), teacher_multiplefibs_path
  parent :root
end

crumb :multiplefib do |course|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEREGISTRATIONMULTIPLEFIB"), teacher_multiplefib_path(course)
  parent :multiplefibs, course
end

crumb :new_multiplefib do |course|
  link t("materials_registration.MAT_REG_MUL_REGISTERMULTIPLEFIB_NEWWINDOW"), teacher_new_multiplefib_path(course)
  parent :multiplefib, course
end

crumb :edit_multiplefib do |multiplefib|
  link t("materials_registration.MAT_REG_MUL_REGISTERMULTIPLEFIB_NEWWINDOW"), teacher_edit_multiplefib_path(multiplefib)
  parent :multiplefib, multiplefib.course
end

crumb :select_course_multiplefib do |course|
  link t("common.COMMON_COURSESELECT"), teacher_select_course_multiplefib_path(course)
  parent :multiplefib, course
end

crumb :select_page_multiplefib do |course, origin|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLECOPY_MULTIPLEFIB"), teacher_select_page_multiplefib_path({:course_id => course.id, :origin_id => origin.id})
  parent :select_course_multiplefib, course
end

crumb :select_upload_file_multiplefib do |course|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEUPLOADMATERIALS"), teacher_select_upload_file_multiplefib_path(course)
  parent :multiplefib, course
end

crumb :confirm_upload_file_multiplefib do |course|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEFILEUPLOAD"), teacher_confirm_upload_file_multiplefib_path(course)
  parent :select_upload_file_multiplefib, course
end

# 大問題
crumb :multiplefib_question do |generic_page|
  link t("materials_registration.MAT_REG_MUL_REGISTERMULTIPLEFIBQUESTIONHEADER_TITLE"), teacher_multiplefibs_question_path(generic_page)
  parent :multiplefib, generic_page.course
end

# 設問
crumb :new_multiplefib_question do |generic_page, question|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_MAKEQUESTION"), teacher_new_multiplefib_question_path(generic_page, question)
  parent :question, generic_page
end

#
# レポート課題作成
#
crumb :essays do
  link t("common.COMMON_COURSESELECT"), teacher_essays_path
  parent :root
end

crumb :essay do |course|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEREGISTRATIONASSIGNMENTESSAY"), teacher_essay_path(course)
  parent :essays
end

crumb :new_essay do |course|
  link t("materials_registration.MAT_REG_ASS_REGISTERASSIGNMENTESSAY_NEWWINDOW"), teacher_new_essay_path(course)
  parent :essay, course
end

crumb :edit_essay do |generic_page|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEREGISTRATIONASSIGNMENTESSAY") + t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEREGISTRATIONANDEDIT"), teacher_edit_essay_path(generic_page)
  parent :essay, generic_page.course
end

crumb :select_course_essay do |course|
  link t("common.COMMON_COURSESELECT"), teacher_select_course_essay_path(course)
  parent :essay, course
end

crumb :select_page_essay do |course, origin|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLECOPY_ASSIGNMENTESSAY"), teacher_select_page_essay_path({:course_id => course.id, :origin_id => origin.id})
  parent :select_course_essay, course
end

crumb :select_upload_file_essay do |course|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEUPLOADMATERIALS"), teacher_select_upload_file_essay_path(course)
  parent :essay, course
end

crumb :confirm_upload_file_essay do |course|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEFILEUPLOAD"), teacher_confirm_upload_file_essay_path(course)
  parent :select_upload_file_essay, course
end

# 課題
crumb :essay_question do |generic_page|
  link t("materials_registration.MAT_REG_ASS_REGISTERASSIGNMENT_REGISTERASSIGNMENT"), teacher_essay_question_path(generic_page)
  parent :essay, generic_page.course
end

#
# アンケート作成
#
crumb :questionnaires do
  link t("common.COMMON_COURSESELECT"), teacher_questionnaires_path
  parent :root
end

crumb :questionnaire do |course|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEREGISTRATIONQUESTIONNAIRE"), teacher_questionnaire_path(course)
  parent :questionnaires
end

crumb :new_questionnaire do |course|
  link t("materials_registration.MAT_REG_QUE_REGISTERQUESTIONNAIRE_NEWWINDOW"), teacher_new_questionnaire_path(course)
  parent :questionnaire, course
end

crumb :edit_questionnaire do |generic_page|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEREGISTRATIONQUESTIONNAIRE") + t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEREGISTRATIONANDEDIT"), teacher_edit_questionnaire_path(generic_page)
  parent :questionnaire, generic_page.course
end

crumb :select_course_questionnaire do |course|
  link t("common.COMMON_COURSESELECT"), teacher_select_course_questionnaire_path(course)
  parent :questionnaire, course
end

crumb :select_page_questionnaire do |course, origin|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLECOPY_QUESTIONNAIRE"), teacher_select_page_questionnaire_path({:course_id => course.id, :origin_id => origin.id})
  parent :select_course_questionnaire, course
end

crumb :select_upload_file_questionnaire do |course|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEUPLOADMATERIALS"), teacher_select_upload_file_questionnaire_path(course)
  parent :questionnaire, course
end

crumb :confirm_upload_file_questionnaire do |course|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEFILEUPLOAD"), teacher_confirm_upload_file_questionnaire_path(course)
  parent :select_upload_file_questionnaire, course
end

# 大問
crumb :questionnaire_question do |generic_page|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_MAKEPARENTQUESTION"), teacher_question_path(generic_page)
  parent :questionnaire, generic_page.course
end

# 設問
crumb :new_questionnaire_question do |generic_page, question|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_MAKEQUESTION"), teacher_new_question_path(generic_page, question)
  parent :questionnaire_question, generic_page
end

crumb :select_upload_questionnaire_question do |generic_page|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEUPLOADMATERIALS"), teacher_select_upload_question_path(generic_page)
  parent :questionnaire_question, generic_page
end

crumb :confirm_upload_questionnaire_question do |generic_page|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEFILEUPLOAD"), teacher_confirm_upload_question_path(generic_page)
  parent :select_upload_questionnaire_question, generic_page
end

crumb :finish_upload_questionnaire_question do |generic_page|
  link t("materials_registration.MAT_REG_REGISTERPARENTQUESTION_EXPLANATION4"), teacher_confirm_upload_question_path(generic_page)
  parent :select_upload_questionnaire_question, generic_page
end

#
# 評価記入リスト作成
#
crumb :evaluations do
  link t("common.COMMON_COURSESELECT"), teacher_evaluations_path
  parent :root
end

crumb :evaluation do |course|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEREGISTRATIONEVALUATIONLIST"), teacher_evaluation_path(course)
  parent :evaluations
end

crumb :new_evaluation do |course|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEREGISTRATIONEVALUATIONLIST") + t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEREGISTRATIONANDEDIT"), teacher_new_evaluation_path(course)
  parent :evaluation, course
end

crumb :edit_evaluation do |generic_page|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEREGISTRATIONEVALUATIONLIST") + t("materials_registration.COMMONMATERIALSREGISTRATION_TITLEREGISTRATIONANDEDIT"), teacher_edit_evaluation_path(generic_page)
  parent :evaluation, generic_page.course
end

crumb :select_course_evaluation do |course|
  link t("common.COMMON_COURSESELECT"), teacher_select_course_evaluation_path(course)
  parent :evaluation, course
end

crumb :select_page_evaluation do |course, origin|
  link t("materials_registration.COMMONMATERIALSREGISTRATION_TITLECOPY_EVALUATIONLIST"), teacher_select_page_evaluation_path({:course_id => course.id, :origin_id => origin.id})
  parent :select_course_evaluation, course
end


#
# 科目環境設定
#
crumb :courses do
  link t("common.COMMON_COURSESELECT"), teacher_courses_path
  parent :root
end

crumb :course do |course|
  link t("admin.course.COMMON_ADMINISTRATECOURSE_COURSEENVIRONMENT"), teacher_course_path(course)
  parent :courses
end


#
# 科目独自のページ
#
crumb :course_specific_pages do
  link t("common.COMMON_COURSESELECT"), teacher_course_specific_pages_path
  parent :root
end

crumb :course_specific_page do
  link t("specific_page.MAT_ALL_COU_REGISTERSPECIFICPAGE_NAVI"), teacher_course_specific_page_path
  parent :course_specific_pages
end


#
# 出席管理
#
crumb :attendances do
  link t("common.COMMON_COURSESELECT"), teacher_attendances_path
  parent :root
end

#
# 連結評価一覧用
#
crumb :combined_records do
  link t("common.COMMON_COURSESELECT"), teacher_combined_records_path
  parent :root
end

crumb :combined_record do |course|
  link t("combinedRecord.COMMONCOMBINEDRECORD_COMBINEDRECORD"), teacher_combined_record_path(course)
  parent :combined_records
end


#
# 教材割付
#
crumb :allocations do
  link t("common.COMMON_COURSESELECT"), teacher_allocations_path
  parent :root
end

crumb :allocation do |course|
  link t("select_class_session.MAT_ALL_SELECTCLASSSESSION_NAVITEXT2"), teacher_allocation_path(course)
  parent :allocations
end

#
# 複合式テスト管理
#
crumb :result_compounds do
  link t("common.COMMON_COURSESELECT"), teacher_result_compounds_path
  parent :root
end

crumb :result_compound do |course|
  link t("materials_administration.COMMONMATERIALSADMINISTRATION_COMPOUNDADMINISTRATION"), teacher_result_compound_path(course)
  parent :result_compounds
end

crumb :result_result_compound do |generic_page|
  link t("materials_administration.COMMONMATERIALSADMINISTRATION_RESULTANDGRADE"), teacher_result_result_compound_path(generic_page)
  parent :result_compound, generic_page.course
end

crumb :result_mark_compound do |generic_page|
  link t("materials_administration.MAT_ADM_COM_GRADECOMPOUND_GRADECOMPOND"), teacher_result_mark_compound_path(generic_page)
  parent :result_result_compound, generic_page
end

crumb :result_graph_compound do |generic_page|
  link t("materials_administration.COMMONMATERIALSADMINISTRATION_RESULTANDGRADE"), teacher_result_graph_compound_path(generic_page)
  parent :result_compound, generic_page.course
end

# 記号入力式テスト作成
crumb :result_multiplefibs do
  link t("common.COMMON_COURSESELECT"), teacher_result_multiplefibs_path
  parent :root
end

crumb :result_multiplefib do |course|
  link t("materials_administration.COMMONMATERIALSADMINISTRATION_MULTIPLEFIBADMINISTRATION"), teacher_result_multiplefib_path(course)
  parent :result_multiplefibs
end

crumb :result_result_multiplefib do |generic_page|
  link t("materials_administration.MAT_ADM_MUL_ADMINISTRATEMULTIPLEFIB_RESULT"), teacher_result_result_multiplefib_path(generic_page)
  parent :result_multiplefib, generic_page.course
end

# レポート管理
crumb :result_essays do
  link t("common.COMMON_COURSESELECT"), teacher_result_essays_path
  parent :root
end

crumb :result_essay do |course|
  link t("materials_administration.COMMONMATERIALSADMINISTRATION_ASSIGNMENTESSAYADMINISTRATION"), teacher_result_essay_path(course)
  parent :result_essays
end

crumb :result_result_essay do |essay|
  link t("materials_administration.COMMONMATERIALSADMINISTRATION_RESULTANDGRADE"), teacher_result_result_essay_path(essay)
  parent :result_essay, essay.course
end

crumb :result_result_essay_upload do |essay|
  link t("materials_administration.MAT_ADM_ASS_PASTASSIGNMENTESSAY_UPLOADSCORESHEET"), teacher_result_result_essay_upload_path(essay)
  parent :result_result_essay, essay
end

crumb :result_result_essay_upload_confirm do |essay|
  link t("materials_administration.MAT_ADM_ASS_PASTASSIGNMENTESSAY_IMPORTSCORESHEET"), teacher_result_result_essay_path(essay)
  parent :result_result_essay_upload, essay
end

crumb :result_result_report_upload do |essay|
  link t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_BUTTON8"), teacher_result_result_report_upload_path(essay)
  parent :result_result_essay, essay
end

crumb :result_result_report_upload_confirm do |essay|
  link t("common.COMMON_CONFIRM"), teacher_result_result_essay_upload_confirm_path(essay)
  parent :result_result_report_upload, essay
end

crumb :result_result_report_import do |essay|
  link t("common.COMMON_REGISTER"), teacher_result_result_essay_upload_confirm_path(essay)
  parent :result_result_report_upload, essay
end

crumb :result_result_report_upload_register do |essay|
  link t("materials_administration.COMMONMATERIALSADMINISTRATION_RESULTANDGRADE"), teacher_result_result_essay_path(essay)
  parent :result_result_essay_upload, essay
end

crumb :result_result_essay_import_file do |essay|
  link t("materials_administration.MAT_ADM_ASS_PASTASSIGNMENTESSAY_ENDIMPORTSCORESHEET1"), result_essay_result_path(essay)
  parent :result_result_essay_upload, essay
end

crumb :mark_essay do |essay|
  link t("materials_administration.MAT_ADM_ASS_GRADEASSIGNMENTESSAY_GRADEASSIGNMENTESSAY"), teacher_result_mark_essay_path(essay)
  parent :result_result_essay, essay
end

crumb :result_essay_history do |essay|
  link t("materials_administration.MAT_ADM_ASS_PASTASSIGNMENTESSAY_PASTASSIGNMENTESSAY"), teacher_result_result_essay_history_path(essay)
  parent :result_result_essay, essay
end

crumb :result_result_upload_return_report do |essay|
  link t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_SUBMITCHECK") + " " + t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_BUTTON1"), teacher_result_result_essay_upload_return_report_path(essay)
  parent :result_result_essay, essay
end

#
# アンケート管理
#
crumb :result_questionnaires do
  link t("common.COMMON_COURSESELECT"), teacher_result_questionnaires_path
  parent :root
end

crumb :result_questionnaire do |course|
  link t("materials_administration.COMMONMATERIALSADMINISTRATION_QUESTIONNAIREADMINISTRATION"), teacher_result_questionnaire_path(course)
  parent :result_questionnaires
end

crumb :result_result_questionnaire do |questionnaire|
  link t("materials_administration.MAT_ADM_QUE_QUESTIONNAIRERESULT_QUESTIONNAIRERESULT"), teacher_result_result_questionnaire_path(questionnaire)
  parent :result_questionnaire, questionnaire.course
end

crumb :detail_result_questionnaire do |question|
  link t("materials_administration.MAT_ADM_QUE_TEXTANSWERRESULT_TEXTANSWERRESULT"), teacher_result_result_questionnaire_path(question)
  parent :result_result_questionnaire, question.parent.generic_pages.first
end

#
# 評価記入リスト管理
#
crumb :result_evaluations do
  link t("common.COMMON_COURSESELECT"), teacher_result_evaluations_path
  parent :root
end

crumb :result_evaluation do |course|
  link t("materials_administration.COMMONMATERIALSADMINISTRATION_EVALUATIONLISTADMINISTRATION"), teacher_result_evaluation_path(course)
  parent :result_evaluations
end

crumb :result_result_evaluation do |evaluation|
  link t("materials_administration.COMMONMATERIALSADMINISTRATION_RESULTANDGRADE"), teacher_result_result_evaluation_path(evaluation)
  parent :result_evaluation, evaluation.course
end

crumb :result_result_evaluation_upload do |evaluation|
  link t("common.COMMON_UPLOAD"), teacher_result_result_evaluation_path(evaluation)
  parent :result_result_evaluation, evaluation
end

#
# お知らせ／メール
#
crumb :teacher_announcements do
  link t("common.COMMON_COURSESELECT"), teacher_announcements_path
  parent :root
end

crumb :teacher_announcement do |course|
  link t("announcement.COMMONANNOUNCEMENT_PAGE2"), teacher_announcement_path(course)
  parent :teacher_announcements
end

crumb :teacher_new_announcement do |course|
  link t("announcement.COMMONANNOUNCEMENT_PAGE1"), teacher_new_announcement_path(course)
  parent :teacher_announcements
end

crumb :teacher_edit_announcement do |announcement|
  link t("announcement.ANN_EDITANNOUNCEMENT_PAGETITLE"), teacher_edit_announcement_path(announcement)
  parent :teacher_announcement, announcement.course
end

crumb :teacher_select_user_announcement do |course|
  link t("announcement.ANN_SELECTSENDUSR_PAGETITLE"), teacher_new_announcement_path(course)
  parent :teacher_new_announcement, course
end

#
# FAQ
#
crumb :teacher_faqs do
  link t("common.COMMON_COURSESELECT"), teacher_faqs_path
  parent :root
end

crumb :teacher_faq do |course|
  link t("faq.COMMONFAQ_PAGE1"), teacher_faq_path(course)
  parent :teacher_faqs
end

crumb :teacher_edit_faq do |faq|
  link t("faq.COMMONFAQ_PAGE2"), teacher_edit_faq_path(faq)
  parent :teacher_faq, faq.course
end

crumb :teacher_confirm_faq do |faq|
  link t("faq.COMMONFAQ_PAGE2"), teacher_confirm_faq_path(faq)
  parent :teacher_edit_faq, faq
end

#
# Open course
#
crumb :open_courses do
  link t("open_course_list.OPE_OPENCOURSELIST_NAVI"), open_courses_path
  parent :root
end

#
# Essay results
#
crumb :essay_results do
  link t("confirm_assignment_essay.MAT_RES_ASS_CONFIRMASSIGNMENTESSAY_NAVI"), essay_results_path
  parent :root
end

crumb :result_essay_result do |essay|
  link t("materials_administration.COMMONMATERIALSADMINISTRATION_RESULTANDGRADE"), result_essay_result_path(essay)
  parent :essay_results
end

crumb :mark_essay_result do |essay|
  link t("materials_administration.MAT_ADM_ASS_GRADEASSIGNMENTESSAY_GRADEASSIGNMENTESSAY"), mark_essay_result_path(essay)
  parent :result_essay_result, essay
end

#
# 未読レポート・未回答FAQ一覧
#
crumb :not_read_assignment_essay_and_faqs do
  link t("top.INSTRUCTORTOP_NOTREADINFORMATION7"), teacher_not_read_assignment_essay_and_faqs_path
  parent :root
end
