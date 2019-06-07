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

class UsersController < ApplicationController
  before_action :set_user, only: [:index, :create_image, :update_image, :delete_image,
    :update_password,:update_email, :update_email_mobile, :delete_email_mobile, :update_locale]
  before_action :set_user_image, only: [:index, :create_image, :update_image, :delete_image,
    :update_password, :update_email, :update_email_mobile, :delete_email_mobile]

  def index
    if current_user.teacher?
      courses = Course.joins(:course_assigned_users).
        where("course_assigned_users.user_id = ? AND courses.term_flag = ? AND (courses.season_cd = ? OR courses.season_cd = ?)",
          current_user.id, Settings.COURSE_TERMFLG_EFFECTIVE, Settings.COURSE_SEASONCD_FIRSTTERM, Settings.COURSE_SEASONCD_LASTTERM)
      @schedule = Schedule.new(courses)

      @others = Course.joins(:course_assigned_users).
        where("course_assigned_users.user_id = ? AND courses.term_flag = ? AND courses.season_cd != ? AND courses.season_cd != ?",
          current_user.id, Settings.COURSE_TERMFLG_EFFECTIVE, Settings.COURSE_SEASONCD_FIRSTTERM, Settings.COURSE_SEASONCD_LASTTERM)

    elsif current_user.student?
      courses = Course.joins(:course_enrollment_users).
        where("course_enrollment_users.user_id = ? AND courses.term_flag = ? AND (courses.season_cd = ? OR courses.season_cd = ?)",
          current_user.id, Settings.COURSE_TERMFLG_EFFECTIVE, Settings.COURSE_SEASONCD_FIRSTTERM, Settings.COURSE_SEASONCD_LASTTERM)
      @schedule = Schedule.new(courses)

      @others = Course.joins(:course_enrollment_users).
        where("course_enrollment_users.user_id = ? AND courses.term_flag = ? AND courses.season_cd != ? AND courses.season_cd != ?",
          current_user.id, Settings.COURSE_TERMFLG_EFFECTIVE, Settings.COURSE_SEASONCD_FIRSTTERM, Settings.COURSE_SEASONCD_LASTTERM)

    end
  end

  def create_image
    index
    respond_to do |format|
      begin
        if @user_image
          @user_image.assign_attributes(user_image_params)
          raise unless @user_image.image_valid?
          @user_image.save!
          flash.now[:notice] = I18n.t('change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_INSERT_SUCCESS')
        else
          @user_image = UserImage.new(user_image_params)
          @user_image.image_type = UserImage::IMAGE_TYPE_EXPRESSION
          @user_image.user_id = current_user.id
          @user_image.exp_cd = UserImage::IMAGE_EXP_CD
          raise unless @user_image.image_valid?
          @user_image.save!
          flash.now[:notice] = I18n.t('change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_CHANGE_SUCCESS')
        end

        format.html { render action: :index }
        format.json { render status: :created, location: @user_image }
      rescue => ex
        logger.error ex.backtrace.join("\n")
        if @user_image.errors
          @user_image.errors.messages.each do |key, msg|
            flash.now[:notice] = msg.join("")
            break
          end
        else
          flash.now[:notice] = ex.message
        end
        format.html { render action: :index }
        format.json { render json: @user_image.errors, status: :unprocessable_entity }
      end
    end
  end

  def delete_image
    @user_image.destroy
    flash.now[:notice] = I18n.t('change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_DELETE_SUCCESS')

    index
    respond_to do |format|
      format.html { render action: :index }
      format.json { head :no_content }
    end
  end

  def update_password
    index
    respond_to do |format|
      if @user.update_with_password(user_password_params)
        bypass_sign_in(@user)
        format.html { redirect_to users_path, notice: I18n.t('change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_CHANGE_SUCCESS') }
        format.json { render status: :created, location: @user }
      else
        format.html { render action: :index }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_email
    index
    respond_to do |format|
      if @user.update_with_email(user_email_params)
        flash.now[:notice] = I18n.t('change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_CHANGE_SUCCESS')
        format.html { render action: :index }
        format.json { render status: :created, location: @user }
      else
        format.html { render action: :index }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_email_mobile
    index
    respond_to do |format|
      if @user.update_with_email_mobile(user_email_mobile_params)
        flash.now[:notice] = I18n.t('change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_CHANGE_SUCCESS')
        format.html { render action: :index }
        format.json { render status: :created, location: @user }
      else
        format.html { render action: :index }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def delete_email_mobile
    index
    respond_to do |format|
      if @user.update_attribute(:email_mobile, "")
        flash.now[:notice] = I18n.t('change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_DELETE_SUCCESS')
        format.html { render action: :index }
        format.json { render status: :created, location: @user }
      else
        format.html { render action: :index }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_locale
    @user.update(user_locale_params)
    redirect_to :action => :index

  rescue => e
    logger.error e.backtrace.join("\n")
    flash[:notice] = e.message
    index
    render :index
  end

  def email
    @user = current_user
  end

  def update_unset_email
    @user = current_user
    if @user.update_unset_email(user_email_params)
      redirect_to root_path
    else
      render :email
    end
  end

  private
    def set_user
      @user = User.find(current_user.id)
    end

    def set_user_image
      @user_image = UserImage.find_by(user_id: current_user.id, image_type: UserImage::IMAGE_TYPE_EXPRESSION)
    end

    def user_password_params
      params.require(:user).permit(:password, :password_confirmation, :current_password, :updated_type)
    end

    def user_email_params
      params.require(:user).permit(:new_email, :email_confirmation, :updated_type)
    end

    def user_email_mobile_params
      params.require(:user).permit(:new_email_mobile, :email_mobile_confirmation, :updated_type)
    end

    def user_image_params
      params.require(:user_image).permit(:mount_url)
    end

    def user_locale_params
      params.require(:user).permit(:locale)
    end
end
