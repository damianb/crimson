###
 key binds
###

if DEBUG #todo make this pkg.version dependent somehow
	$(document).on 'keydown', null, 'ctrl+j', () ->
		win = gui.Window.get()
		win.showDevTools()
		return null
	$(document).on 'keydown', null, 'ctrl+r', () ->
		win = gui.Window.get()
		win.reloadIgnoringCache()
		return null

###
 button binds
###

$('button#authorize').on 'click', null, () ->
	gui.Shell.openExternal crimson.authURI '0000'

###
 ui binds
###

crimson.ui.counter('#pingText', '#charcount', 200)
$('button#private').on 'click', null, () ->
	if !$('button#private').hasClass 'active'
		crimson.ui.counters['#pingText'].max = 400
	else
		crimson.ui.counters['#pingText'].max = 200
	crimson.ui.counters['#pingText'].charCount()

$().ready(() ->
	$('#version').text "node-webkit #{process.versions['node-webkit']}; node #{process.version}; crimson DEV build"
	display 'load'
	display 'client'
	column 'home'
	#crimson.connect()
)

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
