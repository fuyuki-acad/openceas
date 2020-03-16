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

module CustomValidationModule
  extend ActiveSupport::Concern

  VALID_ADDRESS = %r{^(?:(?:(?:(?:[a-zA-Z0-9_!#$%&'*+/=?^`{}~|-]+)(?:.(?:[a-zA-Z0-9_!#$%&'*+/=?^`{}~|-]+))*)|(?:"(?:[^ ]|[^\"])*")))@(?:(?:(?:(?:[a-zA-Z0-9_!#$%&'*+/=?^`{}~|-]+)(?:.(?:[a-zA-Z0-9_!#$%&'*+/=?^`{}~|-]+))*)|(?:[(?:\S|[!-Z^-~])*])))$}

  def validate_presence(target, message)
    value = self.send target.to_sym
    #errors.add(target.to_sym, message) if value.blank?
    errors[:base] << message if value.blank?
  end

  def validate_length(target, message, min, max = nil)
    value = self.send target.to_sym
    unless value.blank?
      if max.nil?
        #errors.add(target.to_sym, message) if value.length < min
        errors[:base] << message if value.length < min
      else
        #errors.add(target.to_sym, message) if value.length < min || value.length > max
        errors[:base] << message if value.length < min || value.length > max
      end
    end
  end

  def validate_max_length(target, message, length)
    value = self.send target.to_sym
    unless value.blank?
      #errors.add(target.to_sym, message) if value.length > length
      errors[:base] << message if value.length > length
    end
  end

  def validate_password(target, message)
    valid_password = /[^0-9A-Za-z\.\_\-]+/
    value = self.send target.to_sym
    unless value.blank?
      #errors.add(target.to_sym, message) if value =~ valid_password
      errors[:base] << message if value =~ valid_password
    end
  end

  def validate_account_name(target, message)
    valid_account = /[^0-9A-Za-z\.\_\-]+/
    value = self.send target.to_sym
    unless value.blank?
      #errors.add(target.to_sym, message) if value =~ valid_account
      errors[:base] << message if value =~ valid_account
    end
  end

  def validate_file_name(target, message)
    valid_name = /[^0-9A-Za-z\.\_\-]+/
    value = self.send target.to_sym
    unless value.blank?
      #errors.add(target.to_sym, message) if value =~ valid_name
      errors[:base] << message if value =~ valid_name
    end
  end

  def validate_name_no_prefix(target, message)
    valid_name = /[^0-9A-Za-z\-]+/
    value = self.send target.to_sym
    unless value.blank?
      #errors.add(target.to_sym, message) if value =~ valid_name
      self.errors[:base] << message if value =~ valid_name
    end
  end

  def validate_alphanumeric(target, message)
    valid_value = /[^0-9A-Za-z]+/
    value = self.send target.to_sym
    unless value.blank?
      #errors.add(target.to_sym, message) if value =~ valid_value
      errors[:base] << message if value =~ valid_value
    end
  end

  def validate_numeric(target, message)
    valid_value = /[^0-9]+/
    value = self.send target.to_sym
    unless value.blank?
      #errors.add(target.to_sym, message) if value =~ valid_value
      errors[:base] << message if value =~ valid_value
    end
  end

  def validate_uniqueness(target, message)
    value = self.send target.to_sym
    unless value.blank?
      if self.new_record?
        count = self.class.where("#{target.to_s} = ?", value).count
      else
        count = self.class.where("#{target.to_s} = ? AND id != ?", value, self.id).count
      end
      #errors.add(target.to_sym, message) if count != 0
      errors[:base] << message if count != 0
    end
  end

  def validate_mail_address(target, message)
    value = self.send target.to_sym
    #errors.add(target.to_sym, message) unless value =~ VALID_ADDRESS
    errors[:base] << message unless value =~ VALID_ADDRESS
  end

  def validate_date(target, message)
    value = self.send target.to_sym
    unless value.blank?
      begin
        date = value.to_date
      rescue ArgumentError
        #errors.add(target.to_sym, message)
        errors[:base] << message
      end
    end
  end
end
