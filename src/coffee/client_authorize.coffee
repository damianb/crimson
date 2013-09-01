###
crimson - desktop social network client
---
author: Damian Bushong <katana@codebite.net>
license: MIT license
url: https://github.com/damianb/crimson
twitter: https://twitter.com/burningcrimson
###

# Just doing this for clarity's sake.
crimson = global.crimson
gui = global.gui

domain = require 'domain'

if !crimson
	throw new Error 'crimson global not found - brb seppuku'

curwindow = gui.Window.get()

# working around a node-webkit bug on windows
# ref: https://github.com/rogerwang/node-webkit/issues/253
curwindow.on 'minimize', ->
	width = curwindow.width
	curwindow.once 'restore', ->
		if curwindow.width isnt width then curwindow.width = width

# initially, we are NOT in debug mode. we have to key-sequence our way into debug mode, and answer
# a series of three questions to the Keeper of the Bridge, else we be cast into the depths beyond.
DEBUG = false

d = domain.create()
d.on 'error', global.handleCrit

oauthToken = null
d.run ->
	$(document).on 'keydown', null, 'ctrl+F12', ->
		DEBUG = !DEBUG
		$('footer').toggle()

	$(document).on 'keydown', null, 'ctrl+j', ->
		if DEBUG
			gui.Window.get().showDevTools()
	$(document).on 'keydown', null, 'ctrl+r', ->
		if DEBUG
			gui.Window.get().reloadIgnoringCache()

	$().ready ->
		$('#apin').hide()
		$('#authorize').click ->
			# grab authorize URI, then open the browser window
			crimson.getAuthUri (err, oauth_token, uri) ->
				if err
					# todo, figure out how best to handle this
					return

				oauthToken = oauth_token
				$('#apin').show()
				$('#abutton').hide()

				console.log uri

				gui.Shell.openExternal(uri)
		$('#sendpin').click ->
			crimson.tradePinForTokens oauthToken, $('#pin').val(), (err, doc) ->
				if err
					# todo, figure out how best to handle this
					return
				crimson.connect doc, (err, user) ->
					if err
						# todo, figure out how to best handle this
						return
					curwindow.close()

		# todo
		# bind to authorize button, open a new browser window to get the user to authenticate, and then wait for the pin...
		# afterwards, try with the pin, see if we get something legit, then go!
