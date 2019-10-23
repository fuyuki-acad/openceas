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
#a
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

class Teacher::PackagedLoadingsController < ApplicationController
  include XmlCeas10Module

  before_action :set_course, only: [:download_file, :select_upload_file, :confirm_upload, :commit_upload]


  LOG_FILENAME = "packagedLoading_log.txt"

  def index
    if current_user.admin?
      @courses = Course.order("school_year DESC, day_cd, hour_cd, season_cd").
        where("indirect_use_flag = ? AND (courses.term_flag = ? OR courseware_flag = ?) AND course_name LIKE ?", 0, Settings.COURSE_SELFSTUDY_INVALIDITY, 0, "%#{params[:course_name]}%").page(params[:page])
    else
      @courses = Course.order("school_year DESC, day_cd, hour_cd, season_cd").
        joins(:course_assigned_users).
        where("user_id = ? AND indirect_use_flag = ? AND (courses.term_flag = ? OR courseware_flag = ?) AND course_name LIKE ?", current_user.id, 0, Settings.COURSE_SELFSTUDY_INVALIDITY, 0, "%#{params[:course_name]}%").page(params[:page])
    end
  end

  def download_file
    file_name = create_ceas10_xml_and_compress

    send_data(File.read(file_name), :type => 'application/zip', :dispositon => 'attachment', :filename => File.basename(file_name))
    FileUtils.rm_r(File.dirname(file_name))
  end

  def select_upload_file
  end

  def confirm_upload
    if upload_params[:file].blank?
      raise I18n.t("packaged_loadings.COMMONPACKAGEDLOADING_UPLOADMATERIALSEXPLANATION1")
    end

    extract_file_path = extract_file(@course, upload_params[:file])
    @uploads = load_ceas10_xml_files(extract_file_path)

  rescue => e
    @course.errors[:base] << e.message
    render :select_upload_file
  end

  def commit_upload
    @log = []
    @log << "/******************************/"
    @log << I18n.t("packaged_loadings.PRE_BEA_PAC_FINISHUPLOADMATERIALSBEAN_PACKAGEDLOADINGLOG") + Time.zone.now.to_s
    @log << "/******************************/"

    extract_file_path = get_temporary_path(@course)
    uploads = load_ceas10_xml_files(extract_file_path)

    ActiveRecord::Base.transaction do
      update_from_ceas10_xml(uploads, extract_file_path, @log)
    end

    remove_temporary_files(@course)

  rescue => e
    logger.error e.backtrace.join("\n")
    p e.backtrace.join("\n")
    p e.message
    @course.errors[:base] << e.message
    render :select_upload_file
  end

  def upload_log
    log = params.permit(upload_log: [])
    send_data(log[:upload_log].join("\n"), :filename => LOG_FILENAME)
  end

  private
  def upload_params
    params.require(:material_file).permit(:file)
  end

  def manifest_params
    params.require(:manifest).permit(:dummy, :course_name, :overview, :course_other, :class_session, :allocation)
  end

  def class_data_params
    params.require(:class_data).permit(:dummy, :announcement, :faq)
  end

  def page_params(type)
    params.require(type).permit(page_id: [])
  end

end
