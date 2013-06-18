crimson.on 'connected', () ->
	display 'client'
	column 'home'
	crimson.heartbeat()
	setInterval () ->
		crimson.heartbeat()
	, 5 * 1000

crimson.on 'connected', () ->
	console.log 'connected!'

crimson.on 'connected', (client) ->
	client.users.me (err, json, res) ->
		if err then bigError(err)
		client.me = json

# todo - replace auth display with an entirely different window?
crimson.on 'pendingAuth', () ->

	#if Object.keys(crimson.users).length is 0
		#display 'auth'

	#else
		# todo

###
crimson.timelines.home.on 'newPing', (ping) ->
	# todo react, append!
	jade.compile # ...
	$('.timeline#home').append()

crimson.timelines.notify.on 'newPing', (ping) ->
	# todo
###

# todo: webkitNotification?
