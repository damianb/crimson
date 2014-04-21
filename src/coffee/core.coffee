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

{EventEmitter} = require 'events'
debug = (require 'debug')('core')
nedb = require 'nedb'
path = require 'path'
{gui, $} = global

compost = require './compost'
director = require './director'
filter = require './filter'
navigator = require './navigator'
negotiator = require './negotiator'

class Core extends EventEmitter
	constructor: () ->
		# todo db constraints
		@gui = gui
		@pkg = gui.App.manifest
		@db =
			preferences: new nedb { autoload: true, nodeWebkitAppName: 'crimson', filename: 'prefs.db' }
			# todo constraints
			#  preferences: array of unique keys
			accounts: new nedb { autoload: true, nodeWebkitAppName: 'crimson', filename: 'users.db' }
			# todo constraints
			#  users: same as above. keys are by user.id
			events: new nedb { autoload: true }
			# todo constraints
			#  events...special situation. unique index by event.id_str ? event.eventType?
			errors: new nedb { autoload: true, nodeWebkitAppName: 'crimson', filename: 'error.db' }
		@compost = new compost @, @db.errors
		@negotiator = new negotiator @
		@filter = new filter @, @db.preferences, @db.events
		@navigator = new navigator @
		@director = new director @, @db.accounts

		super()
