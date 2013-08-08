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
		@ui = null
		@pkg = pkg
		@version = pkg.version

		#
		# the following three databases are divvied up as follows:
		# user: user credential database (token storage)
		# tweet: in-memory database of recent tweets. will be purged of old content on an interval
		#
		@db =
			user: new nedb({ nodeWebkitAppName: 'crimson', filename: 'users.db' })
			tweet: new nedb()
		@users = {}

		#@heartbeat = null # this will hold a setInterval reference.

		# the below is for special unauthenticated stuff only
		# todo remove?
		#@twitter = crimson.getApi()
		super()
	updateTokenStore: ->
		localStorage.setItem 'refreshTokenStore', JSON.stringify @tokenStore
	connectAll: ->
		if Object.keys(@tokenStore).length is 0
			@connect() # initial authorization needed
		else
			@connect token for token in @tokenStore when token isnt null
		null
	connect: (refreshToken) ->
		# init an object for the user
		api = crimson.getApi()
		user =
			api: api
			crimson: @
			data: null
			id: null
			profile: null

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
	# shutdown procedures - should handle cleanup
	__destroy: ->
		# stop heartbeat
		#@halt()
		# ensure token store is completely up to date
		@updateTokenStore()
		@emit '__destroy'
		user.data.__destroy() for user of @users
	@getAuthUri: (fn) ->
		oauth =
			callback: 'oob'
			consumer_key: crimson.consumer_key.toString()
			consumer_secret: crimson.consumer_secret.toString()

		request.post { url: 'https://api.twitter.com/oauth/request_token', oauth:oauth }, (err, res, body) ->
			if err
				debug 'crimson.getAuthUri err: ' + err
				return fn err
			tokens = qs.parse(body)

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
	@tradePinForTokens: (token, pin) ->
	@getApi: (token, secret) ->
		return new twit {
			consumer_key: crimson.consumer_key.toString()
			consumer_secret: crimson.consumer_secret.toSting()
			access_token: token
			access_token_secret: secret
		}
	@consumer_key: new Buffer('', 'base64')
	@consumer_secret: new Buffer('', 'base64')

module.exports = new crimson()
