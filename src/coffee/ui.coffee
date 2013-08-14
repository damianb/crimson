fs = require 'fs'
# nw-gui include (has to be globaled in)
gui = global.gui
jade = require 'jade'

class ui
	constructor: ->
		# cache the templates to save on memory
		@timelineTemplate = jade.compile (fs.readFileSync './assets/templates/timeline.jade'), { filename: './assets/templates/timeline.jade' }
		@entryTemplate = jade.compile (fs.readFileSync './assets/templates/entries.jade'), { filename: './assets/templates/entries.jade' }
		@counters = {}
		@throbInterval = null
	display: (state) ->
		throbbing = !($('.display.dis-load').hasClass 'hide')
		$('.display').addClass 'hide'
		$('.display.dis-' + state).removeClass 'hide'
		if state is 'load'
			@loadThrob()
		else if throbbing
			@loadThrob(false)
	column: (column) ->
		$('.column').addClass 'hide'
		$('.column.col-' + column).removeClass 'hide'
	counter: (_field, _display, max) ->
		field = $(_field)
		display = $(_display)
		counterData = @counters[_field] =
			field: field
			display: display
			max: max
			charCount: (visible = true) ->
				warn = counterData.max - (counterData.max / 5)
				text = counterData.field.val()
				switch
					when text.length >= counterData.max then counterData.display.addClass('lengthOver')
					when text.length >= warn then counterData.display.removeClass('lengthOver').addClass('lengthWarn')
					else counterData.display.removeClass('lengthOver lengthWarn')
				counterData.display.html counterData.max - text.length
				counterData.display.stop()
				if visible or text.length > 0 then counterData.display.fadeTo('fast', 1)
				return null

		field.bind 'keydown keyup keypress', counterData.charCount
		field.bind 'focus paste', =>
			setTimeout counterData.charCount, 10
			return null
		field.bind 'blur', =>
			if field.val().length is 0
				display.stop().fadeTo('fast', 0)
			return false
		display.html counterData.max
		display.stop().fadeTo(0, 0)
	loadThrob: (start = true) ->
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
			@throbInterval = setInterval throbFn, length * 1000, current
		else
			clearInterval @throbInterval
			$('.throbber span').removeClass 'pulse'
	bigError: (err) ->
		$('#errormsg').val err
		display 'fatal'
	logError: (err) ->
		# todo - file logging of errors? NeDB inserts? etc? *shrug*
		console.error err
		fs.writeFileSync './error.log', err.stack
		process.exit 1
	insertTimeline: (template, entries) ->

module.exports = new ui()
