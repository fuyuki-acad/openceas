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
  before_action :require_enrolled_or_open_assigned, only: [:show, :explain_file]
  before_action :set_generic_page, only: [:show, :explain_file]

  def show
    if @generic_page.type_cd == Settings.GENERICPAGE_TYPECD_URLCODE
      redirect_to @generic_page.url_content
      return

    #elsif @generic_page.html?
    #  redirect_to @generic_page.get_link_url
    #  return

    else
      send_material_file(@generic_page.get_material_file_path, @generic_page.file_name)
    end
  end

  def explain_file
    send_material_file(@generic_page.get_explanation_file_path, @generic_page.explanation_file_name)
  end

  private
    def set_generic_page
      @generic_page = GenericPage.find_by(id: params[:id])
    end

    def msie?
      (/MSIE/ =~ request.user_agent) || (/Trident/ =~ request.user_agent)
    end

    def send_material_file(file_path, file_name)
      unless FileTest.exist?(file_path)
        render plain: t("common.COMMON_ERROR_NOTEXISTFILE")
        return
      end

      stat = File::stat(file_path)

      if file_name.blank?
        file_name = File.basename(file_path)
      end
      #file_name = ERB::Util.url_encode(file_name) if msie?

      type, is_inline, is_text = get_content_type(file_name)
      if is_inline
        if is_text
          content = File.read(file_path)
          if NKF.guess(content).to_s == "UTF-8"
            type = "#{type}; charset=utf-8"
          end
          send_data(content, filename: file_name, type: type, disposition: :inline)
        else
          send_file(file_path, filename: file_name, length: stat.size, type: type, disposition: :inline)
        end
      else
        send_file(file_path, filename: file_name, length: stat.size, type: type, disposition: :attachment)
      end
    end
end
