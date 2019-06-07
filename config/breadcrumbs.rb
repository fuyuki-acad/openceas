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

crumb :root do
  link '<span class="glyphicon glyphicon-home" aria-hidden="true"></span>'.html_safe + t("common.COMMON_TOPPAGE"), root_path
end

#
# システム情報
#
crumb :sustem_info do
  link t("general_announcement.COMMONGENERALINFO_GENERALINFOLIST"), system_general_announcements_path
  parent :root
end

#
# システム情報
#
crumb :class_sessions do
  link t("class_session_execution.CLA_CLASSSESSIONEXECUTION_TOPNAVI"), class_sessions_path
  parent :root
end

crumb :class_session do
  link t("class_session_execution.CLA_CLASSSESSIONEXECUTION_NAVI"), class_session_path
  parent :class_sessions
end

# FAQ回答一覧
crumb :faqs do
  link t("faq.FAQ_OPENFAQLISTTOP_THISPAGE"), faqs_path
  parent :root
end

# FAQ回答
crumb :faq do |faq_answer|
  link t("faq.FAQ_OPENFAQTOP_THISPAGE"), faq_path(faq_answer)
  parent :root
end

# グループフォルダー
crumb :group_folders do |course|
  link t("group_folder.COMMONGROUPFOLDER_GROUPFOLDERLIST"), group_folders_path(course)
end

# グループフォルダー編集
crumb :edit_group_folder do |course|
  link t("group_folder.GRO_EDITGROUPFOLDER_NAVITEXT1"), edit_group_folder_path(course)
end

# グループフォルダー
crumb :group_folder do |folder|
  link t("group_folder.COMMONGROUPFOLDER_CONTENTSLIST"), group_folder_path(folder)
  parent :group_folders, folder.course
end

# 資料閲覧
crumb :material_group_folder do |material|
  link t("group_folder.GRO_CONFIRMGROUPFOLDERMATERIAL_TITLE"), material_group_folder_path(material)
  parent :group_folder, material.group_folder
end

# サポート
crumb :support do
  link t("top.COMMONTOP_SUPPORT"), supports_path
  parent :root
end
