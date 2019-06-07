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

# Users
crumb :admin_users do
  link t("admin.user.PRI_ADM_USR_SELECTUSR_TITLE"), admin_users_path
  parent :root
end

crumb :admin_user_new do
  link t("admin.user.PRI_ADM_USR_REGISTERUSR_NAVI"), new_admin_user_path
  parent :admin_users
end

crumb :admin_user_edit do |user|
  link t('admin.user.PRI_ADM_USR_REGISTERUSR_NAVI'), edit_admin_user_path(user)
  parent :admin_users
end

# Course
crumb :admin_courses do
  link t("common.COMMON_COURSESELECT"), admin_courses_path
  parent :root
end

crumb :admin_course_new do
  link t('admin.course.PRI_ADM_COU_REGISTERCOURSE_REGISTERCOURSENEW')+" "+t("admin.course.COMMON_ADMINISTRATECOURSE_COURSEADMINISTRATION"), new_admin_course_path
  parent :admin_courses
end

crumb :admin_course_edit do |course|
  link t('admin.course.PRI_ADM_COU_REGISTERCOURSE_EDITCOURSE')+" "+t('admin.course.COMMON_ADMINISTRATECOURSE_COURSEADMINISTRATION'), edit_admin_course_path(course)
  parent :admin_courses
end

crumb :admin_user_bulk_update do
  link t("admin.course.PRI_ADM_COU_COURSEBATCHUPDATE"), new_admin_course_path
  parent :admin_courses
end

crumb :admin_user_result_bulk_update do
  link t("admin.course.PRI_ADM_COU_COURSEBATCHUPDATE_COMPLETE"), new_admin_course_path
  parent :admin_courses
end

crumb :admin_user_bulk_delete do
  link t("admin.course.PRI_ADM_COU_COURSEBATCHDELETE_CREATEFILETOINSERT"), new_admin_course_path
  parent :admin_courses
end

# General Announcement
crumb :admin_general_announcements do
  link t("general_announcement.COMMONGENERALINFO_GENERALINFOLIST"), admin_general_announcements_path
  parent :root
end

# Access Log
crumb :admin_access_logs do
  link t("access_log.ACC_ACCESSLOG_NAVITEXT1"), admin_access_logs_path
  parent :root
end

# System Log
crumb :admin_system_usages do
  link t("system_usage.SYS_CONFIRMSYSTEMLOG_NAVI"), admin_system_usages_path
  parent :root
end

# Usage summary
crumb :admin_system_usages_summary do
  link t("access_log.ACC_ACCESSTOTALINFO_TITLE"), summary_admin_system_usages_path
  parent :root
end

# 一括登録用メニュー
# ユーザリスト読込
crumb :admin_user_uploads do
  link t("registerUsrList1.PRI_REG_UPLOADLIST_NAVI"), admin_upload_users_path
  parent :root
end

crumb :admin_user_upload_results do
  link t("registerUsrList1.PRI_REG_IMPORTLIST_NAVI"), admin_upload_users_destroy_file_path
  parent :admin_user_uploads
end

crumb :admin_user_upload_confirm do
  link t("registerUsrList1.PRI_REG_IMPORTLIST_NAVI"), admin_upload_users_confirm_url
  parent :admin_user_uploads
end

# 科目リスト読込
crumb :admin_course_uploads do
  link t("registerCourseList1.PRI_REG_UPLOADLIST_NAVI"), admin_upload_courses_path
  parent :root
end

crumb :admin_course_upload_results do
  link t("registerCourseList1.PRI_REG_IMPORTLIST_NAVI"), admin_upload_courses_destroy_file_path
  parent :admin_course_uploads
end

crumb :admin_course_upload_confirm do
  link t("registerCourseList1.PRI_REG_IMPORTLIST_NAVI"), admin_upload_courses_confirm_url
  parent :admin_course_uploads
end

# 科目担任関連リスト読込
crumb :admin_course_assign_uploads do
  link t("registerCourseAssignedList1.PRI_REG_UPLOADLIST_NAVI"), admin_upload_course_assigns_path
  parent :root
end

crumb :admin_course_assign_upload_results do
  link t("registerCourseAssignedList1.PRI_REG_IMPORTLIST_NAVI"), admin_upload_course_assigns_destroy_file_path
  parent :admin_course_assign_uploads
end

crumb :admin_course_assign_upload_confirm do
  link t("registerCourseAssignedList1.PRI_REG_IMPORTLIST_NAVI"), admin_upload_course_assigns_confirm_url
  parent :admin_course_assign_uploads
end

# 履修情報リスト読込
crumb :admin_course_enrollment_uploads do
  link t("registerCourseEnrollmentList1.PRI_REG_UPLOADLIST_NAVI"), admin_upload_courses_path
  parent :root
end

crumb :admin_course_enrollment_upload_results do
  link t("registerCourseEnrollmentList1.PRI_REG_IMPORTLIST_NAVI"), admin_upload_courses_destroy_file_path
  parent :admin_course_enrollment_uploads
end

crumb :admin_course_enrollment_upload_confirm do
  link t("registerCourseEnrollmentList1.PRI_REG_IMPORTLIST_NAVI"), admin_upload_courses_confirm_url
  parent :admin_course_enrollment_uploads
end

crumb :admin_support do
  link t("top.COMMONTOP_SUPPORT_MANAGEMENT"), admin_supports_path
  parent :root
end

#tokens
crumb :admin_tokens do
  link t("top.COMMONTOP_TOKEN"), admin_tokens_path
  parent :root
end

crumb :admin_token_new do
  link t("top.COMMONTOP_TOKEN"), new_admin_token_path
  parent :root
end
