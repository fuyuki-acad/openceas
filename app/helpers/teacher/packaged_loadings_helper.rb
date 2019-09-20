module Teacher::PackagedLoadingsHelper
  def has_pages(xml)
    if xml && xml['pages']
      true
    else
      false
    end
  end

  def get_pages(xml)
    if xml['pages']['page'].instance_of?(Array)
      return xml['pages']['page']
    else
      return [xml['pages']['page']]
    end
  end
end
