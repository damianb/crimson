###
crimson - desktop social network client
---
author: Damian Bushong <katana@codebite.net>
license: MIT license
url: https://github.com/damianb/crimson
twitter: https://twitter.com/burningcrimson
###

#
# - special requires
#

fs = require 'fs'
debug = (require 'debug')('client')

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

# crit logging
global.handleCrit = (err) ->
	debug 'critical: ' + err
	console.error err
	fs.appendFileSync './error.log', "#{new Date()}\n #{err.stack}"
	process.exit 1

process.on 'uncaughtException', global.handleCrit
