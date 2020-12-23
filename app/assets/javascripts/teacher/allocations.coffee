# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

@confirmAllocate = (target, message) ->
  ret = true

  $("[id='"+target+"'] input[name^='allocation']:checked").each ->
    if $(this).val() == '1'
      if confirm(message)
        return true
      else
        ret = false
        return true
  
  return ret
