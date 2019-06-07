class CreateViews < ActiveRecord::Migration[5.1]
  def up
    execute <<-SQL
      CREATE OR REPLACE VIEW unread_assignment_essay_count_view_tmp AS
        SELECT
        	courses.id AS course_id,
        	generic_pages.id AS generic_page_id,
        	CAST(
        	COUNT(answer_scores.id) AS SIGNED INTEGER) AS unread_count
        FROM
        	courses
        	INNER JOIN generic_pages ON courses.id = generic_pages.course_id
        	INNER JOIN answer_scores ON generic_pages.id = answer_scores.page_id
        where
        	generic_pages.type_cd = 5 AND
        	answer_scores.total_score < 0 AND answer_scores.assignment_essay_score IS NULL
        group by
        	courses.id,
        	generic_pages.id,
        	generic_pages.type_cd,
        	answer_scores.total_score,
        	answer_scores.assignment_essay_score
        ORDER BY
        	courses.id, generic_pages.id
    SQL

    execute <<-SQL
      CREATE OR REPLACE VIEW unread_assignment_essay_count_view AS
        SELECT
        	t1.course_id, t1.generic_page_id, t1.unread_count
        FROM
        	unread_assignment_essay_count_view_tmp as t1
        LEFT JOIN courses c1 on t1.course_id=c1.id
        WHERE c1.unread_assignment_display_cd=0
    SQL

    execute <<-SQL
      CREATE OR REPLACE VIEW non_answer_faq_count_view_tmp AS
        SELECT
            DISTINCT courses.id AS course_id,
        	CAST(
        	COUNT(faqs.id) AS SIGNED INTEGER) AS non_answer_count
        FROM
        	courses INNER JOIN faqs ON courses.id = faqs.course_id
        WHERE
        	faqs.response_flag = 0
        GROUP BY
        	courses.id
    SQL

    execute <<-SQL
      CREATE OR REPLACE VIEW non_answer_faq_count_view AS
        SELECT t1.course_id, t1.non_answer_count
        FROM non_answer_faq_count_view_tmp as t1
        LEFT JOIN courses c1 on c1.id=t1.course_id
        WHERE c1.unread_faq_display_cd=0
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW unread_assignment_essay_count_view_tmp
    SQL

    execute <<-SQL
      DROP VIEW unread_assignment_essay_count_view
    SQL

    execute <<-SQL
      DROP VIEW non_answer_faq_count_view_tmp
    SQL

    execute <<-SQL
      DROP VIEW non_answer_faq_count_view
    SQL
  end
end
