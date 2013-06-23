Array::remove = (from, to) ->
	rest = @slice (to or from) + 1 or @length
	@length = if from < 0 then @length + from else from
	return @push.apply @, rest


gui = require 'nw.gui'
crimson = require './crimson'
crimson.ui = require './ui'
dataStream = require './datastream'
timeline = require './timeline'

DEBUG = false

###
client event binds
###

crimson.on 'user.ready', (user, first) ->
	# if the first user to connect, we need to display the client chrome and the home column
	if first
		display 'client'
		column 'home'
	# kickstart my heart!
	crimson.kickstart()

crimson.on 'user.ready', ->
	console.log 'connected!'

crimson.on 'auth.pending', ->
	# display the auth chrome if we don't have any tokens
	if Object.keys(crimson.users).length is 0 and crimson.tokenStore.length is 0
		display 'auth'

###
 key binds
###

if DEBUG #todo make this pkg.version dependent somehow
	$(document).on 'keydown', null, 'ctrl+F12', ->
		DEBUG = true
	$(document).on 'keydown', null, 'ctrl+j', ->
		win = gui.Window.get()
		win.showDevTools()
		return null
	$(document).on 'keydown', null, 'ctrl+r', ->
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
$('button#private').on 'click', null, ->
	if !$('button#private').hasClass 'active'
		crimson.ui.counters['#pingText'].max = 400
	else
		crimson.ui.counters['#pingText'].max = 200
	crimson.ui.counters['#pingText'].charCount()

$().ready ->
	$('#version').text "node-webkit #{process.versions['node-webkit']}; node #{process.version}; crimson DEV build"
	display 'load'
	display 'client'
	column 'home'
	#crimson.connect()
