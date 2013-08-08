{EventEmitter} = require 'events'
debug = (require 'debug')('core')
http = require 'http'
url = require 'url'
qs = require 'querystring'
twit = require 'twit'
nedb  = require 'nedb'
request = require 'request'
pkg = require './../../package.json'
dataStream = require './datastream'

class crimson extends EventEmitter
	constructor: ->
		@appTokens =
			consumer_key: new Buffer('', 'base64')
			consumer_secret: new Buffer('', 'base64')
		@pkg = pkg

		@ui = null

		#
		# the following three databases are divvied up as follows:
		# preferences: application preferences (duh)
		# user: user credential database (token storage, etc)
		#  userId: user's string id
		#  token: oauth token
		#  secret: oauth secret token
		# tweet: in-memory database of recent tweets. will be purged of old content on an interval to reduce memory nommage
		#
		@db =
			preferences: new nedb { nodeWebkitAppName: 'crimson', filename: 'prefs.db' }
			user: new nedb { nodeWebkitAppName: 'crimson', filename: 'users.db' }
			tweet: new nedb()

		@users = {}
		@heartbeat = true

		super()

	connectAll: (fn) ->
		@db.user.find { enabled: true }, (err, tokens) =>
			if err
				debug 'crimson.connectAll nedb err: ' + err
				return fn err

			if tokens.length is 0
				@emit 'user.noaccount'
				# the above should indicate that the user needs to add an account.
			else
				@connect token for token in tokens when token isnt null

	connect: (account) ->
		# todo check if user already connected

		if users[account.userId]?
			return users[account.userId]


		# init an object for the user
		user =
			api: @getApi(account.token, account.secret)
			crimson: @
			data: null
			id: account.userId
			profile: null

		# todo finish

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
				pathname: '/oauth/oauthorize'
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
			# insert into users db
			@db.users.insert {
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
		return new twit {
			consumer_key: @appTokens.consumer_key.toString()
			consumer_secret: @appTokens.consumer_secret.toSting()
			access_token: token
			access_token_secret: secret
		}

	# shutdown procedures - should handle cleanup
	__destroy: ->
		# stop heartbeat
		#@halt()
		# ensure token store is completely up to date
		@updateTokenStore()
		@emit '__destroy'
		user.data.__destroy() for user of @users

module.exports = new crimson()
