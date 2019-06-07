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

class CsvCourse
  CONTENT_TYPE_CSV = ".csv"
  FILE_NAME = "usrList.csv"
  # ファイルタイプ
  CSV_FILE_TYPE = 'courseList'
  # サンプルファイル
  CSV_SAMPLE_FILE = 'courseList.csv'
  # 読込行数限界値
  BUS_UTI_CSV_LIMITCOUNT = 3000
  # 項目数
  BUS_UTI_CSV_COLUMNCOUNT = 23
  CSV_ITEM_COUNT = 11
  # 識別子コード
  BUS_SER_IMP_IMP_IDENTIFICATIONCD = 'cd'
  # 科目コード制限
  BUS_SER_IMP_IMP_COURSECDMAXLENGTH = 128
#  BUS_SER_IMP_IMP_COURSECDFORMAT = /[[:punct:]]/
  BUS_SER_IMP_IMP_COURSECDFORMAT = /[^0-9A-Za-z\.\_\-]+/
  # 科目名制限
  BUS_SER_IMP_IMP_COURSENAMEMAXLENGTH = 64
  # 年度制限
  BUS_SER_IMP_IMP_SCHOOLYEARFORMAT = /^\d{4}$/
  # 学科制限
  BUS_SER_IMP_IMP_MAJORMAXLENGTH = 64
  # 担任者名制限
  BUS_SER_IMP_IMP_INSTRUCTORNAMEMAXLENGTH = 128

  attr_accessor :file, :not_overwrite

  def initialize(csv_params = nil)
    @file = csv_params['file'] unless csv_params.blank?
    @not_overwrite = csv_params['not_overwrite'] unless csv_params.blank?
  end

  def valid?
    return true unless @file.blank?
  end

  def csv?
    File.extname(@file.original_filename) == CONTENT_TYPE_CSV
  end

  def tmp_dir
    Rails.root.join("public", "#{Settings.UPLOAD_DIR}", "#{Settings.CSV_DIR}", "course").to_s + "/"
  end

  def temp_file
    self.tmp_dir + self.file.original_filename
  end
end
