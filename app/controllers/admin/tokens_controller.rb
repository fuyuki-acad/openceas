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

class Admin::TokensController < ApplicationController
  before_action :set_token, only: [:edit, :update, :destroy, :regenerate_token]

  def index
    @tokens = AdmittedToken.where(user_id: current_user.id)
  end

  def new
    @token = AdmittedToken.new
  end

  def create
    @token = AdmittedToken.new(token_params)
    @token.user_id = current_user.id
    if @token.save
      redirect_to :action => :index
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @token.update(token_params)
      redirect_to :action => :index
    else
      render :edit
    end
  end

  def destroy
    if @token.destroy
      redirect_to :action => :index
    end
  end

  def regenerate_token
    if @token.regenerate_access_token
      redirect_to :action => :index
    end
  end

  private
  def set_token
    @token = AdmittedToken.find(params[:id])
  end

  def token_params
    params.require(:token).permit(:description, :expire_date)
  end
end
