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

module Teacher::AllocationsHelper
  OPEN_TAG = " in"

  def initial_panel_state(type, contents)
    case type
    when "materials"
      if Settings.TEACHER.ALLOCATION.CONTENT_PANEL.MATERIAL.INITIAL_OPEN.to_s == "true"
        if (Settings.TEACHER.ALLOCATION.CONTENT_PANEL.MATERIAL.MAXIMUM_NUMBER.to_s == "0") ||
           (Settings.TEACHER.ALLOCATION.CONTENT_PANEL.MATERIAL.MAXIMUM_NUMBER.to_i >= contents.count)

          OPEN_TAG
        end
      end

    when "urls"
      if Settings.TEACHER.ALLOCATION.CONTENT_PANEL.URL.INITIAL_OPEN.to_s == "true"
        if (Settings.TEACHER.ALLOCATION.CONTENT_PANEL.URL.MAXIMUM_NUMBER.to_s == "0") ||
           (Settings.TEACHER.ALLOCATION.CONTENT_PANEL.URL.MAXIMUM_NUMBER.to_i >= contents.count)

          OPEN_TAG
        end
      end

    when "questionnaires"
      if Settings.TEACHER.ALLOCATION.CONTENT_PANEL.QUESTIONNAIRE.INITIAL_OPEN.to_s == "true"
        if (Settings.TEACHER.ALLOCATION.CONTENT_PANEL.QUESTIONNAIRE.MAXIMUM_NUMBER.to_s == "0") ||
           (Settings.TEACHER.ALLOCATION.CONTENT_PANEL.QUESTIONNAIRE.MAXIMUM_NUMBER.to_i >= contents.count)

          OPEN_TAG
        end
      end

    when "compounds"
      if Settings.TEACHER.ALLOCATION.CONTENT_PANEL.COMPOUND.INITIAL_OPEN.to_s == "true"
        if (Settings.TEACHER.ALLOCATION.CONTENT_PANEL.COMPOUND.MAXIMUM_NUMBER.to_s == "0") ||
           (Settings.TEACHER.ALLOCATION.CONTENT_PANEL.COMPOUND.MAXIMUM_NUMBER.to_i >= contents.count)

          OPEN_TAG
        end
      end

    when "multiplefibs"
      if Settings.TEACHER.ALLOCATION.CONTENT_PANEL.MULTIPLE_FIB.INITIAL_OPEN.to_s == "true"
        if (Settings.TEACHER.ALLOCATION.CONTENT_PANEL.MULTIPLE_FIB.MAXIMUM_NUMBER.to_s == "0") ||
           (Settings.TEACHER.ALLOCATION.CONTENT_PANEL.MULTIPLE_FIB.MAXIMUM_NUMBER.to_i >= contents.count)

          OPEN_TAG
        end
      end

    when "essays"
      if Settings.TEACHER.ALLOCATION.CONTENT_PANEL.ESSAY.INITIAL_OPEN.to_s == "true"
        if (Settings.TEACHER.ALLOCATION.CONTENT_PANEL.ESSAY.MAXIMUM_NUMBER.to_s == "0") ||
           (Settings.TEACHER.ALLOCATION.CONTENT_PANEL.ESSAY.MAXIMUM_NUMBER.to_i >= contents.count)

          OPEN_TAG
        end
      end

    when "evaluations"
      if Settings.TEACHER.ALLOCATION.CONTENT_PANEL.EVALUATION.INITIAL_OPEN.to_s == "true"
        if (Settings.TEACHER.ALLOCATION.CONTENT_PANEL.EVALUATION.MAXIMUM_NUMBER.to_s == "0") ||
           (Settings.TEACHER.ALLOCATION.CONTENT_PANEL.EVALUATION.MAXIMUM_NUMBER.to_i >= contents.count)

          OPEN_TAG
        end
      end

    end
  end
end
