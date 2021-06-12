class AddTableAzureVideos < ActiveRecord::Migration[5.1]
  def change
    create_table "azure_videos", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint "page_id", null: false
      t.string "video_url", null: false
      t.integer "forwarding", limit: 1, default: 0, null: false
      t.string "forwarding_url"
      t.string "init_message"
      t.string "firstquartile_message"
      t.string "midpoint_message"
      t.string "thirdquartile_message"
      t.string "ended_message"
      t.integer "panel_display", limit: 1, default: 1, null: false
      t.timestamps null: false
    end
  end
end

