###
crimson - desktop social network client
---
author: Damian Bushong <katana@codebite.net>
license: MIT license
url: https://github.com/damianb/crimson
twitter: https://twitter.com/burningcrimson
###

#
# - global object prototype modifications...
#

global.Array::remove = (from, to) ->
	rest = @slice (to or from) + 1 or @length
	@length = if from < 0 then @length + from else from
	@push.apply @, rest

global.Array::has = (entries...) ->
	hasEntries = true
	process = =>
		if (@indexOf entries.shift()) is -1
			hasEntries = false
	process() until hasEntries is false or entries.length is 0
	hasEntries


escapeHTML = require 'escape-html'
global.String::escapeHTML = ->
	escapeHTML @

dateFormat = require 'dateformat'
global.Date::format = (mask, utc) ->
	dateFormat @, mask, utc

# global muckery...yuck. ;_;

global.$ = $
global.gui = gui = require 'nw.gui'
mainWindow = gui.Window.get()

# special requires

# we need to make this a global to prevent gc
global.crimson = crimson = require './assets/js/crimson/core'

domain = require 'domain'
fs = require 'fs'
debug = (require 'debug')('client')

# initially, we are NOT in debug mode. we have to key-sequence our way into debug mode, and answer
# a series of three questions to the Keeper of the Bridge, else we be cast into the depths beyond.
DEBUG = false

# working around a node-webkit bug on windows
# ref: https://github.com/rogerwang/node-webkit/issues/253
mainWindow.on 'minimize', ->
	width = mainWindow.width
	mainWindow.once 'restore', ->
		if mainWindow.width isnt width then mainWindow.width = width

process.on 'uncaughtException', (err) ->
	debug 'uncaught exception: ' + err
	console.error err
	fs.appendFileSync './error.log', "#{new Date()}\n #{err.stack}"
	# process.exit 1

d = domain.create()
d.on 'error', (err) ->
	debug 'caught error: ' + err
	console.error err
	fs.appendFileSync './error.log', "#{new Date()}\n #{err.stack}"

d.run ->
	#
	# - client event binds
	#

	crimson.on 'user.ready', (user, first) ->
		###
		# if the first user to connect, we need to display the client chrome and the home column
		###

	crimson.on 'user.ready', ->
		console.log 'connected!'

	crimson.on 'user.noaccount', ->
		console.log "no account, opening authorize account window"
		# todo, prepare authorize template
		gui.Window.open 'authorize.html', {
			position: 'center'
			height: 500
			width: 500
		}

	#
	# - key binds
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
