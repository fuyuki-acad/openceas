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

class GroupFoldersController < ApplicationController
  before_action :set_course, only: [:index]
  before_action :set_group_folder, only: [:show, :edit, :update, :upload]
  before_action :set_group_folder_material, only: [:material, :confirm]

  def show
    @group_folder_material = GroupFolderMaterial.new
    @group_folder_material.group_folder = @group_folder

    get_materials
  end

  def update
    if @group_folder.update(group_folder_params)
      redirect_to :action => :index, :course_id => @group_folder.course
    else
      render :edit
    end
  end

  def upload
    @group_folder_material = GroupFolderMaterial.new(group_folder_material_params)
    if @group_folder_material.save
      flash[:notice] = I18n.t("group_folder.PRE_BEA_GRO_GROUPFOLDERBEAN_ERROR6")
      redirect_to :action => :show, :id => @group_folder
    else
      get_materials
      render :show
    end
  end

  def material
    params[:type_flag] = "0" if params[:type_flag].blank?
  end

  def confirm
    if @material.display_pass == params[:display_pass]
      if params[:type_flag] == GroupFolderMaterial::TYPE_DELETE
        if @material.destroy
          redirect_to :action => :show, :id => @material.group_folder
        else
          render :material
        end
      else
        File.open(@material.material_file, 'r') do |file|
          send_data file.read.force_encoding('BINARY'), filename: @material.file_name
        end
      end
    else
      @material.errors.add(:display_pass, I18n.t("group_folder.PRE_BEA_GRO_GROUPFOLDERBEAN_ERROR8"))
      render :material
    end
  end

  private
    def set_group_folder
      @group_folder = GroupFolder.find(params[:id])
    end

    def set_group_folder_material
      @material = GroupFolderMaterial.find(params[:id])
    end

    def group_folder_params
      params.require(:group_folder).permit(:title, :memo)
    end

    def group_folder_material_params
      params.require(:group_folder_material).permit(:group_folder_id, :title, :display_pass, :file)
    end

    def get_materials
      params[:search_flag] = GroupFolderMaterial::SEARCH_ALL if params[:search_flag].blank?
      params[:order] = GroupFolderMaterial::ORDER_DSC if params[:order].blank?

      if params[:order] == GroupFolderMaterial::ORDER_DSC
        order = "group_folder_materials.created_at DESC"
      else
        order = "group_folder_materials.created_at ASC"
      end

      if params[:keyword].blank?
        @materials = @group_folder.group_folder_materials.order(order)
      else
        case params[:search_flag]
        when GroupFolderMaterial::SEARCH_TITLE
          sql_text = "group_folder_materials.title like :keyword"
        when GroupFolderMaterial::SEARCH_USER
          sql_text = "users.user_name like :keyword"
        else
          sql_text = "group_folder_materials.title like :keyword OR users.user_name like :keyword"
        end
        sql_param = {:keyword => "%"+params[:keyword]+"%"}

        @materials = @group_folder.group_folder_materials.joins(:user).where(sql_text, sql_param).order(order)
      end
    end
end
