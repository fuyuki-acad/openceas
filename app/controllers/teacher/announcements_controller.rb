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

class Teacher::AnnouncementsController < ApplicationController
  before_action :require_assigned, only: [:show, :new, :create, :user, :send_mail, :edit, :update]
  before_action :set_courses, only: [:index]
  before_action :set_course, only: [:show, :new, :create, :user, :send_mail]
  before_action :set_announcement, only: [:edit, :update]

  def new
    if params[:back] && session[:announcement]
      @announcement = Announcement.new(session[:announcement])
      session[:announcement] = nil
    else
      @announcement = Announcement.new
      @announcement.course = @course
      @announcement.announcement_state = "1"
    end
  end

  def create
    @announcement = Announcement.new(announcement_params)
    if @announcement.valid?
      case @announcement.announcement_state
      when "0"
        ActiveRecord::Base.transaction do
          @announcement.save!
          ## send mail to enrolled users (students)
          send_anouncement_mail(@announcement, @course.enrolled_users)
          ## send mail to assigned users (teachers)
          send_anouncement_mail(@announcement, @course.assigned_users)
        end

        message = I18n.t("announcement.ANN_REGISTERANNOUNCEMENT_RESULT_SENDMAIL_html")

      when "1"
        @announcement.save!
        message = I18n.t("announcement.COMMONANNOUNCEMENT_SCRIPT2")

      when "2"
        @enrolled_users = @course.enrolled_users
        session[:announcement] = announcement_params
        render "select_user"
        return
      end

      redirect_to teacher_announcements_path, notice: message
    else
      render action: :new
    end
  end

  def update
    if @announcement.update(announcement_params)
      redirect_to action: :show, :course_id => @announcement.course
    else
      render action: :edit
    end
  end

  def destroy
    items = params[:announcement].keys if params[:announcement]
    items.each do |item|
      course = Course.joins(:announcements).where("announcements.id = ?", item).first
      must_be_assigned(course)
    end
    Announcement.destroy(items)

    redirect_to :action => :show, :course_id => params[:course_id]
  end

  def user
    @users = @course.enrolled_users.where("user_name like ?", "%"+params[:keyword]+"%")
    render :layout => false
  end

  def send_mail
    @announcement = Announcement.new(session[:announcement])
    @enrolled_users = User.where("id in (?)", params[:user].keys)

    ActiveRecord::Base.transaction do
      @announcement.save!
      ## send mail to enrolled users (students)
      send_anouncement_mail(@announcement, @enrolled_users)
      ## send mail to assigned users (teachers)
      send_anouncement_mail(@announcement, @course.assigned_users)
    end

    session[:announcement] = nil
    redirect_to teacher_announcements_path, notice: I18n.t("announcement.ANN_REGISTERANNOUNCEMENT_RESULT_SENDMAIL_html")

  rescue => e
    logger.error e.backtrace.join("\n")
    flash.now[:notice] = e.message
    render "select_user"
  end

  private
    def set_announcement
      @announcement = Announcement.find(params[:id])
    end

    def announcement_params
      params.require(:announcement).permit(:course_id, :subject, :content, :announcement_state)
    end

    def send_anouncement_mail(announcement, users)
      users.each do |user|
        next if user.email.blank?
        AnnouncementMailer.new_registration(announcement, user).deliver_now
        log = AnnouncementMailLog.new(:user_id => user.id, :announcement_id => announcement.id)
        log.save!
      end
    end
end
