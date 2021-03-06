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

class AzureVideo < ApplicationRecord
  belongs_to :generic_page, :foreign_key => :page_id, optional: true

  TYPE_PANEL_NOTDISPLAY = '0'
  TYPE_PANEL_DISPLAY = '1'
  TYPE_NOTFORWARDING = '0'
  TYPE_FORWARDING = '1'

  TYPE_MATERIAL = 10
  TYPE_MULTIPLEFIB_QUESTION = 30
  TYPE_MULTIPLEFIB_EXPLANATION = 31

#  validates :video_url, :presence => true
  def panel?
    if self.panel_display == 1
      return "true" 
    else
      return "false" 
    end
  end

  def forwarding?
    if self.forwarding == 1
      return "true" 
    else
      return "false" 
    end
  end
end

