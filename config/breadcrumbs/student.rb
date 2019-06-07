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
crumb :users do
  link t("top.COMMONTOP_PERSONALDATA"), users_path
  parent :root
end

# お知らせ一覧
crumb :announcements do
  link t("announcement.ANN_ANNOUNCEMENTLISTTOP_THISPAGE"), announcements_path
  parent :root
end

# お知らせ
crumb :announcement do |announcement|
  link t("announcement.ANN_ANNOUNCEMENTTOP_THISPAGE"), announcement_path(announcement)
  parent :root
end

# テスト結果
crumb :results do |course|
  link t("material_result_view.MAT_RESULTVIEW_MATEEIALRESULTVIEW_NAVITITLE1"), results_path(course)
  parent :root
end

crumb :result do |generic_page|
  link t("material_result_view.MAT_RESULTVIEW_MATEEIALRESULTVIEW_NAVITITLE2"), result_path(generic_page)
  parent :results, generic_page.course
end

# レポート確認
crumb :essay_result do
  link t("confirm_assignment_essay.MAT_RES_ASS_CONFIRMASSIGNMENTESSAY_NAVI"), essay_result_path
  parent :root
end
