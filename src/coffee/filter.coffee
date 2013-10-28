#
# crimson - desktop social network client
# ---
# @copyright (c) 2013 Damian Bushong <katana@codebite.net>
# @license MIT license
# @url <https://github.com/damianb/crimson>
# @twitter <https://twitter.com/burningcrimson>
#

{EventEmitter} = require 'events'
debug = (require 'debug')('filter')

#
# the filter class will handle filter management and notifying the DOM of filter updates
#
class filter extends EventEmitter
	constructor: (@preferencesDb, @eventsDb) ->
		@users = []
		@sources = []
		@text = []
		@preferencesDb.findOne { key: 'filter' }, (err, doc) =>
			if err
				debug 'filter.constructor nedb err: ' + err
				return err

			if doc
				@users = doc.filters.users
				@sources = doc.filters.sources
				@text = doc.filters.text

		super()
	addFilter: () ->
		# emit something so that all events db items are refiltered.
		# this will take an nedb query, at least
		# todo

	remFilter: () ->
		# todo
		# IT SHOULD ALWAYS BE IN THE DOM, JUST NOT VISIBLE! (display:none) so we don't lose where it is in the DOM!
		# todo: emit something to trigger dom modifications, nedb updates

