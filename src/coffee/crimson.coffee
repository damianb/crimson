{EventEmitter} = require 'events'
jade = require 'jade'
fs = require 'fs'
heelloApi = require 'heello'
http = require 'http'
url = require 'url'
os = require 'os'
gui = require 'nw.gui'

class _crimson extends EventEmitter
	constructor: () ->
		@users = {}
		@tokenPort = 33233  #todo see how common this port is in use...
		@tokenStore = JSON.parse localStorage.getItem 'refreshTokenStore'
		@heartbeat = null # this will hold a setInterval reference.
		if !@tokenStore? then @tokenStore = []
		super()
	updateTokenStore: () ->
		localStorage.setItem 'refreshTokenStore', JSON.stringify @tokenStore
	connectAll: () ->
		@connect token for token in @tokenStore
	connect: (refreshToken) ->
		# init an object for the user
		heello = new heelloApi {
			# ignore the obfuscation, it's necessary due to automated code scanners
			appId: new Buffer('ZThhYTg4NGJmM2NlYzk1NmQ2NGJjODc3NDc1N2U4Nzk5ZTFlZGEwZGY3MmNlNjQyOWYxYTRlZWNiN2ViZDQxYw==', 'base64').toString()
			appSecret: new Buffer('MDljMTE2MjRmN2EyZTZiNTRjODFmZDcxMjQzYTY5Y2Q5OTZmZDZhOTliM2ZjMzk0MmNjMzhiODNjMGYyM2FhNg==', 'base64').toString()
			callbackURI: "http://127.0.0.1:#{@tokenPort}"
			userAgent: 'crimson-client'
			# todo: somehow get current pkg.version! D:
		}
		user =
			crimson: @
			heello: heello
			data: null
			profile: null
		user.data = new dataCache user
		procTokens = (err) =>
			if err? then bigError err
			@tokenStore.push heello.refreshToken
			@updateTokenStore()
			heello.users.me (err, json) =>
				user.profile = json.response
				@users[json.response.id] = user
				@emit 'connected', user

		# check if we need to get tokens for the account
		if !refreshToken?
			# application not yet authorized...let's do this!
			tokenInterceptor @tokenPort, (code) =>
				heello.getTokens code, procTokens
			@emit 'pendingAuth', user
		else
			heello.refreshTokens refreshToken, procToken
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

tokenInterceptor = (port, fn) ->
	server = http.createServer((req, res) ->
		# obtain refresh & access token now with token exchange...
		code = url.parse(req.url, true).query.code
		fn code
		res.writeHead 200, {'Content-Type': 'text/html'}
		res.end '<!DOCTYPE html><html><head><title>Authorization successful</title></head><body><h2>Authorization successful</h2><p>You may now close this window.</p><script>window.close();</script></body></html>\n'
		server.close()
	).listen port

crimson = new _crimson()
