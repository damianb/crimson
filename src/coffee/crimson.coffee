{EventEmitter} = require 'events'
jade = require 'jade'
fs = require 'fs'
heelloApi = require 'heello'
http = require 'http'
url = require 'url'
os = require 'os'
gui = require 'nw.gui'

DEBUG = true

class _crimson extends EventEmitter
	constructor: () ->
		@users = {}
		@interceptors = 0
		@tokenPort = 33233  #todo see how common this port is in use...
		@tokenStore = JSON.parse localStorage.getItem 'refreshTokenStore'
		@heartbeat = null # this will hold a setInterval reference.
		# the below is for special unauthenticated stuff only
		@heello = @getApi()
		@authURI = @heello.getAuthURI '0000'
		if !@tokenStore? then @tokenStore = []
		super()
	getApi: () ->
		return new heelloApi {
			# ignore the obfuscation, it's necessary due to automated code scanners
			appId: new Buffer('ZThhYTg4NGJmM2NlYzk1NmQ2NGJjODc3NDc1N2U4Nzk5ZTFlZGEwZGY3MmNlNjQyOWYxYTRlZWNiN2ViZDQxYw==', 'base64').toString()
			appSecret: new Buffer('MDljMTE2MjRmN2EyZTZiNTRjODFmZDcxMjQzYTY5Y2Q5OTZmZDZhOTliM2ZjMzk0MmNjMzhiODNjMGYyM2FhNg==', 'base64').toString()
			callbackURI: "http://127.0.0.1:#{@tokenPort}"
			userAgent: 'crimson-client'
			# todo: somehow get current pkg.version! D:
		}
	updateTokenStore: () ->
		localStorage.setItem 'refreshTokenStore', JSON.stringify @tokenStore
	connectAll: () ->
		if Object.keys(@users).length is 0
			@connect() # initial authorization needed
		else
			@connect token for token in @tokenStore
	connect: (refreshToken) ->
		# init an object for the user
		api = @getApi()
		user =
			crimson: @
			api: api
			data: null
			profile: null
			heartbeatBinds: []
		user.data = new dataCache user
		procTokens = (err) =>
			if err? then bigError err
			@tokenStore.push api.refreshToken
			@updateTokenStore()
			api.users.me (err, json) =>
				user.profile = json.response
				first = Object.keys(@users).length is 0
				@users[json.response.id] = user
				# rock and roll!
				@emit 'user.ready', user, first

		# check if we need to get tokens for the account
		if !refreshToken?
			# application not yet authorized...let's do this!
			@tokenInterceptor (code) =>
				api.getTokens code, procTokens
			@emit 'auth.pending', user
		else
			api.refreshTokens refreshToken, procToken
	tokenInterceptor: (fn) ->
		# interceptor queue, so that we don't waste an HTTP server when we need one
		if interceptors is 0
			server = http.createServer((req, res) =>
				# obtain refresh & access token now with token exchange...
				code = url.parse(req.url, true).query.code
				@emit 'auth.got'
				fn code
				res.writeHead 200, {'Content-Type': 'text/html'}
				res.end '<!DOCTYPE html><html><head><title>Authorization successful</title></head><body><h2>Authorization successful</h2><p>You may now close this window.</p><script>window.close();</script></body></html>\n'
				server.close () ->
					interceptors--
			).listen @tokenPort
		@interceptors++
	kickstart: () ->
		if !@heartbeat?
			@heartbeat = setInterval () =>
				@emit 'heartbeat'
			, 5 * 1000
	halt: () ->
		if @heartbeat?
			clearInterval @heartbeat
	@filter: () ->
		# todo


class dataCache
	constructor: (@client) ->
		minute = 60 * 1000
		@stalePingAge = 30 * minute
		@staleMeAge = 30 * minute
		@staleUserAge = 5 * minute
		@staleListeningAge = 10 * minute
		@staleListenerAge = 10 * minute
		@staleHomeAge = 1 * minute
		@staleNotifyAge = 1 * minute
		@last =
			home: 0
			notify: 0
			me: 0
			listeners: 0
			listening: 0
			# filters: 0
	ping: (pingId, fn) ->
		# todo
		# fetch pings...?
	user: (user, fn) ->
		# todo
		# fetch user data from local storage, refresh cache if local storage too "stale"
	userTimeline: (fn) ->
		# todo
		# fetch other user's previous tweets... 5 minute cache? shorter?
	me: (fn) ->
		# todo
	home: (fn) ->
		# todo
	notifications: (fn) ->
		# todo
		# fetch latest "notifications"...?
	listeners: (fn) ->
		# todo
		# fetch latest "listeners"
	listening: (fn) ->
		# todo
		# fetch latest "listening"
	ignored: (fn) ->
		# todo
		# fetch "ignored" users from local storage...this acts as a frontend for filters against user accounts
	filters: (fn) ->
		# todo
	update: (type, data) ->
		# todo


class viewport
	constructor: (@user) ->
		@timelines = {}
		@visible = 1
		@first = 0
	addTimeline: (timeline) ->
		@timelines[timeline.type + '_' + @user.profile.id] = timeline
	removeTimeline: (timeline) ->
	scrollTo: (timeline) ->
		# todo


class timeline
	constructor: (@user, type) ->
		if type is 'home'
			@client.on 'newPing', addEntry
		else if type is 'notify'
			@client.on 'newNotify', addEntry
		else if type is 'mentions'
			@client.on 'newMention', addEntry
		else if type is 'private'
			@client.on 'newPingPrivate', addEntry
	addEntry: (entry) ->
	removeEntry: (entry) ->
	getEntry: (entry) ->
	getEntries: () ->
	page: (offset, length) ->
		# todo

crimson = new _crimson()
