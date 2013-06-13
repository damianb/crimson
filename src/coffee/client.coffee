crimson.on 'connected', () ->
	display 'client'
	column 'home'
	crimson.heartbeat()
	setInterval () ->
		crimson.heartbeat()
	, 5 * 1000

crimson.on 'connected', () ->
	console.log 'connected!'

###
crimson.timelines.home.on 'newPing', (ping) ->
	# todo react, append!
	jade.compile # ...
	$('.timeline#home').append()

crimson.timelines.notify.on 'newPing', (ping) ->
	# todo
###

# todo: webkitNotification?
