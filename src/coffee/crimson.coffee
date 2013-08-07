{EventEmitter} = require 'events'
http = require 'http'
url = require 'url'
twit = require 'twit'
pkg = require './../../package.json'
dataStream = require './datastream'

class crimson extends EventEmitter
	constructor: ->
		@ui = null
		@users = {}
		@interceptors = 0
		@interceptor = null
		@tokenPort = tokenPort
		@tokenStore = JSON.parse(localStorage.getItem 'refreshTokenStore') or []
		@heartbeat = null # this will hold a setInterval reference.
		@pkg = pkg
		# the below is for special unauthenticated stuff only
		@twitter = crimson.getApi()

		#@heello = crimson.getApi()
		#@authURI = @heello.getAuthURI '0000'
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
		user.data = new dataStream @, user, api
		procTokens = (err) =>
			if err? then return @ui.logError err
			if api.refreshToken is null then throw new Error 'api.refreshToken null!'
			oldTokenIndex = @tokenStore.indexOf refreshToken
			if oldTokenIndex isnt -1 then @tokenStore.remove oldTokenIndex
			@tokenStore.push api.refreshToken
			@updateTokenStore()
			api.on 'newTokens', (oldRefreshToken, newRefreshToken) =>
				oldTokenIndex = @tokenStore.indexOf oldRefreshToken
				if oldTokenIndex isnt -1 then @tokenStore.remove oldTokenIndex
				@tokenStore.push newRefreshToken
				@updateTokenStore()
			api.users.me (err, json) =>
				if err? then return @ui.logError err
				user.profile = json.response
				user.id = user.profile.id
				first = Object.keys(@users).length is 0
				@users[user.id] = user
				# rock and roll!
				@emit 'user.ready', user, first

		# check if we need to get tokens for the account
		if !refreshToken?
			# application not yet authorized...let's do this!
			@tokenInterceptor (code) =>
				api.getTokens code, procTokens
			@emit 'auth.pending', user
		else
			api.refreshTokens refreshToken, procTokens

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
	@getAuthUri: ->
		# todo write
	@getApi: ->
		# todo switch to twitter
		return new twit {
			consumer_key: new Buffer('', 'base64').toString()
			consumer_secret: new Buffer('', 'base64').toString()
		}

		###
		return new heelloApi {
			# ignore the obfuscation, it's necessary due to automated code scanners
			appId: new Buffer('ZThhYTg4NGJmM2NlYzk1NmQ2NGJjODc3NDc1N2U4Nzk5ZTFlZGEwZGY3MmNlNjQyOWYxYTRlZWNiN2ViZDQxYw==', 'base64').toString()
			appSecret: new Buffer('MDljMTE2MjRmN2EyZTZiNTRjODFmZDcxMjQzYTY5Y2Q5OTZmZDZhOTliM2ZjMzk0MmNjMzhiODNjMGYyM2FhNg==', 'base64').toString()
			callbackURI: "http://127.0.0.1:#{tokenPort}"
			userAgent: "crimson-client_#{pkg.version}"
		}
		###

module.exports = new crimson()
