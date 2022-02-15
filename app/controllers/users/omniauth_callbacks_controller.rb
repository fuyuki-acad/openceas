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

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Devise::Controllers::Rememberable
  skip_before_action :authenticate_user!

  def cas
    callback_from :cas
  end

  def azure_activedirectory_v2
    callback_from :azure_activedirectory_v2
  end
  private

  def callback_from(provider)
    provider = provider.to_s

    @user = User.find_for_omniauth(request.env['omniauth.auth'])

    if @user && @user.persisted?
      SystemLog.success(@user.id, @user.account, "", remote_ip)

      flash[:notice] = nil
      flash[:alert] = nil
      sign_in_and_redirect @user, event: :authentication
    else
      SystemLog.failed(0, request.env['omniauth.auth']['uid'], "", remote_ip)

      #session["devise.#{provider}_data"] = request.env['omniauth.auth']
      #redirect_to new_user_registration_url
      @provider = request.env['omniauth.auth'][:provider]
      #flash[:alert] = I18n.t("login.LOG_LOGIN_LOGINFAILED")
      #render :error
      redirect_to new_user_session_path, alert: I18n.t("login.LOG_LOGIN_LOGINFAILED")
    end
  end

  def remote_ip
    request.env["HTTP_X_FORWARDED_FOR"] || request.remote_ip
  end
end
