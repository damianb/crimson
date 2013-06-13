
crimson = new _crimson()

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
