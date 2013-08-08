###
crimson - desktop heello client
---
author: Damian Bushong <katana@codebite.net>
license: MIT license
url: https://github.com/damianb/crimson
heello: https://heello.com/katana
twitter: https://twitter.com/burningcrimson
###

#
# - global object prototype modifications...
#

global.Array::remove = (from, to) ->
	rest = @slice (to or from) + 1 or @length
	@length = if from < 0 then @length + from else from
	return @push.apply @, rest

global.Array::has = (entries...) ->
	hasEntries = true
	process = () =>
		if @indexOf(entries.shift()) is -1 then hasEntries = false
		null
	process() until hasEntries is false or entries.length is 0
	return hasEntries

# todo - deprecate the following two globals

###
# the following are based on the autolink-js tool by bryanwoods on github: https://github.com/bryanwoods/autolink-js
global.String::autolink = ->
	pattern = ///
		(^|\s)
		(
			(?:https?|ftp):// # Look for a valid URL protocol (non-captured)
			[\w\-+\u0026@#/%?=~|!:,.;]*# Valid URL characters (any number of times)
			[\w\-+\u0026@#/%=~|] # String must end in a valid URL character
		)
	///gi

	if arguments.length is 0
		return @replace(pattern, "$1<a href='$2'>$2</a>")

	options = Array::slice.call(options)
	linkAttributes = (" #{k}='#{v}'" for k, v of options when k isnt 'callback').join ''
	return @replace pattern, (match, space, url) ->
		link = options.callback?(url) or "<a href='#{url}'#{linkAttributes}>#{url}</a>"
		"#{space}#{link}"

global.String::autousername = ->
	pattern = /(^|\s)@([\w]{1,18})/g
	uriBase = 'https://heello.com/'
	if arguments.length is 0
		return @replace(pattern, "$1<a href='#{uriBase}'>@$2</a>")

	options = Array::slice.call(options)
	linkAttributes = (" #{k}='#{v}'" for k, v of options when k isnt 'callback').join ''
	return @replace pattern, (match, space, username) ->
		link = options.callback?(url) or "<a href='#{uriBase}#{url}'#{linkAttributes}>@#{username}</a>"
		"#{space}#{link}"
###

escapeHTML = require 'escape-html'
global.String::escapeHTML = ->
	return escapeHTML @

dateFormat = require 'dateformat'
global.Date::format = (mask, utc) ->
	dateFormat @, mask, utc

# global muckery...yuck. ;_;

global.localStorage = localStorage
global.$ = $
global.gui = gui = require 'nw.gui'
mainWindow = gui.Window.get()

# special requires

crimson = require './assets/js/crimson'
crimson.ui = require './assets/js/ui'
dataStream = require './assets/js/datastream'
timeline = require './assets/js/timeline'
domain = require 'domain'
fs = require 'fs'

# initially, we are NOT in debug mode. we have to key-sequence our way into debug mode, and answer
# a series of three questions to the Keeper of the Bridge, else we be cast into the depths beyond.
DEBUG = false

# working around a node-webkit bug on windows
# ref: https://github.com/rogerwang/node-webkit/issues/253
mainWindow.on 'minimize', ->
	width = mainWindow.width
	mainWindow.once 'restore', ->
		if mainWindow.width isnt width
			mainWindow.width = width

process.on 'uncaughtException', (err) ->
	fs.writeFileSync './error.log', err.stack

d = domain.create()
d.on 'error', (err) ->
	fs.writeFileSync './error.log', err.stack

d.run ->
	#
	# - client event binds
	#

	crimson.on 'user.ready', (user, first) ->
		###
		# if the first user to connect, we need to display the client chrome and the home column
		if first
			crimson.ui.display 'client'
			crimson.ui.column 'home'

			displayResponse = (responses) ->
				$('.column[data-column="superhome"]').prepend(crimson.ui.entryTemplate({
					entries: responses
				}))
			user.data.on 'ping.new', displayResponse
			user.data.on 'echo.new.ofmine', displayResponse
			user.data.forwardArray null,sampleJSON, null
		# kickstart my heart!
		crimson.kickstart()
		###

	crimson.on 'user.ready', ->
		console.log 'connected!'

	crimson.on 'auth.pending', ->
		# display the auth chrome if we don't have any tokens
		if Object.keys(crimson.users).length is 0 and crimson.tokenStore.length is 0
			crimson.ui.display 'auth'

	#
	# - key binds
	#

	$(document).on 'keydown', null, 'ctrl+F12', ->
		DEBUG = !DEBUG
		$('footer').toggle()

	$(document).on 'keydown', null, 'ctrl+j', ->
		if DEBUG
			gui.Window.get().showDevTools()
		return null
	$(document).on 'keydown', null, 'ctrl+r', ->
		if DEBUG
			gui.Window.get().reloadIgnoringCache()
		return null

	#
	# - button binds
	#

	$('button#authorize').on 'click', null, () ->
		gui.Shell.openExternal crimson.authURI

	#
	# - ui binds
	#

	crimson.ui.counter('#pingText', '#charcount', 200)
	$('button#private').on 'click', null, ->
		if !$('button#private').hasClass 'active'
			crimson.ui.counters['#pingText'].max = 400
		else
			crimson.ui.counters['#pingText'].max = 200
		crimson.ui.counters['#pingText'].charCount(false)

	$(window).resize ->
		# queue a redraw
		crimson.ui.viewport.resize()

	$().ready ->
		$('#version').text("nw #{process.versions['node-webkit']}; node #{process.version}; crimson #{crimson.pkg.version}")
		$('footer').hide()
		crimson.ui.display 'load'
		crimson.ui.display 'client'
		crimson.ui.column 'home'

		$('.reldate').relatizeDateTime()
		setInterval ->
			$('.reldate').relatizeDateTime()
		, 60
		#crimson.connectAll()
