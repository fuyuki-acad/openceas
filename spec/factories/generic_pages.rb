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

FactoryBot.define do
  factory :material, class: GenericPage do
    sequence(:generic_page_title) { |n| "material title #{n}" }
    type_cd  { Settings.GENERICPAGE_TYPECD_MATERIALCODE }
    upload_flag  {GenericPage::TYPE_FILEUPLOAD}
    file {""}
    file_name {""}
    extract_flag {false}
    link_name {""}
    url_content {""}
    sequence(:material_memo_closed) { |n| "material_memo_closed #{n}" }
    sequence(:material_memo) { |n| "material_memo #{n}" }
    html_text {""}
    content {""}
  end

  factory :url_link, class: GenericPage do
    sequence(:generic_page_title) { |n| "url title #{n}" }
    type_cd  { Settings.GENERICPAGE_TYPECD_URLCODE }
    upload_flag  {"0"}
    file {""}
    file_name {""}
    extract_flag {false}
    link_name {""}
    url_content { "https://www.google.co.jp/" }
    material_memo_closed {""}
    sequence(:material_memo) { |n| "url memo #{n}" }
    html_text {""}
    sequence(:content) { |n| "url content #{n}" }
  end

  factory :compound, class: GenericPage do
    sequence(:generic_page_title) { |n| "compound title #{n}" }
    type_cd  { Settings.GENERICPAGE_TYPECD_COMPOUNDCODE }
    max_count  {"1"}
    pass_grade {"60"}
    self_type {"0"}
    sequence(:material_memo) { |n| "compound memo #{n}" }
  end

  factory :multiplefib, class: Multiplefib do
    sequence(:generic_page_title) { |n| "multiplefib title #{n}" }
    type_cd  { Settings.GENERICPAGE_TYPECD_MULTIPLEFIBCODE }
    max_count  {"1"}
    pass_grade {"60"}
    upload_flag { GenericPage::TYPE_FILEUPLOAD }
    start_pass {""}
    start_time {""}
    end_time {""}
    sequence(:material_memo) { |n| "multiplefib memo #{n}" }
  end

  factory :essay, class: GenericPage do
    sequence(:generic_page_title) { |n| "essay title #{n}" }
    type_cd { Settings.GENERICPAGE_TYPECD_ASSIGNMENTESSAYCODE }
    edit_essay_flag {"0"}
    assignment_essay_return_method_cd { Settings.GENERICPAGE_RETURN_METHOD_NOT_RETURN }
    score_open_flag {"0"}
    pre_grading_enable_flag { Settings.GENERICPAGE_PREGRADINGENABLEFLG_OFF }
    upload_flag { GenericPage::TYPE_NOFILEUPLOAD }
    file {""}
    start_pass {""}
    start_time { Time.zone.now }
    end_time { Time.zone.now }
    sequence(:material_memo) { |n| "essay memo #{n}" }
  end

  factory :questionnaire, class: GenericPage do
    sequence(:generic_page_title) { |n| "questionnaire title #{n}" }
    type_cd { Settings.GENERICPAGE_TYPECD_QUESTIONNAIRECODE }
    pre_grading_enable_flag { Settings.GENERICPAGE_PREGRADINGENABLEFLG_OFF }
    upload_flag { GenericPage::TYPE_NOFILEUPLOAD }
    file {""}
    start_pass {""}
    start_time {""}
    end_time {""}
    edit_flag {"0"}
    anonymous_flag {"0"}
    sequence(:material_memo) { |n| "questionnaire memo #{n}" }
  end

  factory :evaluation, class: GenericPage do
    sequence(:generic_page_title) { |n| "evaluation title #{n}" }
    type_cd { Settings.GENERICPAGE_TYPECD_EVALUATIONLISTCODE }
    score_open_flag { Settings.GENERICPAGE_SCOREOPENFLG_OFF }
    sequence(:material_memo) { |n| "evaluation memo #{n}" }
end
end
