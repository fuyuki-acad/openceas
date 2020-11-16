require 'rails_helper'

RSpec.describe Course, type: :model do
  describe 'バリデーション' do
    before do
      @course = build(:course, :year_of_2019)
    end

    it "正常" do
      @course.valid?
      expect(@course.errors.count).to eq 0
      expect(@course).to be_valid
    end

    it "コース名" do
      @course.course_name = nil
      @course.valid?
      expect(@course.errors.messages[:course_name]).to include I18n.t("admin.course.PRI_ADM_COU_REGISTERCOURSE_ERROR1")
    end

    it "概要" do
      @course.overview = nil
      @course.valid?
      expect(@course.errors.count).to eq 0
      expect(@course).to be_valid

      @course.overview = "あ" * 4096
      @course.valid?
      expect(@course.errors.count).to eq 0
      expect(@course).to be_valid

      @course.overview = "あ" * 4097
      @course.valid?
      expect(@course.errors.messages[:overview]).to include I18n.t("admin.course.PRI_ADM_COU_REGISTERCOURSE_ERROR5")
    end
  end

  context 'コース登録' do
    let(:teacher) { create(:teacher_user) }

    before do
      @attendance_ips = ["192.168.0.1", "192.168.0.2", "192.168.0.3", "192.168.0.4"]
    end

    context '新規追加' do
      before do
        @course = build(:course, :year_of_2019,
          course_name: "target course",
          attendance_ip1: @attendance_ips[0],
          attendance_ip2: @attendance_ips[1],
          attendance_ip3: @attendance_ips[2],
          attendance_ip4: @attendance_ips[3])
      end
        
      it "登録" do
        expect{
          @course.save
        }.to change(User, :count).by(0)
        expect(@course.attendance_ip_list).to eq @attendance_ips.join(",")
      end

      it "取得" do
        @course.save

        target_course = Course.where(course_name: "target course").first
        expect(target_course.attendance_ip1).to eq @attendance_ips[0]
        expect(target_course.attendance_ip2).to eq @attendance_ips[1]
        expect(target_course.attendance_ip3).to eq @attendance_ips[2]
        expect(target_course.attendance_ip4).to eq @attendance_ips[3]
      end
    end
  end
end