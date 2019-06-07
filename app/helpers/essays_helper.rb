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

module EssaysHelper
  def essay_status_name(status)
    case status
    when 0
      t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_NOTPRESENT")
    when 1
      t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_PRESENTED")
    when 2
      t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_REPRESENT")
    when 3
      t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_GRADED")
    when 4
      t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_GRADED_REPRESENT")
    when 5
      t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_GRADED_ACCEPTANCE")
    when 6
      t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_RETUENED_REPRESENT")
    when 7
      t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_RETUENED_ACCEPTANCE")
    end
  end
end
