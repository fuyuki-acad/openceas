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

class HelpsController < ApplicationController
  before_action :set_manuals, only: [:index, :update]
  before_action :set_manual, only: [:edit, :upload]

  def index
  end

  def update
		## 権限をチェックする
		unless current_user.admin?
			render template: "top/error"
      return
		end

    count = 0
    ActiveRecord::Base.transaction do
      helps = Help.all
      helps.each do |help|
        value = params.require(:manual).permit("#{help.id}" => [:title, :version])["#{help.id}"]
        if help.title != value[:title] || help.version != value[:version]
          help.title = value[:title]
          help.version = value[:version]
          help.save!(validate: false)
          count += 1
        end
      end
    end

    if count > 0
			## 正常に更新
			flash.now[:notice] = I18n.t("helptop.HELPTOP_UPDATE_SUCCESS")
		else
			## 変更がない
			flash.now[:notice] = I18n.t("helptop.HELPTOP_UPDATE_NOCHANGE")
		end

    render :index
  rescue => e
    logger.error e.backtrace.join("\n")
    flash.now[:notice] = I18n.t("helptop.HELPTOP_UPDATE_FAILURE")
    render :index
  end

  def edit
    ## 権限をチェックする
		unless current_user.admin?
			render template: "top/error"
      return
		end
  end

  def upload
    ## 権限をチェックする
		unless current_user.admin?
			render template: "top/error"
      return
		end

    ## DB更新
    if params[:manual].blank?
      flash.now[:notice] = I18n.t("common.COMMON_UPLOADFILENULLCHECK")
    elsif @manual.update(manual_params)
      redirect_to helps_path, :notice => I18n.t("helptop.HELPTOP_UPDATE_SUCCESS")
      return
    else
      flash.now[:notice] = I18n.t("helptop.HELPTOP_UPDATE_FAILURE")
    end
    
    render :edit
  end

  private
    def set_manuals
      if current_user.student?
        @manuals = Help.where("target_auth_cd = ?", current_user.role_id)
      else
        @manuals = Help.all
      end
    end

    def set_manual
      @manual = Help.find(params[:id])
    end

    def manual_params
      params.require(:manual).permit(:file)
    end
end
