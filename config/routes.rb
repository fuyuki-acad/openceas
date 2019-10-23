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

Rails.application.routes.draw do
  devise_for :users,
    controllers: {
      registrations: 'users/registrations',
      omniauth_callbacks: 'users/omniauth_callbacks'
    },
    skip: [:sessions]

  devise_scope :user do
    # local sign in
    get 'login',                to: 'users/sessions#new'
    get 'sign_in',              to: 'users/sessions#new',       as: :new_user_session

    # cas sign in
    #get     'login',              to: redirect('users/auth/cas')
    #get     'sign_in',            to: redirect('users/auth/cas'), as: :new_user_session
    #get     'omniauth_sign_out',  to: 'users/sessions#omniauth_sign_out'

    # Common settings
    delete  'logout',             to: 'users/sessions#destroy'
    get     'users/sign_in',      to: 'users/sessions#new'
    post    'users/sign_in',      to: 'users/sessions#create',    as: :sign_in
  end

#  root :to => "devise/sessions#new"
  root to: 'top#index'
  post  '/' => 'top#index'
  get   '/other_courses/:course_id' => 'top#other_courses'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  resources :users,                 only: [:index] do
    post   :create_image,           on: :collection
    delete :delete_image,           on: :collection
    post   :update_password,        on: :collection
    post   :update_email,           on: :collection
    post   :update_email_mobile,    on: :collection
    delete :delete_email_mobile,    on: :collection
    patch  :update_locale,          on: :collection
    get    :email,                  on: :collection
    post   :update_unset_email,     on: :collection
  end

  # 管理者からのお知らせ
  resources :general_announcements, only: [:index, :show] do
    get   :system,                  on: :collection
  end

  # お知らせ
  resources :announcements,         only: [:index, :show] do
  end

  # FAQ
  resources :faq_answers,           only: [:index, :show] do
  end

  # 授業実施画面
  get     'class_sessions/:course_id',                      to: 'class_sessions#index',         as: 'class_sessions'
  get     'class_sessions/:course_id/show',                 to: 'class_sessions#show',          as: 'class_session'
  get     'class_sessions/:course_id/announcement',         to: 'class_sessions#announcement'
  get     'class_sessions/:course_id/faq',                  to: 'class_sessions#faq'
  get     'class_sessions/:course_id/specific_page',        to: 'class_sessions#specific_page'
  get     'class_sessions/:course_id/collect_attendance',   to: 'class_sessions#collect_attendance',   as: 'collect_attendance'
  post    'class_sessions/:course_id/start_collect_attendance',   to: 'class_sessions#start_collect_attendance'
  get     'class_sessions/:course_id/stop_collect_attendance',    to: 'class_sessions#stop_collect_attendance'
  post    'class_sessions/:course_id/start_collect_late',   to: 'class_sessions#start_collect_late'
  get     'class_sessions/:course_id/recollect_or_delete_attendance',   to: 'class_sessions#recollect_or_delete_attendance'
  get     'class_sessions/:course_id/confirm_attendance',   to: 'class_sessions#confirm_attendance'
  post    'class_sessions/:course_id/recollect_attendance', to: 'class_sessions#recollect_attendance'
  post    'class_sessions/:course_id/recollect_late',       to: 'class_sessions#recollect_late'
  post    'class_sessions/:course_id/delete_attendance',    to: 'class_sessions#delete_attendance'
  get     'class_sessions/:course_id/prepare_help',         to: 'class_sessions#prepare_help'
  get     'class_sessions/:generic_page_id/questionnaire',  to: 'class_sessions#questionnaire'
  get     'class_sessions/:generic_page_id/compond',        to: 'class_sessions#compond'
  get     'class_sessions/:generic_page_id/multiplefib',    to: 'class_sessions#multiplefib'
  get     'class_sessions/:generic_page_id/essay',          to: 'class_sessions#essay'

  # グループフォルダー
  get     'group_folders/:course_id',                       to: 'group_folders#index',          as: 'group_folders'
  get     'group_folders/:id/show',                         to: 'group_folders#show',           as: 'group_folder'
  get     'group_folders/:id/edit',                         to: 'group_folders#edit',           as: 'edit_group_folder'
  patch   'group_folders/:id/update',                       to: 'group_folders#update'
  post    'group_folders/:id/upload',                       to: 'group_folders#upload'
  get     'group_folders/:id/material',                     to: 'group_folders#material',       as: 'material_group_folder'
  post    'group_folders/:id/confirm',                      to: 'group_folders#confirm'

  # FAQ
  get     'faqs',                         to: 'faqs#index',               as: 'faqs'
  get     'faqs/:course_id/show',         to: 'faqs#show',                as: 'faq'
  get     'faqs/:course_id/course',       to: 'faqs#course',              as: 'faq_course'
  get     'faqs/:course_id/new',          to: 'faqs#new'
  post    'faqs/confirm',                 to: 'faqs#confirm'
  post    'faqs/create',                  to: 'faqs#create'

  # 複合式テスト
  get     'compounds/clear_password',           to: 'compounds#clear_password', as: 'compound_clear_password'
  get     'compounds/:id/show',                 to: 'compounds#show',           as: 'compound'
  patch   'compounds/:id/confirm',              to: 'compounds#confirm'
  patch   'compounds/:id/save',                 to: 'compounds#save'
  get     'compounds/:id/finish',               to: 'compounds#finish'
  post    'compounds/:id/password',             to: 'compounds#password'
  get     'compounds/:id/mark_password',        to: 'compounds#mark_password'
  post    'compounds/:id/mark_password',        to: 'compounds#mark_password'
  get     'compounds/:id/mark',                 to: 'compounds#mark'
  get     'compounds/:id/self_mark',            to: 'compounds#self_mark'
  patch   'compounds/:id/update_self_score',    to: 'compounds#update_self_score'

  # 記号入力式テスト
  get     'multiplefibs/clear_password',  to: 'multiplefibs#clear_password',    as: 'multiplefib_clear_password'
  get     'multiplefibs/:id/show',        to: 'multiplefibs#show',              as: 'multiplefib'
  get     'multiplefibs/:id/quiz',        to: 'multiplefibs#quiz'
  post    'multiplefibs/:id/mark',        to: 'multiplefibs#mark'
  get     'multiplefibs/help',            to: 'multiplefibs#help'
  post    'multiplefibs/:id/password',    to: 'multiplefibs#password'

  # アンケート
  get     'questionnaires/finish',        to: 'questionnaires#finish'
  get     'questionnaires/clear_password',to: 'questionnaires#clear_password',  as: 'questionnaire_clear_password'
  get     'questionnaires/:id',           to: 'questionnaires#show',            as: 'questionnaire'
  patch   'questionnaires/:id/confirm',   to: 'questionnaires#confirm'
  patch   'questionnaires/:id/save',      to: 'questionnaires#save'
  post    'questionnaires/:id/password',  to: 'questionnaires#password'

  # レポート
  get     'essays/clear_password',        to: 'essays#clear_password',    as: 'essay_clear_password'
  get     'essays/:id',                   to: 'essays#show',              as: 'essays'
  post    'essays/:id/upload',            to: 'essays#upload'
  post    'essays/:id/destroy',           to: 'essays#destroy'
  post    'essays/:id/password',          to: 'essays#password'
  get     'essays/:id/file',              to: 'essays#file'
  get     'essays/:id/return_file',       to: 'essays#return_file'

  # テスト結果
  get     'results/:course_id',           to: 'results#index',            as: 'results'
  get     'results/:id/show',             to: 'results#show',             as: 'result'

  # レポート確認
  get     'essay_results',                       to: 'essay_results#index'
  get     'essay_results/:id/result',            to: 'essay_results#result',            as: 'result_essay_result'
  get     'essay_results/:id/mark',              to: 'essay_results#mark',              as: 'mark_essay_result'
  get     'essay_results/:id/file',              to: 'essay_results#file'
  get     'essay_results/:id/file_confirm',      to: 'essay_results#file_confirm'
  patch   'essay_results/:id/save',              to: 'essay_results#save'
  patch   'essay_results/:id/update_score',      to: 'essay_results#update_score'
  post    'essay_results/:id/outputcsv_scoresheet',         to: 'essay_results#outputcsv_scoresheet'
  post    'essay_results/:id/outputcsv_assignmentessay',    to: 'essay_results#outputcsv_assignmentessay'
  get     'essay_results/:id/upload',                       to: 'essay_results#upload'
  get     'essay_results/:id/upload_confirm',               to: 'essay_results#upload_confirm'
  post    'essay_results/:id/upload_confirm',               to: 'essay_results#upload_confirm'
  get     'essay_results/:id/upload_register',              to: 'essay_results#upload_register'
  get     'essay_results/:id/import_file',                  to: 'essay_results#import_file'
  get     'essay_results/:id/upload_error',                 to: 'essay_results#upload_error'
  get     'essay_results/:id/report_upload',                to: 'essay_results#report_upload'
  get     'essay_results/:id/report_upload_confirm/:user_id',  to: 'essay_results#report_upload_confirm'
  post    'essay_results/:id/import_report/:user_id',       to: 'essay_results#import_report'
  post    'essay_results/:id/send_mail',                    to: 'essay_results#send_mail'
  post    'essay_results/:id/download_report',              to: 'essay_results#download_report'
  post    'essay_results/:id/download_package',             to: 'essay_results#download_package'
  get     'essay_results/:id/history',                      to: 'essay_results#history',            as: 'result_essay_history'
  patch   'essay_results/:id/comment/:score',               to: 'essay_results#comment',            as: 'result_essay_comment'
  post    'essay_results/:id/return_report',                to: 'essay_results#return_report'
  post    'essay_results/:id/upload_return_report',         to: 'essay_results#upload_return_report',     as: 'result_essay_upload_return_report'
  patch   'essay_results/:id/save_return_report',           to: 'essay_results#save_return_report',       as: 'result_essay_save_return_report'
  get     'essay_results/:id/return_file',       to: 'essay_results#return_file'

  # 公開コース
  get     'open_courses',                 to: 'open_courses#index'
  post    'open_courses/assign',          to: 'open_courses#assign'

  # マニュアル
  get     "helps",                        to: 'helps#index',              as: 'helps'
  patch   "helps/update",                 to: 'helps#update'
  get     "helps/:id/edit",               to: 'helps#edit'
  patch   "helps/:id/upload",             to: 'helps#upload'

  # マテリアル
  resources :materials,   only: [:show] do
    get   :explain_file,          on: :member
  end

  # support
  get     "supports",               to: 'supports#index'

  #
  # 管理者
  #
  namespace :admin do
    resources :users do
      post    :confirm,             on: :collection
      post    :outputcsv,           on: :collection
      post    :course,              on: :collection
      post    :delete,              on: :collection
    end

    resources :courses do
      post    :confirm,             on: :collection
      get     :bulk_update_search,  on: :collection
      patch   :bulk_update,         on: :collection
      get     :bulk_delete_search,  on: :collection
      delete  :bulk_delete,         on: :collection
      post    :outputcsv,           on: :collection
      get     :parent_course,       on: :collection
      post    :outputcsv_enrollment,   on: :collection
      delete  :destroy,             on: :collection
      post    :create_delete_list,  on: :collection
      post    :upload_confirm,      on: :collection
      get     :upload_error,        on: :collection
      get     :upload_destroy,      on: :collection
    end

    get     'access_logs',                 to: 'access_logs#index'
    get     'access_logs/outputcsv',       to: 'access_logs#index'
    delete  'access_logs/destroy',         to: 'access_logs#destroy'

    resources :system_usages,       only: [:index] do
      get     :summary,             on: :collection
    end

    resources :supports,       only: [:index] do
      get     :monthly,             on: :collection
      get     :score,               on: :collection
      post    :refresh_score,       on: :collection
      post    :refresh_detail,      on: :collection
    end

    resources :announcements
    resources :class_sessions

    get     'general_announcements',            to: 'general_announcements#index'
    get     'general_announcements/:id',        to: 'general_announcements#show'
    get     'general_announcements/:id/new',    to: 'general_announcements#new'
    post    'general_announcements/create',     to: 'general_announcements#create'
    get     'general_announcements/:id/edit',   to: 'general_announcements#edit'
    patch   'general_announcements/:id/update', to: 'general_announcements#update'
    delete  'general_announcements/destroy',    to: 'general_announcements#destroy'

    # ユーザリスト読込
    get     'upload_users',                 to: 'uploads#user'
    post    'upload_users/confirm',         to: 'uploads#user_confirm'
    get     'upload_users/import_file',     to: 'uploads#user_import_file'
    delete  'upload_users/destroy_file',    to: 'uploads#user_destroy_file'
    get     'upload_users/sample_file',     to: 'uploads#user_sample_file'
    get     'upload_users/error_list',      to: 'uploads#user_error_list'

    # 科目リスト読込
    get     'upload_courses',               to: 'uploads#course'
    post    'upload_courses/confirm',       to: 'uploads#course_confirm'
    get     'upload_courses/import_file',   to: 'uploads#course_import_file'
    delete  'upload_courses/destroy_file',  to: 'uploads#course_destroy_file'
    get     'upload_courses/sample_file',   to: 'uploads#course_sample_file'
    get     'upload_courses/error_list',    to: 'uploads#course_error_list'

    # 科目担任関連リスト読込
    get     'upload_course_assigns',               to: 'uploads#course_assign'
    post    'upload_course_assigns/confirm',       to: 'uploads#course_assign_confirm'
    get     'upload_course_assigns/import_file',   to: 'uploads#course_assign_import_file'
    delete  'upload_course_assigns/destroy_file',  to: 'uploads#course_assign_destroy_file'
    get     'upload_course_assigns/sample_file',   to: 'uploads#course_assign_sample_file'
    get     'upload_course_assigns/error_list',    to: 'uploads#course_assign_error_list'

    # 履修情報リスト読込
    get     'upload_course_enrollments',               to: 'uploads#course_enrollment'
    post    'upload_course_enrollments/confirm',       to: 'uploads#course_enrollment_confirm'
    get     'upload_course_enrollments/import_file',   to: 'uploads#course_enrollment_import_file'
    delete  'upload_course_enrollments/destroy_file',  to: 'uploads#course_enrollment_destroy_file'
    get     'upload_course_enrollments/sample_file',   to: 'uploads#course_enrollment_sample_file'
    get     'upload_course_enrollments/error_list',    to: 'uploads#course_enrollment_error_list'

    # 授業資料
    get     'materials',                    to: 'materials#index'
    get     'materials/:course_id',         to: 'materials#show'
    get     'materials/:course_id/new',     to: 'materials#new'
    get     'materials/:course_id/new_url', to: 'materials#new_url',    as: 'new_url_material'
    post    'materials/:course_id/create',  to: 'materials#create'
    get     'materials/:id/edit',           to: 'materials#edit'
    get     'materials/:id/edit_url',       to: 'materials#edit_url'
    patch   'materials/:id/update',         to: 'materials#update'
    delete  'materials/:course_id/destroy', to: 'materials#destroy'
    get     'materials/:id/download',       to: 'materials#download'
    get     'materials/help2',              to: 'materials#help2'
    post    'materials/select_file',        to: 'materials#select_file'
    post    'materials/create_html',        to: 'materials#create_html'

    # 複合式テスト
    get     'compounds',                    to: 'compounds#index'
    get     'compounds/:course_id',         to: 'compounds#show',       as: 'compound'
    get     'compounds/:course_id/new',     to: 'compounds#new',        as: 'new_compound'
    post    'compounds/:course_id/create',  to: 'compounds#create'
    get     'compounds/:id/edit',           to: 'compounds#edit',       as: 'edit_compound'
    patch   'compounds/:id/update',         to: 'compounds#update'
    delete  'compounds/:course_id/destroy', to: 'compounds#destroy'
    delete  'compounds/:id/destroy_file',   to: 'compounds#destroy_file'

    # 記号入力式テスト
    get     'multiplefibs',                     to: 'multiplefibs#index'
    get     'multiplefibs/:course_id',          to: 'multiplefibs#show',      as: 'multiplefib'
    get     'multiplefibs/:course_id/new',      to: 'multiplefibs#new',       as: 'new_multiplefib'
    post    'multiplefibs/:course_id/create',   to: 'multiplefibs#create'
    get     'multiplefibs/:id/edit',            to: 'multiplefibs#edit',      as: 'edit_multiplefib'
    patch   'multiplefibs/:id/update',          to: 'multiplefibs#update'
    delete  'multiplefibs/:course_id/destroy',  to: 'multiplefibs#destroy'
    post    'multiplefibs/create_html',         to: 'multiplefibs#create_html'
    get     'multiplefibs/:id/edit_html',       to: 'multiplefibs#edit_html'
    patch   'multiplefibs/:id/update_html',     to: 'multiplefibs#update_html'

    # レポート課題
    get     'essays',                       to: 'essays#index'
    get     'essays/:course_id',            to: 'essays#show',          as: 'essay'
    get     'essays/:course_id/new',        to: 'essays#new',           as: 'new_essay'
    post    'essays/:course_id/create',     to: 'essays#create'
    get     'essays/:id/edit',              to: 'essays#edit',          as: 'edit_essay'
    patch   'essays/:id/update',            to: 'essays#update'
    delete  'essays/:course_id/destroy',    to: 'essays#destroy'
    delete  'essays/:id/destroy_file',      to: 'essays#destroy_file'
    get     'essays/:course_id/download',   to: 'essays#download'

    # アンケート問題
    get     'questionnaires',                     to: 'questionnaires#index'
    get     'questionnaires/:course_id',          to: 'questionnaires#show',      as: 'questionnaire'
    get     'questionnaires/:course_id/new',      to: 'questionnaires#new',       as: 'new_questionnaire'
    post    'questionnaires/:course_id/create',   to: 'questionnaires#create'
    get     'questionnaires/:id/edit',            to: 'questionnaires#edit',      as: 'edit_questionnaire'
    patch   'questionnaires/:id/update',          to: 'questionnaires#update'
    delete  'questionnaires/:course_id/destroy',  to: 'questionnaires#destroy'
    delete  'questionnaires/:id/destroy_file',    to: 'questionnaires#destroy_file'
    get     'questionnaires/:course_id/download', to: 'questionnaires#download'

    # 評価記入リスト
    get     'evaluations',                        to: 'evaluations#index'
    get     'evaluations/:course_id',             to: 'evaluations#show',         as: 'evaluation'
    get     'evaluations/:course_id/new',         to: 'evaluations#new',          as: 'new_evaluation'
    post    'evaluations/:course_id/create',      to: 'evaluations#create'
    get     'evaluations/:id/edit',               to: 'evaluations#edit',         as: 'edit_evaluation'
    patch   'evaluations/:id/update',             to: 'evaluations#update'
    delete  'evaluations/:course_id/destroy',     to: 'evaluations#destroy'

    # 教材割付
    get     'allocations',                            to: 'allocations#index'
    get     'allocations/:course_id',                 to: 'allocations#show',         as: 'allocation'
    post    'allocations/:course_id/create',          to: 'allocations#create'
    patch   'allocations/:id/update',                 to: 'allocations#update'
    get     'allocations/:course_id/execution',       to: 'allocations#execution'
    patch   'allocations/:course_id/assign',          to: 'allocations#assign'

    # 科目独自のページ
    get     'course_specific_pages',                      to: 'course_specific_pages#index'
    get     'course_specific_pages/:course_id',           to: 'course_specific_pages#show',       as: 'course_specific_page'
    post    'course_specific_pages/:course_id/upload',    to: 'course_specific_pages#upload'
    get     'course_specific_pages/:course_id/show_file', to: 'course_specific_pages#show_file'

    # 出席管理
    get     'attendances',                  to: 'attendances#index'
    get     'attendances/:course_id',       to: 'attendances#show'

    # 連結評価一覧表
    get     'combined_records',                        to: 'combined_records#index'
    get     'combined_records/:course_id',             to: 'combined_records#show'
    get     'combined_records/:course_id/output_csv',  to: 'combined_records#output_csv'

    # Token発行
    resources :tokens do
      get   :regenerate_token,              on: :member
    end
  end


  #
  # 担任者
  #
  namespace :teacher do
    # 授業資料
    get     'materials/help2',              to: 'materials#help2'
    get     'materials',                    to: 'materials#index'
    get     'materials/:course_id',         to: 'materials#show',       as: 'material'
    get     'materials/:course_id/new',     to: 'materials#new'
    get     'materials/:course_id/new_url', to: 'materials#new_url',    as: 'new_url_material'
    post    'materials/:course_id/create',  to: 'materials#create'
    get     'materials/:id/edit',           to: 'materials#edit'
    get     'materials/:id/edit_url',       to: 'materials#edit_url'
    patch   'materials/:id/update',         to: 'materials#update'
    delete  'materials/:course_id/destroy', to: 'materials#destroy'
    get     'materials/:id/download',       to: 'materials#download'
    post    'materials/select_file',        to: 'materials#select_file'
    post    'materials/create_html',        to: 'materials#create_html'
    get     'materials/:course_id/select_course',               to: 'materials#select_course',      as: 'select_course_material'
    get     'materials/:course_id/select_page/:origin_id',      to: 'materials#select_page',        as: 'select_page_material'
    post    'materials/:course_id/copy/:origin_id',             to: 'materials#copy'
    get     'materials/:course_id/select_url_course',           to: 'materials#select_url_course',  as: 'select_url_course_material'
    get     'materials/:course_id/select_url_page/:origin_id',  to: 'materials#select_url_page',    as: 'select_url_page_material'
    post    'materials/:course_id/url_copy/:origin_id',         to: 'materials#url_copy'
    get     'materials/:id/select_copy_to',                     to: 'materials#select_copy_to',     as: 'select_copy_to_material'
    post    'materials/:id/copy_to',                            to: 'materials#copy_to'

    # 複合式テスト
    get     'compounds',                    to: 'compounds#index'
    get     'compounds/:course_id',         to: 'compounds#show',       as: 'compound'
    get     'compounds/:course_id/new',     to: 'compounds#new',        as: 'new_compound'
    post    'compounds/:course_id/create',  to: 'compounds#create'
    get     'compounds/:id/edit',           to: 'compounds#edit',       as: 'edit_compound'
    patch   'compounds/:id/update',         to: 'compounds#update'
    delete  'compounds/:course_id/destroy', to: 'compounds#destroy'
    delete  'compounds/:id/destroy_file',   to: 'compounds#destroy_file'
    get     'compounds/:id/download',       to: 'compounds#download'
    get     'compounds/:course_id/select_course',           to: 'compounds#select_course',   as: 'select_course_compound'
    get     'compounds/:course_id/select_page/:origin_id',  to: 'compounds#select_page',     as: 'select_page_compound'
    post    'compounds/:course_id/copy/:origin_id',         to: 'compounds#copy'
    get     'compounds/:course_id/select_upload_file',      to: 'compounds#select_upload_file',     as: 'select_upload_file_compound'
    post    'compounds/:course_id/confirm_upload_file',     to: 'compounds#confirm_upload_file',    as: 'confirm_upload_file_compound'
    patch   'compounds/:course_id/upload_file',             to: 'compounds#upload_file'

    # 複合式テスト問題
    get     'questions/:generic_page_id/sample_csv',        to: 'questions#sample_csv'
    get     'questions/:generic_page_id/sample_xml',        to: 'questions#sample_xml'
    get     'questions/:generic_page_id',                   to: 'questions#show',         as: 'question'
    post    'questions/:generic_page_id/create_parent',     to: 'questions#create_parent'
    get     'questions/:generic_page_id/:id/edit_parent',   to: 'questions#edit_parent'
    patch   'questions/:generic_page_id/:id/update_parent', to: 'questions#update_parent'
    get     'questions/:generic_page_id/:parent_id/new',    to: 'questions#new',          as: 'new_question'
    post    'questions/:generic_page_id/:parent_id/create', to: 'questions#create'
    get     'questions/:generic_page_id/:id/edit',          to: 'questions#edit'
    patch   'questions/:generic_page_id/:id/update',        to: 'questions#update'
    delete  'questions/:generic_page_id/:parent_id/destroy',to: 'questions#destroy'
    get     'questions/:generic_page_id/upload',            to: 'questions#upload'
    get     'questions/:generic_page_id/confirm',           to: 'questions#confirm'
    get     'questions/:generic_page_id/download',          to: 'questions#download'
    patch   'questions/:generic_page_id/:parent_id/update_order',   to: 'questions#update_order'
    get     'questions/:generic_page_id/select_upload',     to: 'questions#select_upload',    as: 'select_upload_question'
    post    'questions/:generic_page_id/confirm_upload',    to: 'questions#confirm_upload',   as: 'confirm_upload_question'
    patch   'questions/:generic_page_id/upload',            to: 'questions#upload'
    get     'questions/:generic_page_id/download',          to: 'questions#download_xml'

    # 記号入力式テスト
    get     'multiplefibs',                     to: 'multiplefibs#index'
    get     'multiplefibs/:course_id',          to: 'multiplefibs#show',      as: 'multiplefib'
    get     'multiplefibs/:course_id/new',      to: 'multiplefibs#new',       as: 'new_multiplefib'
    post    'multiplefibs/:course_id/create',   to: 'multiplefibs#create'
    get     'multiplefibs/:id/edit',            to: 'multiplefibs#edit',      as: 'edit_multiplefib'
    patch   'multiplefibs/:id/update',          to: 'multiplefibs#update'
    delete  'multiplefibs/:course_id/destroy',  to: 'multiplefibs#destroy'
    post    'multiplefibs/create_html',         to: 'multiplefibs#create_html'
    get     'multiplefibs/:id/edit_html',       to: 'multiplefibs#edit_html'
    patch   'multiplefibs/:id/update_html',     to: 'multiplefibs#update_html'
    delete  'multiplefibs/:id/destroy_file',    to: 'multiplefibs#destroy_file'
    get     'multiplefibs/:id/download',        to: 'multiplefibs#download'
    get     'multiplefibs/:course_id/select_course',          to: 'multiplefibs#select_course',   as: 'select_course_multiplefib'
    get     'multiplefibs/:course_id/select_page/:origin_id', to: 'multiplefibs#select_page',     as: 'select_page_multiplefib'
    post    'multiplefibs/:course_id/copy/:origin_id',        to: 'multiplefibs#copy'
    get     'multiplefibs/:course_id/select_upload_file',     to: 'multiplefibs#select_upload_file',    as: 'select_upload_file_multiplefib'
    post    'multiplefibs/:course_id/confirm_upload_file',    to: 'multiplefibs#confirm_upload_file',   as: 'confirm_upload_file_multiplefib'
    patch   'multiplefibs/:course_id/upload_file',            to: 'multiplefibs#upload_file'

    # 記号入力式テスト問題
    get     'multiplefib_questions/help ',                              to: 'multiplefib_questions#help'
    get     'multiplefib_questions/:generic_page_id',                   to: 'multiplefib_questions#index',        as: 'multiplefibs_question'
    get     'multiplefib_questions/:generic_page_id/show',              to: 'multiplefib_questions#show'
    post    'multiplefib_questions/:generic_page_id/create_parent',     to: 'multiplefib_questions#create_parent'
    delete  'multiplefib_questions/:generic_page_id/:id/destroy_parent',to: 'multiplefib_questions#destroy_parent'
    post    'multiplefib_questions/:generic_page_id/create',            to: 'multiplefib_questions#create'
    patch   'multiplefib_questions/:generic_page_id/update',            to: 'multiplefib_questions#update'
    delete  'multiplefib_questions/:generic_page_id/destroy',           to: 'multiplefib_questions#destroy'
    get     'multiplefib_questions/:generic_page_id/confirm',           to: 'multiplefib_questions#confirm'

    # レポート課題
    get     'essays',                       to: 'essays#index'
    get     'essays/:course_id',            to: 'essays#show',          as: 'essay'
    get     'essays/:course_id/new',        to: 'essays#new',           as: 'new_essay'
    post    'essays/:course_id/create',     to: 'essays#create'
    get     'essays/:id/edit',              to: 'essays#edit',          as: 'edit_essay'
    patch   'essays/:id/update',            to: 'essays#update'
    delete  'essays/:course_id/destroy',    to: 'essays#destroy'
    delete  'essays/:id/destroy_file',      to: 'essays#destroy_file'
    get     'essays/:course_id/download',   to: 'essays#download'
    get     'essays/:course_id/select_course',            to: 'essays#select_course',   as: 'select_course_essay'
    get     'essays/:course_id/select_page/:origin_id',   to: 'essays#select_page',     as: 'select_page_essay'
    post    'essays/:course_id/copy/:origin_id',          to: 'essays#copy'
    get     'essays/:course_id/select_upload_file',       to: 'essays#select_upload_file',    as: 'select_upload_file_essay'
    post    'essays/:course_id/confirm_upload_file',      to: 'essays#confirm_upload_file',   as: 'confirm_upload_file_essay'
    patch   'essays/:course_id/upload_file',              to: 'essays#upload_file'

    # レポート課題
    get     'essay_questions/:generic_page_id/show',        to: 'essay_questions#show',         as: 'essay_question'
    post    'essay_questions/:generic_page_id/create',      to: 'essay_questions#create'
    patch   'essay_questions/:generic_page_id/:id/update',  to: 'essay_questions#update'
    delete  'essay_questions/:generic_page_id/:id/destroy', to: 'essay_questions#destroy'
    get     'essay_questions/:generic_page_id/confirm',     to: 'essay_questions#confirm'

    # アンケート問題
    get     'questionnaires',                     to: 'questionnaires#index'
    get     'questionnaires/:course_id',          to: 'questionnaires#show',      as: 'questionnaire'
    get     'questionnaires/:course_id/new',      to: 'questionnaires#new',       as: 'new_questionnaire'
    post    'questionnaires/:course_id/create',   to: 'questionnaires#create'
    get     'questionnaires/:id/edit',            to: 'questionnaires#edit',      as: 'edit_questionnaire'
    patch   'questionnaires/:id/update',          to: 'questionnaires#update'
    delete  'questionnaires/:course_id/destroy',  to: 'questionnaires#destroy'
    delete  'questionnaires/:id/destroy_file',    to: 'questionnaires#destroy_file'
    get     'questionnaires/:course_id/download', to: 'questionnaires#download'
    get     'questionnaires/:course_id/select_course',            to: 'questionnaires#select_course',   as: 'select_course_questionnaire'
    get     'questionnaires/:course_id/select_page/:origin_id',   to: 'questionnaires#select_page',     as: 'select_page_questionnaire'
    post    'questionnaires/:course_id/copy/:origin_id',          to: 'questionnaires#copy'
    get     'questionnaires/:course_id/select_upload_file',       to: 'questionnaires#select_upload_file',    as: 'select_upload_file_questionnaire'
    post    'questionnaires/:course_id/confirm_upload_file',      to: 'questionnaires#confirm_upload_file',   as: 'confirm_upload_file_questionnaire'
    patch   'questionnaires/:course_id/upload_file',              to: 'questionnaires#upload_file'

    # 評価記入リスト
    get     'evaluations',                        to: 'evaluations#index'
    get     'evaluations/:course_id',             to: 'evaluations#show',         as: 'evaluation'
    get     'evaluations/:course_id/new',         to: 'evaluations#new',          as: 'new_evaluation'
    post    'evaluations/:course_id/create',      to: 'evaluations#create'
    get     'evaluations/:id/edit',               to: 'evaluations#edit',         as: 'edit_evaluation'
    patch   'evaluations/:id/update',             to: 'evaluations#update'
    delete  'evaluations/:course_id/destroy',     to: 'evaluations#destroy'
    get     'evaluations/:course_id/select_course',           to: 'evaluations#select_course',   as: 'select_course_evaluation'
    get     'evaluations/:course_id/select_page/:origin_id',  to: 'evaluations#select_page',     as: 'select_page_evaluation'
    post    'evaluations/:course_id/copy/:origin_id',         to: 'evaluations#copy'

    # 教材一括更新
    get     'packaged_loadings',                  to: 'packaged_loadings#index'
    get     'packaged_loadings/:course_id/select_upload_file',    to: 'packaged_loadings#select_upload_file',   as: 'select_upload_file_packaged_loadings'
    post    'packaged_loadings/:course_id/confirm_upload',        to: 'packaged_loadings#confirm_upload',       as: 'confirm_upload_file_packaged_loadings'
    post    'packaged_loadings/:course_id/commit_upload',         to: 'packaged_loadings#commit_upload',        as: 'commit_upload_file_packaged_loadings'
    post    'packaged_loadings/:course_id/upload_log',            to: 'packaged_loadings#upload_log'
    post    'packaged_loadings/:course_id/download_file',         to: 'packaged_loadings#download_file'

    # 出席管理
    get     'attendances',                                                                   to: 'attendances#index'
    get     'attendances/:course_id',                                                        to: 'attendances#show',              as: 'attendance'
    get     'attendances/:course_id/output_csv',                                             to: 'attendances#output_csv'
    get     'attendances/:course_id/edit/:class_session_count/:attendance_count',            to: 'attendances#edit'
    patch   'attendances/:course_id/update/',                                                to: 'attendances#update'
    patch   'attendances/:course_id/batch_update/',                                          to: 'attendances#batch_update'
    get     'attendances/:course_id/output_csv/',                                            to: 'attendances#output_csv'
    get     'attendances/:course_id/attendance_input/',                                      to: 'attendances#attendance_input'
    get     'attendances/:course_id/edit_user/:user_id',                                     to: 'attendances#edit_user'
    patch   'attendances/:course_id/update_user/',                                           to: 'attendances#update_user'
    get     'attendances/:course_id/upload/:class_session_count/:attendance_count',          to: 'attendances#upload'
    post    'attendances/:course_id/upload_confirm/:class_session_count/:attendance_count',  to: 'attendances#upload_confirm'
    get     'attendances/:course_id/upload_error/:class_session_count/:attendance_count',    to: 'attendances#upload_error'
    patch   'attendances/:course_id/update_file/:class_session_count/:attendance_count',     to: 'attendances#update_file'
    get     'attendances/:course_id/upload_result/:class_session_count/:attendance_count',   to: 'attendances#upload_result'

    # 連結評価一覧表
    get     'combined_records',                        to: 'combined_records#index'
    get     'combined_records/:course_id',             to: 'combined_records#show',         as: 'combined_record'
    get     'combined_records/:course_id/output_csv',  to: 'combined_records#output_csv'

    # 教材割付
    get     'allocations',                            to: 'allocations#index'
    get     'allocations/:course_id',                 to: 'allocations#show',         as: 'allocation'
    post    'allocations/:course_id/create',          to: 'allocations#create'
    patch   'allocations/:id/update',                 to: 'allocations#update'
    get     'allocations/:course_id/confirm',         to: 'allocations#confirm'
    patch   'allocations/:course_id/assign',          to: 'allocations#assign'

    # 科目環境設定
    get     'courses',                            to: 'courses#index'
    get     'courses/:course_id',                 to: 'courses#show',             as: 'course'
    post    'courses/:id/confirm',                to: 'courses#confirm',          as: 'confirm_course'
    patch   'courses/:id/update',                 to: 'courses#update'
    delete  'courses/:id/destroy_data',           to: 'courses#destroy_data'
    delete  'courses/destroy',                    to: 'courses#destroy'
    post    'courses/:course_id/outputcsv',       to: 'courses#outputcsv'

    # 科目独自のページ
    get     'course_specific_pages',                      to: 'course_specific_pages#index'
    get     'course_specific_pages/:course_id',           to: 'course_specific_pages#show',       as: 'course_specific_page'
    post    'course_specific_pages/:course_id/upload',    to: 'course_specific_pages#upload'
    get     'course_specific_pages/:course_id/show_file', to: 'course_specific_pages#show_file'

    # 評価記入リスト管理
    resources :evaluation_list_administrations, only: [:index, :show] do
    end

    # 出席管理
    resources :attendance_administrations, only: [:index, :show] do
    end

    # 未読レポート・未回答FAQ一覧
    resources :not_read_assignment_essay_and_faqs, only: [:index]

    # FAQ
    get     'faqs',                         to: 'faqs#index'
    get     'faqs/:course_id',              to: 'faqs#show',        as: 'faq'
    get     'faqs/:id/edit',                to: 'faqs#edit',        as: 'edit_faq'
    post    'faqs/:id/confirm',             to: 'faqs#confirm',     as: 'confirm_faq'
    patch   'faqs/:id/update',              to: 'faqs#update'
    get     'faqs/:id/replied',             to: 'faqs#replied'
    delete  'faqs/:course_id/destroy',      to: 'faqs#destroy'

    # お知らせ／メール
    get     'announcements',                      to: 'announcements#index'
    get     'announcements/:course_id',           to: 'announcements#show',       as: 'announcement'
    get     'announcements/:course_id/new',       to: 'announcements#new',        as: 'new_announcement'
    post    'announcements/:course_id/create',    to: 'announcements#create'
    get     'announcements/:id/edit',             to: 'announcements#edit',       as: 'edit_announcement'
    patch   'announcements/:id/update',           to: 'announcements#update'
    delete  'announcements/:course_id/destroy',   to: 'announcements#destroy'
    get     'announcements/:course_id/user',      to: 'announcements#user'
    post    'announcements/:course_id/send_mail', to: 'announcements#send_mail'

    # アクセスログ
    get     'access_logs',                  to: 'access_logs#index'

    # 授業データ管理
    namespace :result do
      # 複合式テスト管理
      get     'compounds',                            to: 'compounds#index'
      get     'compounds/:course_id',                 to: 'compounds#show',           as: 'compound'
      get     'compounds/:id/result',                 to: 'compounds#result',         as: 'result_compound'
      get     'compounds/:id/mark',                   to: 'compounds#mark',           as: 'mark_compound'
      patch   'compounds/:id/save',                   to: 'compounds#save',           as: 'save_compound'
      get     'compounds/:id/graph',                  to: 'compounds#graph',          as: 'graph_compound'
      post    'compounds/:course_id/outputcsv_bulk',  to: 'compounds#outputcsv_bulk'
      post    'compounds/:id/outputcsv',              to: 'compounds#outputcsv'
      post    'compounds/:id/outputcsv_question',     to: 'compounds#outputcsv_question'

      # 記号入力式テスト管理
      get     'multiplefibs',                            to: 'multiplefibs#index'
      get     'multiplefibs/:course_id',                 to: 'multiplefibs#show',        as: 'multiplefib'
      get     'multiplefibs/:id/result',                 to: 'multiplefibs#result',      as: 'result_multiplefib'
      post    'multiplefibs/:course_id/outputcsv_bulk',  to: 'multiplefibs#outputcsv_bulk'
      post    'multiplefibs/:id/outputcsv',              to: 'multiplefibs#outputcsv'

      # レポート課題
      get     'essays',                                  to: 'essays#index'
      get     'essays/:course_id',                       to: 'essays#show',              as: 'essay'
      get     'essays/:id/result',                       to: 'essays#result',            as: 'result_essay'
      get     'essays/:id/mark',                         to: 'essays#mark',              as: 'mark_essay'
      get     'essays/:id/file',                         to: 'essays#file'
      get     'essays/:id/return_file',                  to: 'essays#return_file'
      get     'essays/:id/file_confirm',                 to: 'essays#file_confirm'
      patch   'essays/:id/save',                         to: 'essays#save'
      patch   'essays/:id/update_score',                 to: 'essays#update_score'
      post    'essays/:id/outputcsv_scoresheet',         to: 'essays#outputcsv_scoresheet'
      post    'essays/:id/outputcsv_assignmentessay',    to: 'essays#outputcsv_assignmentessay'
      get     'essays/:id/upload',                       to: 'essays#upload',            as: 'result_essay_upload'
      get     'essays/:id/upload_confirm',               to: 'essays#upload_confirm'
      post    'essays/:id/upload_confirm',               to: 'essays#upload_confirm',    as: 'result_essay_upload_confirm'
      get     'essays/:id/upload_register',              to: 'essays#upload_register'
      get     'essays/:id/import_file',                  to: 'essays#import_file'
      get     'essays/:id/upload_error',                 to: 'essays#upload_error'
      get     'essays/:id/report_upload',                to: 'essays#report_upload',     as: 'result_report_upload'
      get     'essays/:id/report_upload_confirm/:user_id',  to: 'essays#report_upload_confirm'
      post    'essays/:id/import_report/:user_id',       to: 'essays#import_report'
      post    'essays/:id/send_mail',                    to: 'essays#send_mail'
      post    'essays/:id/download_report',              to: 'essays#download_report'
      post    'essays/:id/download_package',             to: 'essays#download_package'
      get     'essays/:id/history',                      to: 'essays#history',            as: 'result_essay_history'
      patch   'essays/:id/comment/:score',               to: 'essays#comment',            as: 'result_essay_comment'
      post    'essays/:id/return_report',                to: 'essays#return_report'
      get     'essays/:id/upload_return_report',         to: 'essays#upload_return_report',       as: 'result_essay_upload_return_report'
      post    'essays/:id/confirm_return_report',        to: 'essays#confirm_return_report',      as: 'confirm_return_report'
      patch   'essays/:id/save_return_report',           to: 'essays#save_return_report',         as: 'result_essay_save_return_report'

      # アンケート
      get     'questionnaires',                                   to: 'questionnaires#index'
      get     'questionnaires/:course_id',                        to: 'questionnaires#show',      as: 'questionnaire'
      get     'questionnaires/:id/result',                        to: 'questionnaires#result',    as: 'result_questionnaire'
      get     'questionnaires/:id/detail',                        to: 'questionnaires#detail',    as: 'detail_questionnaire'
      post    'questionnaires/bulk_outputcsv/user',               to: 'questionnaires#bulk_outputcsv_user'
      post    'questionnaires/:course_id/bulk_outputcsv',         to: 'questionnaires#bulk_outputcsv'
      post    'questionnaires/:course_id/bulk_outputcsv/user',    to: 'questionnaires#bulk_outputcsv_user'
      post    'questionnaires/:id/outputcsv',                     to: 'questionnaires#outputcsv'
      post    'questionnaires/:id/outputcsv/user',                to: 'questionnaires#outputcsv_user'
      post    'questionnaires/:id/:question_id/detail_outputcsv', to: 'questionnaires#detail_outputcsv'

      # 評価記入リスト管理
      get     'evaluations',                        to: 'evaluations#index'
      get     'evaluations/:course_id',             to: 'evaluations#show',         as: 'evaluation'
      get     'evaluations/:id/result',             to: 'evaluations#result',       as: 'result_evaluation'
      patch   'evaluations/:id/save',               to: 'evaluations#save'
      patch   'evaluations/:id/save_content',       to: 'evaluations#save_content'
      post    'evaluations/:id/outputcsv',          to: 'evaluations#outputcsv'
      get     'evaluations/:id/upload',             to: 'evaluations#upload'
      post    'evaluations/:id/upload_confirm',     to: 'evaluations#upload_confirm'
      post    'evaluations/:id/upload_file',        to: 'evaluations#upload_file'
      get     'evaluations/:id/upload_error',       to: 'evaluations#upload_error'
      patch   'evaluations/:id/upload_save',        to: 'evaluations#upload_save'
      get     'evaluations/:id/upload_result',      to: 'evaluations#upload_result'
      post    'evaluations/:id/send_mail',          to: 'evaluations#send_mail'
    end
  end

  namespace :api, {format: 'json'} do
    namespace :v1 do
      get     'courses',                          to: 'courses#index'
      get     'course/:id',                       to: 'courses#show'

      get     'materials/:course_id',             to: 'materials#index'
      get     'material/:id',                     to: 'materials#show'

      get     'class_sessions/:course_id',        to: 'class_sessions#index'
      get     'class_session/:id',                to: 'class_sessions#show'

      get     'users',                            to: 'users#index'
      get     'user/:id',                         to: 'users#show'
    end
  end
end
