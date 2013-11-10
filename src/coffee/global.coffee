#
# crimson - desktop social network client
# ---
# @copyright (c) 2013 Damian Bushong <katana@codebite.net>
# @license MIT license
# @url <https://github.com/damianb/crimson>
# @twitter <https://twitter.com/burningcrimson>
#

#
# - special requires
#

fs = require 'fs'
debug = (require 'debug')('global')
dateFormat = require 'dateformat'
escapeHTML = require 'escape-html'

#
# - global object prototype modifications...
#

global.Array::remove = Array::remove = (from, to) ->
	rest = @slice (to or from) + 1 or @length
	@length = if from < 0 then @length + from else from
	@push.apply @, rest

# better than using Array::filter because it's short-circuit - we waste less time once we have our hits.
# please also note, this use OR logic. only one of the supplied params must be present in the array.
global.Array::has = Array::has = (entries...) ->
	hasEntries = true
	process = =>
		if (@indexOf entries.shift()) is -1
			hasEntries = false
	process() until hasEntries is false or entries.length is 0
	hasEntries

global.String::escapeHTML = String::escapeHTML = ->
	escapeHTML @

global.Date::format = Date::format = (mask, utc) ->
	dateFormat @, mask, utc

# global muckery...yuck. ;_;

# this must only be done AFTER jq has loaded...if it's not there, just skip it.
if $? then global.$ = $
global.gui = gui = require 'nw.gui'

# crit logging
global.handleCrit = handleCrit = (err) ->
	debug 'critical: ' + err
	console.error err
	fs.appendFileSync './error.log', "#{new Date()}\n #{err.stack}\n"
	process.exit 1

process.on 'uncaughtException', handleCrit
