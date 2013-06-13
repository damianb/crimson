{EventEmitter} = require 'events'
jade = require 'jade'
fs = require 'fs'
heelloApi = require 'heello'
http = require 'http'
url = require 'url'
os = require 'os'
gui = require 'nw.gui'

class _crimson extends EventEmitter
	constructor: (options) ->
		@userId = null
		@username = null
		@timelines =
			home: null
			notify: null
		@filters = {}

		@tokenPort = 33233  #todo see how common this port is in use...
		@heello = new heelloApi {
			appId: new Buffer('ZThhYTg4NGJmM2NlYzk1NmQ2NGJjODc3NDc1N2U4Nzk5ZTFlZGEwZGY3MmNlNjQyOWYxYTRlZWNiN2ViZDQxYw==', 'base64').toString()
			appSecret: new Buffer('MDljMTE2MjRmN2EyZTZiNTRjODFmZDcxMjQzYTY5Y2Q5OTZmZDZhOTliM2ZjMzk0MmNjMzhiODNjMGYyM2FhNg==', 'base64').toString()
			callbackURI: "http://127.0.0.1:#{@tokenPort}"
			userAgent: 'crimson-client'
			# todo: somehow get current pkg.version! D:
		}
		@data = new dataCache @
		super()
	connect: () ->
		refreshToken = @data.refreshToken()
		# check if we need to get tokens for the client
		if !refreshToken?
			# application not yet authorized...let's do this!
			tokenInterceptor @tokenPort, (code) =>
				console.log 'got code'
				@heello.getTokens code, (err) =>
					console.log err
					if err? then bigError err
					@data.setRefreshToken @heello.refreshToken
					@emit 'connected'
			display 'auth'
		else
			@heello.refreshTokens refreshToken, (err) =>
				if err? then bigError err
				@data.setRefreshToken @heello.refreshToken
				@emit 'connected'
	heartbeat: () ->
		# todo
	parsePing: () ->
		# todo
	@filter: () ->
		# todo

class dataCache
	constructor: (@client) ->
		@staleUserAge = 60 * 1000 # 1 minute
		@staleListeningAge = 10 * 60 * 1000 # 60 minutes
		@staleListenerAge = 10 * 60 * 1000 # 60 minutes
	refreshToken: () ->
		if !@refresh? then @refresh = localStorage.getItem 'refreshToken'
		return @refresh
	setRefreshToken: (@refresh) ->
		localStorage.setItem 'refreshToken', @refresh
		return null
	ping: (pingId) ->
		# todo
		# fetch pings...?
	user: (userId) ->
		# todo
		# fetch user data from local storage, refresh cache if local storage too "stale"
	userTimeline: () ->
		# todo
		# fetch other user's previous tweets... 5 minute cache? shorter?
	me: () ->
		# todo
	notifications: () ->
		# todo
		# fetch latest "notifications"...?
	listeners: () ->
		# todo
		# fetch latest "listeners"
	listening: () ->
		# todo
		# fetch latest "listening"
	ignored: () ->
		# todo
		# fetch "ignored" users from local storage...this acts as a frontend for filters against user accounts
	update: (type, data) ->
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
