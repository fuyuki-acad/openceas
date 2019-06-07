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

class Teacher::CourseSpecificPagesController < ApplicationController
  before_action :set_courses, only: [:index]
  before_action :set_course, only: [:show, :upload]
  before_action :set_specific_page, only: [:show, :upload, :show_file]

  def upload
    @specific_page.file = params[:file]
    if @specific_page.save_file
      redirect_to action: :show, id: @specific_page
    else
      render action: :show
    end
  end

  def show_file
    if @specific_page.get_specific_page_url
      redirect_to @specific_page.get_specific_page_url
    else
      render 'not_found'
    end
  end

  private
    def set_specific_page
      @specific_page = SpecificPage.find(params[:course_id])
    end
end
