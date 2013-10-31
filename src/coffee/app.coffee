#
# crimson - desktop social network client
# ---
# @copyright (c) 2013 Damian Bushong <katana@codebite.net>
# @license MIT license
# @url <https://github.com/damianb/crimson>
# @twitter <https://twitter.com/burningcrimson>
#

controllers = require './assets/js/crimson/controllers'
negotiator = require './assets/js/crimson/negotiator'
director = require './assets/js/crimson/director'

debug = (require 'debug')('app')
nedb = require 'nedb'
path = require 'path'
{ gui, $ } = global

angular.module('crimson', [])
	.factory('gui', ->
		gui
	)
	.factory('manifest', ->
		gui.App.manifest
	)
	.factory('preferencesDb', ->
		#
		# this database is created with the intention of storing appliation preferences
		#
		db = new nedb { autoload: true, nodeWebkitAppName: 'crimson', filename: 'prefs.db' }
		# todo constraints
		#  preferences: array of unique keys
		db
	)
	.factory('accountsDb', ->
		#
		# this database is created with the intention of storing account credentials and -minor- preferences
		#
		db = new nedb { autoload: true, nodeWebkitAppName: 'crimson', filename: 'users.db' }
		# todo constraints
		#  users: same as above. keys are by user.id
		db
	)
	.factory('eventsDb', ->
		#
		# this database is created to store all twitter events in memory for queries.
		#   again, it is stored in memory -ONLY-. on close, all data is lost. count on nothing.
		#   it may also be periodically purged for GC purposes. anything received X hours ago could be a candidate for dumping.
		#
		db = new nedb { autoload: true }
		# todo constraints
		#  events...special situation. unique index by event.id_str ? event.eventType?
		db
	)
	.factory('broadcast', ->
		# todo
	)
	.factory('negotiator', ->
		new negotiator()
	)
	.factory('filter', ['preferencesDb', 'eventsDb', (db, events) ->
		new filter db, events
	])
	.factory('users', ['accountsDb', 'negotiator', (db, neg) ->
		new director db, neg
	])
