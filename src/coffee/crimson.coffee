{EventEmitter} = require 'events'
jade = require 'jade'
fs = require 'fs'
heelloApi = require 'heello'
http = require 'http'
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
		@heello.refreshTokens @data.refreshToken(), (err) =>
			if err? return false
				# handle error...somehow.
			@data.setRefreshToken @heello.refreshToken
			@emit 'connected'
	heartbeat: () ->
		# todo
	parsePing: () ->
		# todo
	@filter: () ->
		# todo
	@tokenPort: 33233  #todo see how common this port is in use...

#
# todo: determine if this structure should be kept
###
class timeline extends EventEmitter
	constructor: (@type, @pings) ->
		if !@pings? then @pings = []
		@lastPingId = null
		@on 'newPing', () =>
			if @pings.length > 20 # todo - see if this is an appropriate restriction
				@pings.shift() # discard old pings
			return null
	addPing: (ping) ->
		@lastPingId = ping.id if ping.id > @lastPingId
		@pings.push ping #todo memory management in @pings
		@emit 'newPing', ping
	paging: (offset, count) ->
		# todo

class ping
	constructor: (data) ->
		#todo
###

class dataCache
	constructor: (@client) ->
		@staleUserAge = 10 * 60 * 1000 # 10 minutes
		@stalePingAge = 0 # todo: should we perform ping caching at *all*?
		@staleListeningAge = 60 * 60 * 1000 # 60 minutes
		@staleListenerAge = 60 * 60 * 1000 # 60 minutes
	refreshToken: () ->
		if !@refresh? then @refresh = clientStorage.refreshToken
		return @refresh
	setRefreshToken: (@refresh) ->
		clientStorage.refreshToken = @refresh
	ping: (pingId) ->
		# todo
		# fetch ping data from local storage
		# remove?
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
		# fetch latest "notifications"
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

tokenIntercept = (port) ->
	#todo refactor to make it a bit MORE useful...
	server = http.createServer( (req, res) ->
		res.writeHead 200, {'Content-Type': 'application/json'}
		res.end JSON.stringify({ response: url.parse(req.url, true).query }) + '\n'
		server.close()
	).listen _crimson.tokenPort
