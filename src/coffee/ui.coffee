fs = require 'fs'
jade = require 'jade'
{gui, $} = global

throb = null

module.exports =
	entryTemplate: jade.compile (fs.readFileSync './assets/templates/entries.jade'), { filename: './assets/templates/entries.jade' }

	counter: (_field, _display, max) ->
		field = $(_field)
		display = $(_display)
		charCount = (visible = true) ->
			warn = max - (max / 5)
			text = field.val()
			switch
				when text.length >= max then display.addClass('lengthOver')
				when text.length >= warn then display.removeClass('lengthOver').addClass('lengthWarn')
				else display.removeClass('lengthOver lengthWarn')
			display.html max - text.length
			display.stop()
			if visible or text.length > 0 then display.fadeTo('fast', 1)
			return null

		field.bind 'keydown keyup keypress', charCount
		field.bind 'focus paste', =>
			setTimeout charCount, 10
			return null
		field.bind 'blur', ->
			if field.val().length is 0
				display.stop().fadeTo('fast', 0)
			return false
		display.html max
		display.stop().fadeTo(0, 0)

	display: (state) ->
		throbbing = !($('.display.dis-load').hasClass 'hide')
		$('.display').addClass 'hide'
		$('.display.dis-' + state).removeClass 'hide'
		if state is 'load'
			@throbber()
		else if throbbing
			@throbber(false)

	throbber: (start = true) ->
		if !!start
			current = length = 1
			throbFn = =>
				if current is 5
					current = 1
				$('.throbber span').removeClass 'pulse'
				if current isnt 4
					$('.throbber span#t' + current++).addClass 'pulse'
				else
					current++
			throb = setInterval throbFn, length * 1000, current
		else
			if throb? then clearInterval throb
			$('.throbber span').removeClass 'pulse'
			null

	bigError: (err) ->
		$('#errormsg').val err
		@display 'fatal'

	logError: (err) ->
		# todo - file logging of errors? NeDB inserts? etc? *shrug*
		console.error err
		fs.writeFileSync './error.log', err.stack
		process.exit 1
