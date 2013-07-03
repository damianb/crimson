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

escapeHTML = require 'escape-html'
global.String::escapeHTML = ->
	return escapeHTML @

dateFormat = require 'dateformat'
global.Date::format = (mask, utc) ->
	dateFormat @, mask, utc

# global muckery...eugh

global.localStorage = localStorage
global.$ = $
global.gui = gui = require 'nw.gui'

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
		crimson.connectAll()

	# sample data, for now

	global.sampleJSON = sampleJSON = { "response" : [
		{
			"id": 12188547,
			"text": "@uppfinnarn shows just fine in my stack traces on an exception.",
			"user_id": 1688760,
			"echo_id": null,
			"reply_id": 12187793,
			"checkin": false,
			"created_at": "2013-06-24T12:17:31Z",
			"user": {
					"id": 1688760,
					"username": "katana",
					"name": "Damian Bushong",
					"bio": "Burning a hole through the past and lighting the path into the future.",
					"website": "",
					"location": "",
					"timezone": "Central Time (US & Canada)",
					"created_at": null,
					"avatar": "//d2trw7474qpa0b.cloudfront.net/katana/thumb.jpg?49c663f527fa2998953bbb65f631c5ed",
					"background": "//d2dh8keolssd5w.cloudfront.net/default.png",
					"cover": "//d38xdbig8ajh16.cloudfront.net/default.png",
					"metadata": {
							"ping_count": 259,
							"checkin_count": 0,
							"listener_count": 29,
							"listening_count": 7
					}
			},
			"media": {},
			"metadata": {
					"echo_count": 0,
					"reply_count": 0,
					"can_reply": true,
					"can_delete": true,
					"can_echo": false,
					"is_private": false
			},
			"replies": []
		},

		{
			"id": 12771311,
			"type": "echo",
			"created_at": "2013-06-11T05:50:53Z",
			"data": {
				"ping": {
					"id": 11545705,
					"text": null,
					"user_id": 1984189,
					"echo_id": 11275595,
					"reply_id": null,
					"checkin": false,
					"created_at": "2013-06-11T05:50:53Z",
					"user": {
						"id": 1984189,
						"username": "amarnath",
						"name": "Amarnath Verma",
						"bio": "",
						"website": "",
						"location": "",
						"timezone": "Kolkata",
						"created_at": "2013-05-31T05:52:28Z",
						"avatar": "//d2trw7474qpa0b.cloudfront.net/amarnath/thumb.jpg?6e5fbb03cda86bda4dac28ad92340046",
						"background": "//d2dh8keolssd5w.cloudfront.net/default.png",
						"cover": "//d38xdbig8ajh16.cloudfront.net/amarnath/thumb.jpg?9ef17face99ce40dde0ccaf8b29dc873",
						"metadata": {
							"ping_count": 338,
							"checkin_count": 4,
							"listener_count": 10,
							"listening_count": 83,
							"listening": false,
							"listens": false
						}
					},
					"media": {},
					"echo": {
						"id": 11275595,
						"text": "How not to get an audit: \r\n<malerzril> Hey all, I am looking for someone to pentest/audit my code for any noticeable security flaws\r\n<pronto> how much are you paying?\r\n<malerzril> 100$\r\n<soot> heh",
						"user_id": 1688760,
						"echo_id": null,
						"reply_id": null,
						"checkin": false,
						"created_at": "2013-06-04T14:25:10Z",
						"user": {
							"id": 1688760,
							"username": "katana",
							"name": "Damian Bushong",
							"bio": "Burning a hole through the past and lighting the path into the future.",
							"website": "",
							"location": "",
							"timezone": "Central Time (US & Canada)",
							"created_at": null,
							"avatar": "//d2trw7474qpa0b.cloudfront.net/katana/thumb.jpg?1aa31f75916f1e69c17373b3087399b3",
							"background": "//d2dh8keolssd5w.cloudfront.net/default.png",
							"cover": "//d38xdbig8ajh16.cloudfront.net/default.png",
							"metadata": {
								"ping_count": 233,
								"checkin_count": 0,
								"listener_count": 26,
								"listening_count": 6
							}
						},
						"media": {},
						"metadata": {
							"echo_count": 2,
							"reply_count": 0,
							"can_reply": true,
							"can_delete": true,
							"can_echo": false,
							"is_private": false
						}
					},
					"metadata": {
						"echo_count": 0,
						"reply_count": 0,
						"can_reply": true,
						"can_delete": false,
						"can_echo": true,
						"is_private": false
					}
				},
				"user": {
					"id": 1984189,
					"username": "amarnath",
					"name": "Amarnath Verma",
					"bio": "",
					"website": "",
					"location": "",
					"timezone": "Kolkata",
					"created_at": "2013-05-31T05:52:28Z",
					"avatar": "//d2trw7474qpa0b.cloudfront.net/amarnath/thumb.jpg?6e5fbb03cda86bda4dac28ad92340046",
					"background": "//d2dh8keolssd5w.cloudfront.net/default.png",
					"cover": "//d38xdbig8ajh16.cloudfront.net/amarnath/thumb.jpg?9ef17face99ce40dde0ccaf8b29dc873",
					"metadata": {
						"ping_count": 338,
						"checkin_count": 4,
						"listener_count": 10,
						"listening_count": 83,
						"listening": false,
						"listens": false
					}
				}
			}
		},
	]}
