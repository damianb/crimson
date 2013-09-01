###
crimson - desktop social network client
---
author: Damian Bushong <katana@codebite.net>
license: MIT license
url: https://github.com/damianb/crimson
twitter: https://twitter.com/burningcrimson
###

# we need to make this a global to prevent gc
global.crimson = crimson = require './assets/js/crimson/core'
domain = require 'domain'

# initially, we are NOT in debug mode. we have to key-sequence our way into debug mode, and answer
# a series of three questions to the Keeper of the Bridge, else we be cast into the depths beyond.
DEBUG = false

curwindow = gui.Window.get()

# working around a node-webkit bug on windows
# ref: https://github.com/rogerwang/node-webkit/issues/253
curwindow.on 'minimize', ->
	width = curwindow.width
	curwindow.once 'restore', ->
		if curwindow.width isnt width then curwindow.width = width

d = domain.create()
d.on 'error', global.handleCrit

d.run ->
	#
	# - client event binds
	#

	crimson.on 'user.ready', (user) ->
		###
		# if the first user to connect, we need to display the client chrome and the home column
		###

	crimson.on 'user.ready', (user) ->
		console.log 'connected! uid: ' + user.userId

	crimson.on 'user.noaccount', ->
		console.log "no account, opening authorize account window"
		# todo, prepare authorize template
		gui.Window.open 'authorize.html', {
			position: 'center'
			height: 280
			width: 440
		}

	#
	# - special key binds
	# - there will be no compromise. these will not be allowed to be used
	#

	$(document).on 'keydown', null, 'ctrl+F12', ->
		DEBUG = !DEBUG
		$('footer').toggle()

	$(document).on 'keydown', null, 'ctrl+j', ->
		if DEBUG
			gui.Window.get().showDevTools()
	$(document).on 'keydown', null, 'ctrl+r', ->
		if DEBUG
			gui.Window.get().reloadIgnoringCache()

	#
	# - ui binds
	#

	# todo refactor
	crimson.ui.counter('#tweetText', '#charcount', 140)

	$().ready ->
		$('#version').text("nw #{process.versions['node-webkit']}; node #{process.version}; crimson #{crimson.pkg.version}")
		$('footer').hide()
		crimson.ui.display 'load'

		$('.reldate').relatizeDateTime()
		setInterval ->
			$('.reldate').relatizeDateTime()
		, 45 # todo, maybe make 15 second intervals?

		crimson.connectAll (err, accountCount) ->
			if err then return console.log err
			console.log "#{accountCount} accounts connected"
