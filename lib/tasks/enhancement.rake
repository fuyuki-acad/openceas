namespace :enhancement do

  desc "Update data for enhancement"
  task update_data: [:start, :set_answer_score_id, :copy_to_answer_score_histories, :copy_to_answer_histories, :delete_history_records] do
    puts "* Finish update data for enhancement - #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
  end

  desc "start"
  task :start do
    puts "* Start update data for enhancement - #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
  end

  desc "Set answer_score_id to answers records"
  task :set_answer_score_id => :environment do
    puts "** Start set answer_score_i to answers records - #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
    # Set answer_score_id in answer records
    AnswerScore.all.each do |answer_score|
      questions = Question.joins(
          "INNER JOIN questions AS parents ON parents.id = questions.parent_question_id" +
          " INNER JOIN generic_page_question_associations AS associations ON associations.question_id = parents.id"
        ).
        where("associations.generic_page_id = ?", answer_score.page_id)

      question_ids = questions.map { |question| question.id }
      if question_ids.count > 0
        args = ["UPDATE answers SET answer_score_id = ?, updated_at = NOW() WHERE question_id IN (?) AND user_id = ? AND answer_count = ?",
          answer_score.id, question_ids, answer_score.user_id, answer_score.answer_count]
        sql = ActiveRecord::Base.send(:sanitize_sql_array, args)
        ActiveRecord::Base.connection.execute(sql)
      end
    end
    puts "** End set answer_score_i to answers records - #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
  end

  desc "Copy to answer_score_histories"
  task :copy_to_answer_score_histories => :environment do
    puts "** Start copy to answer_score_histories - #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
    # Copy answer_scores records to answer_score_histories
    sql = <<-"EOS"
    INSERT INTO answer_score_histories(
      page_id,
      user_id,
      total_score,
      total_raw_score,
      self_total_score,
      self_user_id,
      assignment_essay_score,
      answer_count,
      pass_cd,
      file_name,
      link_name,
      effective_date,
      effective_memo,
      insert_memo,
      insert_user_id,
      update_memo,
      update_user_id,
      answer_score_id,
      created_at,
      updated_at
    )
    SELECT
      page_id,
      user_id,
      total_score,
      total_raw_score,
      self_total_score,
      self_user_id,
      assignment_essay_score,
      answer_count,
      pass_cd,
      file_name,
      link_name,
      effective_date,
      effective_memo,
      insert_memo,
      insert_user_id,
      update_memo,
      update_user_id,
      id,
      NOW(),
      NOW()
    FROM answer_scores
    EOS

    ActiveRecord::Base.connection.execute(sql)

    puts "** End copy to answer_score_histories - #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
  end

  desc "Copy to answer_histories"
  task :copy_to_answer_histories => :environment do
    puts "** Start copy to answer_histories - #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
    # Copy answer_scores records to answer_score_histories
    sql = <<-"EOS"
    INSERT INTO answer_histories(
      question_id,
      user_id,
      answer_count,
      select_answer_id,
      text_answer,
      score,
      self_score,
      effective_date,
      effective_memo,
      insert_memo,
      insert_user_id,
      update_memo,
      update_user_id,
      answer_score_id,
      answer_id,
      created_at,
      updated_at
    )
    SELECT
      question_id,
      user_id,
      answer_count,
      select_answer_id,
      text_answer,
      score,
      self_score,
      effective_date,
      effective_memo,
      insert_memo,
      insert_user_id,
      update_memo,
      update_user_id,
      answer_score_id,
      id,
      NOW(),
      NOW()
    FROM answers
    EOS

    ActiveRecord::Base.connection.execute(sql)
    puts "** End copy to answer_histories - #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
  end

  desc "Delete history records"
  task :delete_history_records => :environment do
    puts "** Start delete answer_scores history records - #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
    # Delete history records of answer_scores
    answer_scores = AnswerScore.select("page_id, user_id, max(answer_count) AS answer_count").group("page_id, user_id, answer_count")
    answer_scores.each do |answer_score|
      args = ["DELETE FROM answer_scores where page_id = ? AND user_id = ? AND answer_count < ?",
        answer_score.page_id, answer_score.user_id, answer_score.answer_count]
      sql = ActiveRecord::Base.send(:sanitize_sql_array, args)
      ActiveRecord::Base.connection.execute(sql)
    end
    puts "** End delete answer_scores history records - #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"

    puts "** Start delete answers history records - #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
    # Delete history records of answers
    answers = Answer.select("question_id, user_id, max(answer_count) AS answer_count").group("question_id, user_id, answer_count")
    answers.each do |answer|
      args = ["DELETE FROM answers where question_id = ? AND user_id = ? AND answer_count < ?",
        answer.question_id, answer.user_id, answer.answer_count]
      sql = ActiveRecord::Base.send(:sanitize_sql_array, args)
      ActiveRecord::Base.connection.execute(sql)
    end
    puts "** End delete answers history records - #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
  end
end
