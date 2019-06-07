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

class MaterialsController < ApplicationController
  before_action :set_generic_page, only: [:show]

  def show
    if @generic_page.type_cd == Settings.GENERICPAGE_TYPECD_URLCODE
      redirect_to @generic_page.url_content
      return

    elsif @generic_page.html?
      redirect_to @generic_page.get_link_url
      return

    else
      file_path = @generic_page.get_material_file_path
      stat = File::stat(file_path)

      if @generic_page.file_name.blank?
        file_name = File.basename(@generic_page.link_name)
      else
        file_name = @generic_page.file_name
      end
      #file_name = ERB::Util.url_encode(file_name) if msie?

      type, is_inline = get_content_type(file_name)
      if is_inline
        send_file(file_path, filename: file_name, length: stat.size, type: type, disposition: :inline)
      else
        send_file(file_path, filename: file_name, length: stat.size, type: type, disposition: :attachment)
      end
    end
  end

  private
    def set_generic_page
      @generic_page = GenericPage.find_by(id: params[:id])
    end

    def msie?
      (/MSIE/ =~ request.user_agent) || (/Trident/ =~ request.user_agent)
    end

end
