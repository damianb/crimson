#
# crimson - desktop social network client
# ---
# @copyright (c) 2013 Damian Bushong <katana@codebite.net>
# @license MIT license
# @url <https://github.com/damianb/crimson>
# @twitter <https://twitter.com/burningcrimson>
#

{EventEmitter} = require 'events'
debug = (require 'debug')('director')
async = require 'async'

#
# the director class handles all user accounts and dispatching user-related events
#  todo: replace timeline calls with appropriate actions instead. possibly timeline manager?
#
class director extends EventEmitter
	constructor: (@accountsDb, @navigator, @negotiator) ->
		@users = {}
		super()

	connectAll: (fn) ->
		@accountsDb.accounts.find { enabled: true }, (err, tokens) =>
			if err
				debug 'director.connectAll nedb err: ' + err
				return fn err

			if tokens.length is 0
				@emit 'user.noaccount'
				# the above should indicate that the user needs to add an account.
				fn null, tokens.length
			else
				async.each tokens, @connect.bind(@), (err) ->
					if err
						debug 'director.connectAll err: ' + err
						return fn err
					fn null, tokens.length

	connect: (account, fn) ->
		if @users[account.userId]?
			return @users[account.userId]

		# init an object for the user
		user =
			api: @negotiator.getApi(account.token, account.secret)
			crimson: @
			stream: null # will hold a stream object, which wraps twit streams
			id: account.userId
			profile: null
			friends: []
			blocked: []
		# todo replace with timeline manager object?
		@navigator.timelines.init user
		@users[user.id] = user

		async.waterfall [
			(cb) =>
				user.api.get 'blocks/ids', { stringify_ids: true }, (err, reply) =>
					if err then return cb err
					user.blocked = reply.ids
					cb null
			(cb) =>
				user.api.get 'users/show', { user_id: user.id, include_entities: true }, (err, reply) =>
					if err then return cb err
					user.profile = reply
					cb null
			(cb) =>
				# we don't want to init the stream until now, due to...stuff.
				user.stream = new stream user
				user.stream.on '__destroy', (user) =>
					# clean up the timelines reference here quickly when we have a __destroy emitted
					@navigator.delAccount user
					@users[user.id] = undefined
				cb null
			(cb) =>
				# order the timeline navigator to init base timelines...
				@navigator.addAccount user
#					home: new timeline 'home', user
#					mentions: new timeline 'mentions', user
#					events: new timeline 'events', user
				cb null
			(cb) =>
				# initial api calls to populate timelines...
				# todo: maybe this should be something in @navigator?
				cb null
		], (err) =>
			if err
				debug 'director.connect err: ' + err
				return fn err

			@emit 'user.ready', user
			fn null, user

module.exports = director
