class UpdateUploadFileSize

  def execute
    puts "***** アップロードファイルサイズ更新 開始 *****"

    count = update_filesize

    puts "** #{count}件に更新しました。"
    puts "***** アップロードファイルサイズ更新 終了 *****"
  end

  def update_filesize
    count = 0

    pages = GenericPage.
      where("generic_pages.type_cd = ?", Settings.GENERICPAGE_TYPECD_ASSIGNMENTESSAYCODE).
      order("generic_pages.course_id DESC, generic_pages.id DESC")

    pages.each do |page|
      page.answer_scores.each do |score|
        if score.link_name.present? && score.file_size.blank?
          if File.exist?(score.get_file_path)
            file_size = File.stat(score.get_file_path).size
          else
            file_size = 0
          end
          score.update_column(:file_size, file_size)
          count += 1
        end

        score.assignment_essay_comments.each do |comment|
          if comment.processed_link_name.present? && comment.file_size.blank?
            if File.exist?(comment.get_file_path)
              file_size = File.stat(comment.get_file_path).size
            else
              file_size = 0
            end
            comment.update_column(:file_size, file_size)
            count += 1
          end
        end
      end

      page.answer_score_histories.each do |history|
        if history.link_name.present? && history.file_size.blank?
          if File.exist?(history.get_file_path)
            file_size = File.stat(history.get_file_path).size
          else
            file_size = 0
          end
          history.update_column(:file_size, file_size)
          count += 1
        end

        if history.latest_comment
          if history.latest_comment.processed_link_name.present? && history.latest_comment.file_size.blank?
            if File.exist?(history.latest_comment.get_file_path)
              file_size = File.stat(history.latest_comment.get_file_path).size
            else
              file_size = 0
            end
            history.latest_comment.update_column(:file_size, file_size)
            count += 1
          end
        end
      end
    end

    return count
  end
end

UpdateUploadFileSize.new.execute
