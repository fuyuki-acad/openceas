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

require 'uri'

class Users::SessionsController < Devise::SessionsController
  skip_before_action :authenticate_user!, only: [:omniauth_sign_out]
#  skip_before_action :verify_authenticity_token, only: [:create]
# before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  def create
    super
    SystemLog.success(current_user.id, current_user.account, "", remote_ip)
  end

  # DELETE /resource/sign_out
  def destroy
    if current_user.provider.blank?
      super
    else
      #if omniauth_sign_out
      #  reset_session
      #else
        super
      #end
    end
  end

  def omniauth_sign_out
    if (current_user && current_user.provider == 'cas') || params[:provider] == 'cas'

      options = Devise.omniauth_configs[:cas].options
      host = options[:host]
      logout_url = options[:logout_url] || '/logout'
      request_url = "https://" + host + logout_url + "?service=#{root_url}users/auth/cas/callback"
      redirect_to URI.escape(request_url)

      true
    else
      false
    end
  end

  def failed
    user = User.find_by(account: params['user']['account'])
    if user
      SystemLog.failed(user.id, params[:user][:account], params[:user][:password], remote_ip)
    else
      SystemLog.failed(0, params[:user][:account], params[:user][:password], remote_ip)
    end

    flash[:notice] = flash[:notice]
    flash[:alert] = flash[:alert]
    redirect_to login_path
  end

  def after_sign_in_path_for(resource)
    if current_user.email.blank? && Settings.REMIND_MAIL_ADDRESS_BLANK
      email_users_path
    else
      super
    end
  end

  protected
    def auth_options
      # 失敗時に recall に設定したパスのアクションが呼び出されるので変更
      # { scope: resource_name, recall: "#{controller_path}#new" } # デフォルト
      { scope: resource_name, recall: "#{controller_path}#failed" }
    end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.for(:sign_in) << :attribute
  # end

  private
    def remote_ip
      request.env["HTTP_X_FORWARDED_FOR"] || request.remote_ip
    end
end
