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

require "csv"

class CsvUser
  CONTENT_TYPE_CSV = ".csv"
  FILE_NAME = "usrList.csv"
  # ファイルタイプ
  CSV_FILE_TYPE = 'usrList'
  # サンプルファイル
  CSV_SAMPLE_FILE = 'usrList.csv'
  # 読込行数限界値
  BUS_UTI_CSV_LIMITCOUNT = 5000
  # 項目数
  BUS_UTI_CSV_COLUMNCOUNT = 14
  # 識別子コード
  BUS_SER_IMP_IMP_IDENTIFICATIONCD = 'ud'
  # アカウント制限
  BUS_SER_IMP_IMP_ACCOUNTMAXLENGTH = 64
  BUS_SER_IMP_IMP_ACCOUNTFORMAT = /[^0-9A-Za-z\.\_\-]+/
  BUS_SER_IMP_IMP_PASSWDMIMLENGTH = 6
  BUS_SER_IMP_IMP_PASSWDMAXLENGTH = 128
  BUS_SER_IMP_IMP_NAMENOPREFIXMAXLENGTH = 128
  BUS_SER_IMP_IMP_USRNAMEMAXLENGTH = 64
  BUS_SER_IMP_IMP_KANANAMEMAXLENGTH = 64
  BUS_SER_IMP_IMP_MAILMAXLENGTH = 256
  BUS_SER_IMP_IMP_MAILFORMAT = /\A[!-?A-~]+@[!-?A-~]+\.[!-?A-~]+\z/

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
    Rails.root.join("public", "#{Settings.UPLOAD_DIR}", "#{Settings.CSV_DIR}", "user").to_s + "/"
  end

  def temp_file
    self.tmp_dir + self.file.original_filename
  end
end
