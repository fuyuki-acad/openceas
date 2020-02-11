if (config.ai_bot)
  App.support = App.cable.subscriptions.create "SupportChannel",
    connected: ->
      # Called when the subscription is ready for use on the server

    disconnected: ->
      # Called when the subscription has been terminated by the server

    received: (data) ->
      $('#conversations').append data.conversation
      $('#conversations').animate({scrollTop: $('#conversations')[0].scrollHeight}, 'fast')

    comment: (msg) ->
      @perform 'comment', message: msg

  $(document).on 'click', '#btn_question', (event) ->
    question = $('#txt_question').val().trim()
    if (question != "")
      App.support.comment question
      event.target.value = ''
      event.preventDefault()
