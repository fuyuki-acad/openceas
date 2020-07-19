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

class Teacher::MultiplefibQuestionsController < ApplicationController
  before_action :require_assigned, only: [:index, :show, :create_parent, :create, :update, :destroy, :confirm]
  before_action :set_generic_page, only: [:index, :show, :create_parent, :create, :update, :destroy, :confirm]
  before_action :set_question, only: [:edit, :destroy_parent]

  def index
  end

  def show
    get_questions
    @question = Question.new
    render :layout => false
  end

  def create_parent
    @question = Question.new
    @question.content = ""
    @question.pattern_cd = Settings.QUESTION_PATTERNCD_PARENTQUESTION
    @question.shuffle_flag = Settings.QUESTION_SHUFFLEFLG_OFF
    Question.transaction do
      @question.save!(validate: false)
      @generic_page.questions << @question

      redirect_to action: :show, :generic_page_id => @generic_page
    end

  rescue => e
    logger.error e.backtrace.join("\n")
    render :show, :layout => false
  end

  def destroy_parent
    if @question.destroy
      redirect_to action: :show, :generic_page_id => params[:generic_page_id]
    else
      render action: :show, :layout => false
    end
  end

  def create
    get_questions

    max_count = Question.where(parent_question_id: params[:parent_id]).maximum(:view_rank)

    @question = Question.new
    @question.parent_question_id = params[:parent_id]
    @question.content = ""
    @question.pattern_cd = Settings.QUESTION_PATTERNCD_RADIO
    @question.score = 1
    @question.view_rank = max_count ? max_count + 1 : 1
    if @question.save(validate: false)
      @questions[params[:parent_id]][@question.id.to_s] = @question
      render action: :show, :layout => false
    else
      render action: :show, :layout => false
    end
  end

  def update
    if params[:question]
      question_values = params[:question].to_unsafe_h.values

      unless check_random_cd(question_values)
        flash[:notice] = I18n.t("materials_registration.MAT_REG_MUL_REGISTERMULTIPLEFIBQUESTIONMAIN_ERROR2_html")
        get_questions
        render action: :show, :layout => false
        return
      end

      unless check_full_cd(question_values)
        flash[:notice] = I18n.t("materials_registration.MAT_REG_MUL_REGISTERMULTIPLEFIBQUESTIONMAIN_ERROR3_html")
        get_questions
        render action: :show, :layout => false
        return
      end

      unless check_random_cd_with_full_cd(question_values)
        flash[:notice] = I18n.t("materials_registration.MAT_REG_MUL_REGISTERMULTIPLEFIBQUESTIONMAIN_ERROR4_html")
        get_questions
        render action: :show, :layout => false
        return
      end

      unless check_full_cd_with_random_cd(question_values)
        flash[:notice] = I18n.t("materials_registration.MAT_REG_MUL_REGISTERMULTIPLEFIBQUESTIONMAIN_ERROR4_html")
        get_questions
        render action: :show, :layout => false
        return
      end

      Question.transaction do
        count = 0
        params[:question].to_unsafe_h.each do |key, value|
          question = Question.find(key)
          question.answer_memo = value['answer_memo']
          question.score = value['score']
          question.random_cd = value['random_cd'].blank? ? nil : value['random_cd']
          question.answer_in_full_cd = value['answer_in_full_cd'].blank? ? nil : value['answer_in_full_cd']
          question.view_rank = count += 1
          question.save!(validate: false)
        end
      end
    end

    url = url_for(action: :show, :generic_page_id => @generic_page)
    redirect_to url, notice: I18n.t("materials_registration.MAT_REG_MUL_REGISTERMULTIPLEFIBQUESTIONMAIN_SUCCESS")

  rescue => e
    logger.error e.backtrace.join("\n")
    get_questions
    render action: :show, :layout => false
  end

  def destroy
    items = params[:delete].keys
    Question.destroy(items) if items.count > 0

    get_questions

    render action: :show, :layout => false
  end

  def help
  end

  def confirm
    @is_view_only = true
    render "multiplefibs/show"
  end

  private
    def set_generic_page
      @generic_page = Multiplefib.find(params[:generic_page_id])
    end

    def set_question
      @question = Question.find(params[:id])
    end

    def question_params
      params.require(:question).permit(:parent_id, :content, :text_count, :score, :must_flag,
      :pattern_cd, :answer_memo, :random_cd, :answer_in_full_cd,
      :quizzes_attributes => [:content, :select_correct_flag])
    end

    def get_questions
      @questions = {}
      @generic_page.parent_questions.each do |parent|
        @questions[parent.id.to_s] = {}
        parent.questions.each do |question|
          if params[:question] && params[:question][question.id.to_s]
            question.score = params[:question][question.id.to_s][:score]
            question.answer_memo = params[:question][question.id.to_s][:answer_memo]
            question.random_cd = params[:question][question.id.to_s][:random_cd]
            question.answer_in_full_cd = params[:question][question.id.to_s][:answer_in_full_cd]
            @questions[parent.id.to_s][question.id.to_s] = question
          else
            @questions[parent.id.to_s][question.id.to_s] = question
          end
        end
      end
    end

    def check_random_cd(question_values)
      value_count = question_values.size

			## 設問の数だけ回す
      (value_count-1).times do |j|
        value = question_values[j]
				## 順不同コードがある時
        unless value['random_cd'].blank?
          index = -1

					## 上のrandomCdと違う数値が出るまで順番に設問を見ていく
					(j + 1).upto(value_count-1) do |k|
          next_value = question_values[k]
						## nullもしくは違う数値が出たらindexを取得
						if value['random_cd'] != next_value['random_cd']
							index = k
							break
						end
					end

					## さらに先を見ていって、同じ数字があるかチェックする
					if index != -1
						(index + 1).upto(value_count-1) do |k|
              next_value = question_values[k]
							## 連続していないのに同じ順不同コードを入力していたらエラーとする
							unless next_value['random_cd'].blank?
								return false if value['random_cd'] == next_value['random_cd']
							end
						end
					end
				end
			end

  		return true
  	end

    def check_full_cd(question_values)
      value_count = question_values.size

			## 設問の数だけ回す
      (value_count-1).times do |j|
        value = question_values[j]
				## 完全解答コードがある時
        unless value['answer_in_full_cd'].blank?
					index = -1
					## 上のanswerInFullCdと違う数値が出るまで順番に設問を見ていく
          (j + 1).upto(value_count-1) do |k|
            next_value = question_values[k]
						## nullもしくは違う数値が出たらindexを取得
						if value['answer_in_full_cd'] != next_value['answer_in_full_cd']
							index = k
							break
						end
					end

					## さらに先を見ていって、同じ数字があるかチェックする
					if index != -1
            (index + 1).upto(value_count-1) do |k|
              next_value = question_values[k]
							## 連続していないのに同じ完全解答コードを入力していたらエラーとする
              unless next_value['answer_in_full_cd'].blank?
                return false if value['answer_in_full_cd'] == next_value['answer_in_full_cd']
              end
						end
					end
				end
			end

  		return true
  	end

    def check_random_cd_with_full_cd(question_values)
      value_count = question_values.size

      ## 設問の数だけ回す
			(value_count-1).times do |j|
				value = question_values[j]
        next_value = question_values[j+1]

				## 順不同コードがある時
				unless value['random_cd'].blank?
					if value['answer_in_full_cd'].blank?
            ## 順不同だけセットしようとしている時
            unless next_value['random_cd'].blank?
							## 同じ順不同コードの時
              if value['random_cd'] == next_value['random_cd']
								## 完全解答コードがnullでないならエラー
                return false unless next_value['answer_in_full_cd'].blank?
							end
            end
          else
            ## 順不同、完全解答の両方をセットしようとしている時
						unless next_value['random_cd'].blank?
							if value['random_cd'] == next_value['random_cd']
                ## 同じ順不同コードの時
                p value['answer_in_full_cd']
                p next_value['answer_in_full_cd']
								## 完全解答コードが違うならエラー
								return false if value['answer_in_full_cd'] != next_value['answer_in_full_cd']

							else
                ## 違う順不同コードの時
                if next_value['answer_in_full_cd'].blank?
									## 完全解答コードが同じならエラー
                  return false if value['answer_in_full_cd'] == next_value['answer_in_full_cd']
								end
							end
						end
					end
        end
      end

      return true
    end

    def check_full_cd_with_random_cd(question_values)
      value_count = question_values.size

      ## 設問の数だけ回す
			(value_count-1).times do |j|
				value = question_values[j]
        next_value = question_values[j+1]
				## 完全解答コードがある時
				unless value['answer_in_full_cd'].blank?
					if value['random_cd'].blank?
            ## 完全解答コードだけセットしようとしている時
            unless next_value['answer_in_full_cd'].blank?
							## 同じ完全解答コードの時
              if value['answer_in_full_cd'] == next_value['answer_in_full_cd']
								## 順不同コードがnullでないならエラー
                return false unless next_value['random_cd'].blank?
							end
            end
          else
            ## 順不同、完全解答の両方をセットしようとしている時
						unless next_value['answer_in_full_cd'].blank?
							if value['answer_in_full_cd'] == next_value['answer_in_full_cd']
                ## 同じ完全解答コードの時
								## 順不同コードが違うならエラー
								return false if value['random_cd'] != next_value['random_cd']

							else
                ## 違う完全解答コードの時
                if next_value['random_cd'].blank?
									## 順不同コードが同じならエラー
                  return false if value['random_cd'] == next_value['random_cd']
								end
							end
						end
					end
        end
      end

      return true
    end
end
