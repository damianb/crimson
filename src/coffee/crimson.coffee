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

		@ui = null
		@pkg = pkg
		@version = pkg.version

		#
		# the following three databases are divvied up as follows:
		# user: user credential database (token storage)
		# tweet: in-memory database of recent tweets. will be purged of old content on an interval to reduce memory nommage
		# preferences: application preferences (duh)
		#
		@db =
			user: new nedb { nodeWebkitAppName: 'crimson', filename: 'users.db' }
			tweet: new nedb()
			preferences: new nedb { nodeWebkitAppName: 'crimson', filename: 'prefs.db' }
		@users = {}
		@heartbeat = true

		super()

	connectAll: (fn) ->
		@db.user.find { enabled: true }, (err, tokens) =>
			if err
				debug 'crimson->connectAll err: ' + err
				return fn err

			if tokens.length is 0
				@emit 'user.noaccounts'
			else
				@connect token for token in tokens when token isnt null

	connect: (tokens) ->
		# init an object for the user
		user =
			api: null
			crimson: @
			data: null
			id: null
			profile: null

		# todo finish

	# todo: this may no longer be relevant
	###
	kickstart: ->
		if !@heartbeat?
			@heartbeat = setInterval =>
				@emit 'heartbeat'
			, 5 * 1000
	# stop client heartbeat
	halt: ->
		if @heartbeat?
			clearInterval @heartbeat
	###

	getAuthUri: (fn) ->
		oauth =
			callback: 'oob'
			consumer_key: crimson.consumer_key.toString()
			consumer_secret: crimson.consumer_secret.toString()

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
	tradePinForTokens: (token, pin, fn) ->
		oauth =
			consumer_key: crimson.consumer_key.toString()
			consumer_secret: crimson.consumer_secret.toString()
			token: token
			verifier: pin
		request.post { url: 'https://api.twitter.com/oauth/access_token', oauth:oauth }, (err, res, body) ->
			if err
				debug 'crimson.tradePinForTokens err: ' + err
				return fn err

			tokens = qs.parse body
			fn null, tokens.oauth_token, tokens.oauth_token_secret

	getApi: (token, secret) ->
		return new twit {
			consumer_key: crimson.consumer_key.toString()
			consumer_secret: crimson.consumer_secret.toSting()
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
