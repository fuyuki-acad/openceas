class ModifyUnreadViews2 < ActiveRecord::Migration[5.1]
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
          INNER JOIN course_enrollment_users
                  ON courses.id = course_enrollment_users.course_id
                 AND answer_scores.user_id = course_enrollment_users.user_id
        WHERE
        	generic_pages.type_cd = 5 AND
        	answer_scores.total_score < 0 AND answer_scores.assignment_essay_score IS NULL
        GROUP BY
        	courses.id,
        	generic_pages.id,
        	generic_pages.type_cd,
        	answer_scores.total_score,
        	answer_scores.assignment_essay_score
        ORDER BY
        	courses.id, generic_pages.id
    SQL
  end

  def down
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
           LEFT JOIN course_enrollment_users
                  ON courses.id = course_enrollment_users.course_id
                 AND answer_scores.user_id = course_enrollment_users.user_id
           LEFT JOIN open_course_assigned_users
                  ON courses.id = open_course_assigned_users.course_id
                 AND answer_scores.user_id = open_course_assigned_users.user_id
        WHERE
        	generic_pages.type_cd = 5 AND
        	answer_scores.total_score < 0 AND answer_scores.assignment_essay_score IS NULL AND
          ( course_enrollment_users.id > 0 OR open_course_assigned_users.id > 0 )
        GROUP BY
        	courses.id,
        	generic_pages.id,
        	generic_pages.type_cd,
        	answer_scores.total_score,
        	answer_scores.assignment_essay_score
        ORDER BY
        	courses.id, generic_pages.id
    SQL
  end
end
