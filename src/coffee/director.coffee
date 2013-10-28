{EventEmitter} = require 'events'
debug = (require 'debug')('director')

async = require 'async'

#
# the director class handles all user accounts and dispatching user-related events
#  todo: replace timeline calls with appropriate actions instead
#
class director extends EventEmitter
	constructor: (@accountsDb, @negotiator) ->
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
		@timelines.user[user.id] = {}
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
				user.stream.on '__destroy', =>
					# clean up the timelines reference here quickly when we have a __destroy emitted
					@timelines.user[user.id] = undefined
					@users[user.id] = undefined
				cb null
			(cb) =>
				# todo init timelines (ALL OF THE TIMELINES! :DDDDD)
				@timelines.user[user.id] =
					home: new timeline 'home', user
					mentions: new timeline 'mentions', user
					events: new timeline 'events', user
				cb null
			(cb) =>
				# initial api calls to populate timelines...
				cb null
		], (err) =>
			if err
				debug 'director.connect err: ' + err
				return fn err

			@emit 'user.ready', user
			fn null, user

module.exports = director
