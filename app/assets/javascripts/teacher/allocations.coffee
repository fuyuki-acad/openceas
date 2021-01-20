# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

@confirmAllocate = (target, message) ->
  ret = true
  
  items = $("[id='"+target+"'] input[name^='allocation']:checked").filter ->
    $(this).val() == '1'
  
  if items.length > 0
    if confirm(message)
    else
      ret = false

  return ret
