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

module XmlCeas10Module
  include XmlConvertorModule

  TAG_ALLOCATION = "allocation"
  TAG_ALLOCATION_MATERIAL = "allocationOfMaterial"
  TAG_ALLOCATION_URL = "allocationOfUrl"
  TAG_ALLOCATION_COMPOUND = "allocationOfCompound"
  TAG_ALLOCATION_MULTIPLEFIB = "allocationOfMultipleFib"
  TAG_ALLOCATION_ESSAY = "allocationOfAssignmentEssay"
  TAG_ALLOCATION_QUESTIONNAIRE = "allocationOfQuestionnaire"
  TAG_ALLOCATION_EVALUATIONLIST = "allocationOfEvaluationlist"

  protected
  def create_ceas10_xml_and_compress
    file_name = create_xml_and_compress do |work_dir|
      temp_dir = work_dir + "/" + BASE_DIR + "/"

      ## お知らせ announcementService
      create_xml_file(@course.announcements,
        {convertor: Announcement::XML_CONVERT_CEAS10}, temp_dir + ANNOUNCEMENT_FILE) if @course.announcements.count > 0

  		## FAQ faqService
      create_xml_file(@course.faqs.includes(:faq_answer),
        {convertor: Faq::XML_CONVERT_CEAS10}, temp_dir + FAQ_FILE) if @course.faqs.count > 0

      if @course.materials.count > 0
    		## 授業資料 genericPageService
        create_xml_file(@course.materials,
          {convertor: GenericPage::XML_CONVERT_CEAS10, tag_name: 'page'}, temp_dir + MATERIAL_FILE)

        export_material_file(@course.materials, temp_dir + MATERIAL_PATH)
      end

  		## URL教材資料 genericPageService
      create_xml_file(@course.urls,
        {convertor: GenericPage::XML_CONVERT_CEAS10, tag_name: 'page'}, temp_dir + URL_FILE) if @course.urls.count > 0

      if @course.compounds.count > 0
    		## 複合式テスト compoundService
        create_xml_file(@course.compounds.includes(:parent_questions => {:questions => :all_quizzes}),
          {convertor: GenericPage::XML_CONVERT_CEAS10, tag_name: 'page'}, temp_dir + COMPOUND_FILE)

        export_material_file(@course.compounds, temp_dir + COMPOUND_PATH)
      end

      if @course.multiplefibs.count > 0
    		## 記号入力式テスト multipleFibService
        create_xml_file(@course.multiplefibs.includes(:parent_questions => {:questions => :all_quizzes}),
          {convertor: GenericPage::XML_CONVERT_CEAS10, tag_name: 'page'}, temp_dir + MULTIPLEFIB_FILE)

        export_material_file(@course.multiplefibs, temp_dir + MULTIPLEFIB_PATH)
      end

      if @course.essays.count > 0
    		## レポート assignmentEssayService
        create_xml_file(@course.essays,
          {convertor: GenericPage::XML_CONVERT_CEAS10, tag_name: 'page'}, temp_dir + ASSIGNMNENT_ESSAY_FILE)

        export_material_file(@course.essays, temp_dir + ASSIGNMNENT_ESSAY_PATH)
      end

      if @course.questionnaires.count > 0
    		## アンケート questionnaireService
        create_xml_file(@course.questionnaires.includes(:parent_questions => {:questions => :all_quizzes}),
          {convertor: GenericPage::XML_CONVERT_CEAS10, tag_name: 'page'}, temp_dir + QUESTIONNAIRE_FILE)

        export_material_file(@course.questionnaires, temp_dir + QUESTIONNAIRE_PATH)
      end

  		## 評価記入リスト
      create_xml_file(@course.evaluations,
        {convertor: GenericPage::XML_CONVERT_CEAS10, tag_name: 'page'}, temp_dir + EVALUATIONLIST_FILE) if @course.evaluations.count > 0


  		## 各授業回数の基本情報 classSessionService
      create_xml_file(@course.class_sessions,
        {convertor: ClassSession::XML_CONVERT_CEAS10, tag_name: 'classSession'}, temp_dir + CLASS_SESSION_FILE) if @course.class_sessions.count > 0

  		## 教材タイトル一覧情報 genericPageService
      create_xml_file(@course,
        {convertor: Course::XML_CONVERT_MANIFEST_CEAS10, single_record: true, tag_name: 'manifest'}, temp_dir + MANIFEST_FILE)

  		## 科目の基本情報 courseService
      create_xml_file(@course,
        {convertor: Course::XML_CONVERT_CEAS10, single_record: true}, temp_dir + COURSE_FILE)

  		## 教材割り付け情報 classSessionService
      create_allocation_xml(@course,
        {convertor: GenericPageClassSessionAssociation::XML_CONVERT_CEAS10}, temp_dir + ALLOCATION_FILE)
    end

    file_name
  end

  def load_ceas10_xml_files(extract_file_path)
    uploads = {}

    # manifest.xml
    uploads['manifest'] = load_xml_file_as_hash(extract_file_path, MANIFEST_FILE)

    # course xml
    uploads['course'] = load_xml_file_as_hash(extract_file_path, COURSE_FILE)

    # classSession.xml
    uploads['class_session'] = load_xml_file_as_hash(extract_file_path, CLASS_SESSION_FILE)

    # allocation.xml
    uploads['allocation'] = load_xml_file_as_hash(extract_file_path, ALLOCATION_FILE)

    # faq/material.xml
    uploads['announcement'] = load_xml_file_as_hash(extract_file_path, ANNOUNCEMENT_FILE)

    # faq/material.xml
    uploads['faq'] = load_xml_file_as_hash(extract_file_path, FAQ_FILE)

    # material/material.xml
    uploads['material'] = load_xml_file_as_hash(extract_file_path, MATERIAL_FILE)

    # url/material.xml
    uploads['url'] = load_xml_file_as_hash(extract_file_path, URL_FILE)

    # compound/material.xml
    uploads['compound'] = load_xml_file_as_hash(extract_file_path, COMPOUND_FILE)

    # multipleFib/material.xml
    uploads['multiple_fib'] = load_xml_file_as_hash(extract_file_path, MULTIPLEFIB_FILE)

    # assignmentEssay/material.xml
    uploads['essay'] = load_xml_file_as_hash(extract_file_path, ASSIGNMNENT_ESSAY_FILE)

    # questionnaire/material.xml
    uploads['questionnaire'] = load_xml_file_as_hash(extract_file_path, QUESTIONNAIRE_FILE)

    # evaluationlist/material.xml
    uploads['evaluationlist'] = load_xml_file_as_hash(extract_file_path, EVALUATIONLIST_FILE)

    uploads
  end

  def update_from_ceas10_xml(uploads, extract_file_path, log)
    @convert_page = {}

    # Course update
    update_course(uploads['manifest'], uploads['course'], log)

    # Class Session update
    update_class_session(uploads['class_session'], log)

    # Anncouncement update
    update_announcement(uploads['announcement'], log)

    # Faq update
    update_faq(uploads['faq'], log)

    # Material update
    update_material(uploads['material'], extract_file_path, log)

    # Url update
    update_url(uploads['url'], log)

    # Compound update
    update_compound(uploads['compound'], extract_file_path, log)

    # MultipleFib update
    update_multiple_fib(uploads['multiple_fib'], extract_file_path, log)

    # Essay update
    update_essay(uploads['essay'], extract_file_path, log)

    # Questionnaire update
    update_questionnaire(uploads['questionnaire'], extract_file_path, log)

    # Evaluationlist update
    update_evaluationlist(uploads['evaluationlist'], extract_file_path, log)

    # Allocation update
    update_allocation(uploads['allocation'], log)
  end

  def create_allocation_xml(course, opt = {}, file_path)
    xml_data = ""
    tag_name = TAG_ALLOCATION.pluralize

    if opt.kind_of?(Hash)
      opt[:version] = VER_CEAS10
    end

    xml = Builder::XmlMarkup.new(:target => xml_data)
    xml.instruct!(:xml, :version => 1.0, :encoding => "UTF-8")
    set_allocation_xml_elements(tag_name, course, xml, opt[:version], opt[:convertor])

    content = xml.target!
    write_file(content, file_path)
  end

  def set_allocation_xml_elements(tag_name, course, xml, version, convertor)
    xml.tag!(tag_name, {:ceasVersion => version}) do |xml_element|
      # material
      set_allocation_xml_element(TAG_ALLOCATION_MATERIAL, course.materials, xml_element, convertor) if course.materials.count > 0
      # url
      set_allocation_xml_element(TAG_ALLOCATION_URL, course.urls, xml_element, convertor) if course.urls.count > 0
      # compound
      set_allocation_xml_element(TAG_ALLOCATION_COMPOUND, course.compounds, xml_element, convertor) if course.compounds.count > 0
      # multiplefib
      set_allocation_xml_element(TAG_ALLOCATION_MULTIPLEFIB, course.multiplefibs, xml_element, convertor) if course.multiplefibs.count > 0
      # essay
      set_allocation_xml_element(TAG_ALLOCATION_ESSAY, course.essays, xml_element, convertor) if course.essays.count > 0
      # questionnaire
      set_allocation_xml_element(TAG_ALLOCATION_QUESTIONNAIRE, course.questionnaires, xml_element, convertor) if course.questionnaires.count > 0
      # evaluation
      set_allocation_xml_element(TAG_ALLOCATION_EVALUATIONLIST, course.evaluations, xml_element, convertor) if course.evaluations.count > 0
    end
  end

  def set_allocation_xml_element(tag_name, data, xml, convertor)
    tag_convertor = convertor.dup if convertor

    xml.tag!(tag_name) do |xml_alocation|
      data.each do |record|
        if !convertor.blank? && convertor.key?(:tag_attributes)
          tag_attributes = {}
          convertor[:tag_attributes].each do |key, value|
            tag_attributes[value] = record[key.to_s] unless record[key.to_s].blank?
          end

          tag_convertor.delete(:tag_attributes)
        end

        next if record.generic_page_class_session_associations.count == 0

        record.generic_page_class_session_associations.each do |allocation|
          xml_alocation.tag!(TAG_ALLOCATION, tag_attributes) do |xml_item|
            set_xml_tag(allocation, xml_item, tag_convertor)
          end
        end
      end
    end
  end

  def update_course(manifest, xml_course, log)
    is_update = false

    if manifest_params[:course_name] == '1'
      #科目名称の上書き
      @course.course_name = null_convert(manifest['manifest']['courseName'])
      log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_COURSENAMELOG1")
      is_update = true
    end

    if manifest_params[:overview] == '1'
      #科目概要の上書き
      @course.overview = null_convert(manifest['manifest']['overview'])
      log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_OVERVIEWLOG1")
      is_update = true
    end

    if manifest_params[:course_other] == '1'
      #その他の科目情報
      @course.announcement_cd = xml_course['course']['announcementCd']
      @course.faq_cd = xml_course['course']['faqCd']
      @course.group_folder_count = xml_course['course']['groupfolderCount']
      @course.class_session_count = xml_course['course']['classSessionCount']

      if @course.announcement_cd == Settings.COURSE_OPENCOURSEANNOUNCEMENTFLG_ON
        log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_OPENANNOUNCEMENTLOG1")
      elsif @course.announcement_cd == Settings.COURSE_OPENCOURSEANNOUNCEMENTFLG_OFF
        log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_OPENANNOUNCEMENTLOG2")
      end

      if @course.faq_cd == Settings.COURSE_OPENCOURSEFAQFLG_ON
        log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_OPENFAQLOG1")
      elsif @course.faq_cd == Settings.COURSE_OPENCOURSEFAQFLG_OFF
        log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_OPENFAQLOG2")
      end

      log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_GROUPFOLDERLOG1") + @course.group_folder_count.to_s +
        I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_GROUPFOLDERLOG2")
      log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_CLASSSESSIONCOUNTLOG1") + @course.class_session_count.to_s +
        I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_CLASSSESSIONCOUNTLOG2")

      is_update = true
    end

    #更新
    @course.save! if is_update
  end

  def update_class_session(xml_class_session, log)
    if manifest_params[:class_session] == '1'
      xml_class_session['classSessions']['classSession'].each do |xml_session|
        data = @course.class_sessions.where(class_session_no: xml_session['classSessionNo']).first
        if data.blank?
          data = ClassSession.new(course_id: @course.id, class_session_no: xml_session['classSessionNo'])
        end

        data.class_session_title = xml_session['classSessionTitle']
        data.overview = xml_session['overview']
        data.class_session_day = xml_session['classSessionDay']
        data.class_session_memo = xml_session['classSessionMemoOpen']
        data.class_session_memo_closed = xml_session['classSessionMemo']

        if xml_session['classSessionDay'].blank?
          if data.class_session_no == 0
            data.class_session_day = I18n.t("select_class_session.MAT_ALL_SELECTCLASSSESSION_CLASSSESSIONOVERVIEWTEXT1")
          else
            data.class_session_day = I18n.t("common.COMMON_NO2") + data.class_session_no.to_s + I18n.t("common.COMMON_COUNT2")
          end
        end

        data.save!
      end

      log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_CLASSSESSIONLOG1")
    end

    if manifest_params[:overview] == '1'
    end
  end

  def update_announcement(xml_announcement, log)
    return if xml_announcement.blank?

    if class_data_params[:announcement] == '1'
      if xml_announcement['announcements']['announcement'].instance_of?(Array)
        xml_announcement['announcements']['announcement'].each do |item|
          update_announcement_data(item)
        end
      else
        update_announcement_data(xml_announcement['announcements']['announcement'])
      end

      log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_ANNOUNCEMENTLOG1")
    end
  end

  def update_announcement_data(item)
    data = Announcement.new
    data.course_id = @course.id
    data.subject = item['subject']
    data.content = item['content']
    data.mail_flag = item['mailFlg']
    data.announcement_state = item['announcementCd']
    data.insert_user_id = item['insertUsr']

    data.save!
  end

  def update_faq(xml_faq, log)
    return if xml_faq.blank?

    if class_data_params[:faq] == '1'
      if xml_faq['faqs']['faq'].instance_of?(Array)
        xml_faq['faqs']['faq'].each do |item|
          update_faq_data(item)
        end
      else
        update_faq_data(xml_faq['faqs']['faq'])
      end

      log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_FAQLOG1")
    end
  end

  def update_faq_data(item)
    data = Faq.new
    data.course_id = @course.id
    data.user_id = item['usrId']
    data.faq_title = item['faqTitle']
    data.question = item['question']
    data.open_flag = item['openFlg']
    data.response_flag = item['responseFlg']

    data.save!

    if item['faqAnswer']
      answer = FaqAnswer.new
      answer.faq_id = data.id
      answer.answer_title = item['faqAnswer']['answerTitle']
      answer.answer = item['faqAnswer']['answer']
      answer.open_answer = item['faqAnswer']['openAnswer']
      answer.open_question = item['faqAnswer']['openQuestion']
      answer.insert_user_id = item['faqAnswer']['insertUsr']

      answer.save!
    end
  end

  def create_generic_page(item)
    page = GenericPage.new
    page.course_id = @course.id
    page.type_cd = item['typeCd'] unless null?(item['typeCd'])
    page.generic_page_title = item['pageTitle'] unless null?(item['pageTitle'])
    page.start_pass = item['startPass'] unless null?(item['startPass'])
    page.start_time = item['startTime'] unless null?(item['startTime'])
    page.end_time = item['endTime'] unless null?(item['endTime'])
    page.file_name = item['fileName'] unless null?(item['fileName'])
    page.link_name = item['linkName'] unless null?(item['linkName'])
    page.explanation_file_name = item['explanationFileName'] unless null?(item['explanationFileName'])
    page.max_count = item['maxCount'] unless null?(item['maxCount'])
    page.pass_grade = item['passGrade'] unless null?(item['passGrade'])
    page.self_flag = item['selfFlg'] unless null?(item['selfFlg'])
    page.self_pass = item['selfPass'] unless null?(item['selfPass'])
    page.edit_flag = item['editFlg'] unless null?(item['editFlg'])
    page.anonymous_flag = item['anonymousFlg'] unless null?(item['anonymousFlg'])
    page.timelag_flag = item['timelagFlg'] unless null?(item['timelagFlg'])
    page.url_content = item['urlContent'] unless null?(item['urlContent'])
    page.pre_grading_enable_flag = item['preGradingEnableFlg'] unless null?(item['preGradingEnableFlg'])
    page.assignment_essay_return_method_cd = item['assignmentEssayReturnMethodCd'] unless null?(item['assignmentEssayReturnMethodCd'])
    page.score_open_flag = item['scoreOpenFlg'] unless null?(item['scoreOpenFlg'])
    page.material_memo = item['materialMemo'] unless null?(item['materialMemo'])
    page.material_memo_closed = item['materialMemoClosed'] unless null?(item['materialMemoClosed'])

    page.save!(validate: false)

    @convert_page[item['pageId']] = page.id

    if item['parentQuestion']
      if item['parentQuestion'].instance_of?(Array)
        item['parentQuestion'].each do |parent_question|
          create_parent_question(page, parent_question)
        end
      else
        create_parent_question(page, item['parentQuestion'])
      end
    end

    page
  end

  def create_parent_question(generic_page, xml_parent_question)
    parent = Question.new
    parent.content = xml_parent_question['content'].presence || ""
    parent.pattern_cd = Settings.QUESTION_PATTERNCD_PARENTQUESTION
    parent.save!(validate: false)
    generic_page.questions << parent

    if xml_parent_question['question']
      questions = xml_parent_question['question']
      if questions.instance_of?(Array)
        questions.each do |question|
          create_question(parent, question)
        end
      else
        create_question(parent, questions)
      end
    end
  end

  def create_question(parent, xml_question)
    child = Question.new
    child.parent_question_id = parent.id
    child.content = xml_question['content'].presence || ""
    child.pattern_cd = xml_question['patternCd'] unless null?(xml_question['patternCd'])
    child.score = xml_question['score'] unless null?(xml_question['score'])
    child.correct_answer_memo = xml_question['correctAnswerMemo'] unless null?(xml_question['correctAnswerMemo'])
    child.wrong_answer_memo = xml_question['wrongAnswerMemo'] unless null?(xml_question['wrongAnswerMemo'])
    child.answer_memo = xml_question['answerMemo'] unless null?(xml_question['answerMemo'])
    child.must_flag = xml_question['mustFlg'] unless null?(xml_question['mustFlg'])
    child.random_cd = xml_question['randomCd'] unless null?(xml_question['randomCd'])
    child.answer_in_full_cd = xml_question['answerInFullCd'] unless null?(xml_question['answerInFullCd'])
    child.text_row = xml_question['textRow'] unless null?(xml_question['textRow'])

    child.save!(validate: false)

    if xml_question['sel']
      if xml_question['sel'].instance_of?(Array)
        xml_question['sel'].each do |sel|
          create_option(child, sel)
        end
      else
        create_option(child, xml_question['sel'])
      end

      if xml_question['otherFlg'] == '1'
        create_option(child, {
          'content' => I18n.t("common.COMMON_OTHER"),
          'selectCorrectFlg' => '0',
          'selectMarkFlg' => '0','textRow' => '1'}
        )
      end
    end
  end

  def create_option(question, xml_sel)
    quiz = SelectQuiz.new
    quiz.question_id = question.id
    quiz.content = xml_sel['content'] unless null?(xml_sel['content'])
    quiz.select_correct_flag = xml_sel['selectCorrectFlg'] unless null?(xml_sel['selectCorrectFlg'])
    quiz.select_mark_flag = xml_sel['selectMarkFlg'] unless null?(xml_sel['selectMarkFlg'])
    quiz.text_row = xml_sel['textRow'] unless null_convert(xml_sel['textRow']).blank?

    quiz.save!(validate: false)
  end

  def update_material(xml_material, extract_file_path, log)
    return if xml_material.blank? || params[:material].blank?

    log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_MATERIALLOG1")

    page_params(:material)[:page_id].each do |page_id|
      get_pages(xml_material).each do |item|
        if item['pageId'] == page_id
          generic_page = create_generic_page(item)

          unless generic_page.link_name.blank?
            import_material_file(generic_page, page_id, extract_file_path, MATERIAL_PATH)
          end

          log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_MATERIALSLOG1") + item['pageTitle'] +
            I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_MATERIALSLOG2")
        end
      end
    end
  end

  def update_url(xml_url, log)
    return if xml_url.blank? || params[:url].blank?

    log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_URLLOG1")

    page_params(:url)[:page_id].each do |page_id|
      get_pages(xml_url).each do |item|
        if item['pageId'] == page_id
          generic_page = create_generic_page(item)

          log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_MATERIALSLOG1") + item['pageTitle'] +
            I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_MATERIALSLOG2")
        end
      end
    end
  end

  def update_compound(xml_compound, extract_file_path, log)
    return if xml_compound.blank? || params[:compound].blank?

    log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_COMPOUNDLOG1")

    page_params(:compound)[:page_id].each do |page_id|
      get_pages(xml_compound).each do |item|
        if item['pageId'] == page_id
          generic_page = create_generic_page(item)

          unless generic_page.link_name.blank?
            import_material_file(generic_page, page_id, extract_file_path, COMPOUND_PATH)
          end

          log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_MATERIALSLOG1") + item['pageTitle'] +
            I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_MATERIALSLOG2")
        end
      end
    end
  end

  def update_multiple_fib(xml_multiple_fib, extract_file_path, log)
    return if xml_multiple_fib.blank? || params[:multiple_fib].blank?

    log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_MULTIPLEFIBLOG1")

    page_params(:multiple_fib)[:page_id].each do |page_id|
      get_pages(xml_multiple_fib).each do |item|
        if item['pageId'] == page_id
          generic_page = create_generic_page(item)

          unless generic_page.link_name.blank?
            import_material_file(generic_page, page_id, extract_file_path, MULTIPLEFIB_PATH)
          end

          log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_MATERIALSLOG1") + item['pageTitle'] +
            I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_MATERIALSLOG2")
        end
      end
    end
  end

  def update_essay(xml_essay, extract_file_path, log)
    return if xml_essay.blank? || params[:essay].blank?

    log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_ASSIGNMENTESSAYLOG1")

    page_params(:essay)[:page_id].each do |page_id|
      get_pages(xml_essay).each do |item|
        if item['pageId'] == page_id
          generic_page = create_generic_page(item)

          unless generic_page.link_name.blank?
            import_material_file(generic_page, page_id, extract_file_path, ASSIGNMNENT_ESSAY_PATH)
          end

          log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_MATERIALSLOG1") + item['pageTitle'] +
            I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_MATERIALSLOG2")
        end
      end
    end
  end

  def update_questionnaire(xml_questionnaire, extract_file_path, log)
    return if xml_questionnaire.blank? || params[:questionnaire].blank?

    log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_QUESTIONNAIRELOG1")

    page_params(:questionnaire)[:page_id].each do |page_id|
      get_pages(xml_questionnaire).each do |item|
        if item['pageId'] == page_id
          generic_page = create_generic_page(item)

          unless generic_page.link_name.blank?
            import_material_file(generic_page, page_id, extract_file_path, QUESTIONNAIRE_PATH)
          end

          log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_MATERIALSLOG1") + item['pageTitle'] +
            I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_MATERIALSLOG2")
        end
      end
    end
  end

  def update_evaluationlist(xml_evaluationlist, extract_file_path, log)
    return if xml_evaluationlist.blank? || params[:evaluationlist].blank?

    log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_EVALUATIONLISTLOG1")

    page_params(:evaluationlist)[:page_id].each do |page_id|
      get_pages(xml_evaluationlist).each do |item|
        if item['pageId'] == page_id
          generic_page = create_generic_page(item)

          log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_MATERIALSLOG1") + item['pageTitle'] +
            I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_MATERIALSLOG2")
        end
      end
    end
  end

  def get_pages(xml)
    if xml['pages']['page'].instance_of?(Array)
      xml['pages']['page']
    else
      [xml['pages']['page']]
    end
  end

  def update_allocation(xml_allocation, log)
    return unless manifest_params[:allocation] == '1'

    xml_allocation['allocations'].each do |key, value|
      next if key !~ /allocation[\w.]/
      next if value.blank? || value['allocation'].blank?

      if value['allocation'].instance_of?(Array)
        value['allocation'].each do |data|
          update_allocation_data(data)
        end
      else
        update_allocation_data(value['allocation'])
      end
    end

    log << I18n.t("packaged_loadings.PAC_FINISHUPLOADMATERIALS_ALLOCATIONLOG1")
  end

  def update_allocation_data(data)
    return unless @convert_page.key?(data['pageId'])
    return if @course.class_session_count < data['classSessionNo'].to_i

    page_id = @convert_page[data['pageId']]
    page = GenericPage.where(id: page_id).first
    if page
      class_session = ClassSession.where(course_id: @course.id, class_session_no: data['classSessionNo']).first
      if class_session.blank?
        class_session = ClassSession.new(course)
        class_session.course_id = @course.id
        class_session.class_session_no = data['classSessionNo']
        class_session.class_session_title = I18n.t("common.COMMON_NO2") + data['classSessionNo'] + I18n.t("common.COMMON_COUNT2")
        class_session.overview = ''
        class_session.class_session_day = I18n.t("common.COMMON_NO2") + data['classSessionNo'] + I18n.t("common.COMMON_COUNT2")
        class_session.save!
      end

      assigned = GenericPageClassSessionAssociation.where(:class_session_id => class_session.id, :generic_page_id => page.id).first
      if assigned.blank?
        assigned = GenericPageClassSessionAssociation.new
        assigned.class_session_id = class_session.id
        assigned.generic_page_id = page.id
      end
      assigned.view_rank = data["view_rank"] unless null_convert(data['view_rank']).blank?
      assigned.save!
    end
  end
end
