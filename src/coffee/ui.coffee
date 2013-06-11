
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

counter('#pingText', '#charcount', 200)
$('#version').text "node-webkit #{process.versions['node-webkit']}; node #{process.version}; crimson DEV build"
$().ready(() ->
	$('.client').removeClass 'hide'
)
