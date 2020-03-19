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

class Admin::GeneralAnnouncementsController < ApplicationController
  before_action :set_announcement, only: [:edit, :update]

  def index
    @announcement = GeneralAnnouncement.new
    @announcements = GeneralAnnouncement.all.order("created_at desc")
  end

  def new
  end

  def edit
  end

  def create
    @announcement = GeneralAnnouncement.new(announcement_params)
    if @announcement.save
      redirect_to action: :index
    else
      @announcements = GeneralAnnouncement.all.order("created_at desc")
      render action: :index
    end
  end

  def update
    if @announcement.update(announcement_params)
      session[:course] = nil
      redirect_to action: :index
    else
      render action: :edit
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      if params[:announcement]
        params[:announcement].each do |key, value|
          GeneralAnnouncement.destroy(value)
        end
      end
    end

    redirect_to :action => :index
  end

  private
    def set_announcement
      @announcement = GeneralAnnouncement.find(params[:id])
    end

    def announcement_params
      params.require(:announcement).permit(:title, :content, :type_cd)
    end
end
