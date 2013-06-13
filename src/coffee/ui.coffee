gui = require 'nw.gui'

counter = (field, display, max) ->
	[display, field] = [$(display), $(field)]
	warn = max - (max / 5)
	charCount = ->
		text = field.val()
		switch
			when text.length >= max then display.addClass('lengthOver')
			when text.length >= warn then display.removeClass('lengthOver').addClass('lengthWarn')
			else display.removeClass('lengthOver lengthWarn')
		display.html(max - text.length)
		display.stop().fadeTo('fast', 1)
		return null

	field.bind 'keydown keyup keypress', charCount
	field.bind 'focus paste', () ->
		setTimeout charCount, 10
		return null
	field.bind 'blur', () ->
		if field.val().length is 0
			display.stop().fadeTo('fast', 0)
		return false
	display.html(max)
	display.stop().fadeTo(0, 0)

display = (state) ->
	throbbing = !($('.display.dis-load').hasClass 'hide')
	$('.display').addClass 'hide'
	$('.display.dis-' + state).removeClass 'hide'
	if state is 'load'
		loadThrob()
	else if throbbing
		loadThrob(false)

column = (column) ->
	$('.main').addClass 'hide'
	$('.main#col-' + column).removeClass 'hide'

throbInterval = null
loadThrob = (start = true) ->
	if !!start
		current = 1
		length = 1
		throbFn = () ->
			if current is 5
				current = 1
			$('.throbber span').removeClass 'pulse'
			if current isnt 4
				$('.throbber span#t' + current++).addClass 'pulse'
		throbInterval = setInterval throbFn, length * 1000, current
	else
		clearInterval throbInterval
		$('.throbber span').removeClass 'pulse'

bigError = (msg) ->
	$('#errormsg').val msg
	display 'fatal'

$(document).on 'keydown', null, 'ctrl+j', () ->
	win = gui.Window.get()
	win.showDevTools()
	return null
$(document).on 'keydown', null, 'ctrl+r', () ->
	win = gui.Window.get()
	win.reloadIgnoringCache()
	return null
$('button#authorize').on 'click', null, () ->
	gui.Shell.openExternal crimson.heello.getAuthURI '0000'
counter('#pingText', '#charcount', 200)


$('#version').text "node-webkit #{process.versions['node-webkit']}; node #{process.version}; crimson DEV build"
$().ready(() ->
	display 'load'
)
