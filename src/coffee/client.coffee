# todo refactor for multi-user
crimson.on 'user.ready', (user, first) ->
	crimson.kickstart()
	# if the first user to connect...
	if first
		display 'client'
		column 'home'

crimson.on 'user.ready', () ->
	console.log 'connected!'

crimson.on 'auth.pending', () ->
	if Object.keys(crimson.users).length is 0 and crimson.tokenStore.length is 0
		display 'auth'

###
crimson.timelines.home.on 'newPing', (ping) ->
	# todo react, append!
	jade.compile # ...
	$('.timeline#home').append()

crimson.timelines.notify.on 'newPing', (ping) ->
	# todo
###

# todo: webkitNotification?
