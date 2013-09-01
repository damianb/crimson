{EventEmitter} = require 'events'
qs = require 'querystring'
url = require 'url'

async = require 'async'
debug = (require 'debug')('core')
nedb  = require 'nedb'
request = require 'request'
twit = require 'twit'

{ gui } = global

stream = require './stream'
timeline = require './timeline'
ui = require './ui'

class crimson extends EventEmitter
	constructor: ->
		@appTokens =
			# todo update with actual tokens
			consumer_key: new Buffer 'Y1M0bm9NWFNEWjh1a1VHU2djeFVR', 'base64'
			consumer_secret: new Buffer 'QjByblViRmVFUDkzMFdKaVdlcGZ5b1RYM1hVUVJ2UTFrVEVTWXFXNjg=', 'base64'
		@pkg = gui.App.manifest
		@ui = ui

		#
		# the following three databases are divvied up as follows:
		# preferences: application preferences (duh)
		# user: user credential database (token storage, etc)
		#  userId: user's string id
		#  token: oauth token
		#  secret: oauth secret token
		# event: in-memory database of recent stream events. will be purged of old content on an interval to reduce memory nommage
		#
		@db =
			preferences: new nedb { autoload: true, nodeWebkitAppName: 'crimson', filename: 'prefs.db' }
			accounts: new nedb { autoload: true, nodeWebkitAppName: 'crimson', filename: 'users.db' }
			#users: new nedb { autoload: true }
			# may be used for quick lookup of user accounts - we'll upsert as needed to update.
			# would provide us with a good method of autocomplete
			events: new nedb { autoload: true }
		# todo: index constraints
		#  preferences: array of unique keys
		#  users: same as above. keys are by user.id
		#  events...special situation. unique index by event.id_str ? event.eventType?

		@timelines =
			super:
				superhome: null
				supernotify: null
			user: {}
		@users = {}

		# establish filters in the core, to prevent unnecessary duplication in memory
		@filtered =
			users: []
			sources: []
			text: []

		@db.preferences.findOne { key: 'filter' }, (err, doc) =>
			if err
				debug 'core.constructor nedb err: ' + err
				return err

			if doc
				@filtered.users = doc.filters.users
				@filtered.sources = doc.filters.sources
				@filtered.text = doc.filters.text

		# todo filter management

		super()

		# hooking these up after calling super() so that eventemitter is ready.
		@timelines.super.superhome = new timeline 'superhome', { crimson: @ }
		@timelines.super.supernotify = new timeline 'supernotify', { crimson: @ }

	connectAll: (fn) ->
		@db.accounts.find { enabled: true }, (err, tokens) =>
			if err
				debug 'crimson.connectAll nedb err: ' + err
				return fn err

			if tokens.length is 0
				@emit 'user.noaccount'
				# the above should indicate that the user needs to add an account.
				fn null, tokens.length
			else
				async.each tokens, @connect.bind(@), (err) ->
					if err
						debug 'crimson.connectAll err: ' + err
						return fn err
					fn null, tokens.length

	connect: (account, fn) ->
		if @users[account.userId]?
			return @users[account.userId]

		# init an object for the user
		user =
			api: @getApi(account.token, account.secret)
			crimson: @
			stream: null # will hold a stream object, which wraps twit streams
			id: account.userId
			profile: null
			friends: []
			blocked: []
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
				#
		], (err) =>
			if err
				debug 'crimson.connect err: ' + err
				return fn err

			@emit 'user.ready', user
			fn null, user

	getAuthUri: (fn) ->
		oauth =
			# has to be oob as per twitter docs
			callback: 'oob'
			consumer_key: @appTokens.consumer_key.toString()
			consumer_secret: @appTokens.consumer_secret.toString()

		request.post { url: 'https://api.twitter.com/oauth/request_token', oauth:oauth }, (err, res, body) ->
			if err
				debug 'crimson.getAuthUri err: ' + err
				return fn err
			tokens = qs.parse body

			if !tokens.oauth_callback_confirmed
				err = 'oauth_callback_confirmed return from twitter api as false'
				debug 'crimson.getAuthUri err: ' + err
				return fn err

			fn null, tokens.oauth_token, url.format {
				protocol: 'https'
				hostname: 'api.twitter.com'
				pathname: '/oauth/authorize'
				query:
					oauth_token: tokens.oauth_token
			}

	# pin will be used as the verifier, as per https://dev.twitter.com/docs/auth/pin-based-authorization
	tradePinForTokens: (token, pin, fn) ->
		oauth =
			consumer_key: @appTokens.consumer_key.toString()
			consumer_secret: @appTokens.consumer_secret.toString()
			token: token
			verifier: pin
		request.post { url: 'https://api.twitter.com/oauth/access_token', oauth:oauth }, (err, res, body) =>
			if err
				debug 'crimson.tradePinForTokens err: ' + err
				return fn err

			tokens = qs.parse body

			if !tokens.user_id
				err = 'No user_id received from twitter API - authentication failed?'
				debug 'crimson.tradePinForTokens err: ' + err
				return fn err

			# insert into users db
			@db.accounts.insert {
				token: tokens.oauth_token
				secret: tokens.oauth_token_secret
				userId: tokens.user_id
			}, (err, doc) ->
				if err
					debug 'crimson.tradePinForTokens nedb err: ' + err
					return fn err
				fn null, doc

	# get a new twitter api instance (will provide streaming, etc.)
	getApi: (token, secret) ->
		return new twit({
			consumer_key: @appTokens.consumer_key.toString()
			consumer_secret: @appTokens.consumer_secret.toString()
			access_token: token
			access_token_secret: secret
		})

	addFilter: () ->
		# emit something so that all events db items are refiltered.
		# this will take an nedb query, at least
		# todo

	remFilter: () ->
		# todo
		# IT SHOULD ALWAYS BE IN THE DOM, JUST NOT VISIBLE! (display:none) so we don't lose where it is in the DOM!
		# todo: emit something to trigger dom modifications, nedb updates

	# shutdown procedures - should handle cleanup
	__destroy: ->
		@emit '__destroy'
		user.stream.__destroy() for user of @users

module.exports = new crimson()
