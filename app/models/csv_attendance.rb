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

require 'kconv'
require "csv"

class CsvAttendance
  # ファイルタイプ
  CSV_FILE_TYPE = 'attendance'
  # 読込行数限界値
  BUS_UTI_CSV_LIMITCOUNT = 5000
  # 項目数
  BUS_UTI_CSV_COLUMNCOUNT = 4
  # 識別子コード
  BUS_SER_IMP_IMP_IDENTIFICATIONCD = 'ar'

  # CSV解析後のデータが入っている行数
  CSV_DATA_START_LINENO = 5
  # CSVファイルのヘッダーが入っている行数
  HEADER_LINENO = 14

  attr_accessor :file

  def initialize(csv_params = nil)
    @file = csv_params['file'] unless csv_params.blank?
  end

  def valid?
    return true unless @file.blank?
  end

  def csv?
    File.extname(@file.original_filename) == CONTENT_TYPE_CSV
  end

  def tmp_dir
    Rails.root.join("tmp", "#{Settings.UPLOAD_DIR}", User::current_user.id.to_s).to_s
  end

  def temp_file
    self.tmp_dir + self.file.original_filename
  end
end
