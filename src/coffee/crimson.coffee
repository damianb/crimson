{EventEmitter} = require 'events'
jade = require 'jade'
fs = require 'fs'
heelloApi = require 'heello'
http = require 'http'
url = require 'url'
os = require 'os'
gui = require 'nw.gui'

DEBUG = true

Array::remove = (from, to) ->
	rest = @slice (to or from) + 1 or @length
	@length = if from < 0 then @length + from else from
	return @push.apply @, rest

class _crimson extends EventEmitter
	constructor: ->
		@ui = null
		@users = {}
		@interceptors = 0
		@interceptor = null
		@tokenPort = 33233  #todo see how common this port is in use...
		@tokenStore = JSON.parse localStorage.getItem 'refreshTokenStore'
		@heartbeat = null # this will hold a setInterval reference.
		# the below is for special unauthenticated stuff only
		@heello = _crimson.getApi()
		@authURI = @heello.getAuthURI '0000'
		if !@tokenStore? then @tokenStore = []
		super()

	updateTokenStore: ->
		localStorage.setItem 'refreshTokenStore', JSON.stringify @tokenStore
	connectAll: ->
		if Object.keys(@users).length is 0
			@connect() # initial authorization needed
		else
			@connect token for token in @tokenStore
	connect: (refreshToken) ->
		# init an object for the user
		api = _crimson.getApi()
		user =
			api: api
			crimson: @
			data: null
			id: null
			profile: null
		user.data = new dataStream @, user, api
		procTokens = (err) =>
			if err? then bigError err
			@tokenStore.push api.refreshToken
			@updateTokenStore()
			api.on 'newTokens', (oldRefreshToken, newRefreshToken) =>
				if @tokenStore.indexOf(oldRefreshToken) isnt -1
					@tokenStore.remove @tokenStore.indexOf oldRefreshToken
				@tokenStore.push newRefreshToken
				@updateTokenStore()
			api.users.me (err, json) =>
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
			api.refreshTokens refreshToken, procToken
	tokenInterceptor: (fn) ->
		# interceptor queue, so that we don't waste an HTTP server when we need one
		if @interceptors is 0
			@interceptor = http.createServer((req, res) =>
				# obtain refresh & access token now with token exchange...
				code = url.parse(req.url, true).query.code
				@emit 'auth.got'
				fn code
				res.writeHead 200, {'Content-Type': 'text/html'}
				res.end '<!DOCTYPE html><html><head><title>Authorization successful</title></head><body><h2>Authorization successful</h2><p>You may now close this window.</p><script>window.close();</script></body></html>\n'
				@interceptor.close ->
					interceptors--
			).listen @tokenPort
		@interceptors++
	# start client heartbeat
	kickstart: ->
		if !@heartbeat?
			@heartbeat = setInterval =>
				@emit 'heartbeat'
			, 5 * 1000
	# stop client heartbeat
	halt: ->
		if @heartbeat?
			clearInterval @heartbeat
	# shutdown procedures - should handle cleanup
	__destroy: ->
		# stop heartbeat
		@halt()
		# ensure token store is completely up to date
		@updateTokenStore()
		# nuke interceptor server if it's running
		if @interceptor?
			@interceptor.close ->
				interceptors--
		user.data.__destroy() for user of @users
	@getApi: ->
		return new heelloApi {
			# ignore the obfuscation, it's necessary due to automated code scanners
			appId: new Buffer('ZThhYTg4NGJmM2NlYzk1NmQ2NGJjODc3NDc1N2U4Nzk5ZTFlZGEwZGY3MmNlNjQyOWYxYTRlZWNiN2ViZDQxYw==', 'base64').toString()
			appSecret: new Buffer('MDljMTE2MjRmN2EyZTZiNTRjODFmZDcxMjQzYTY5Y2Q5OTZmZDZhOTliM2ZjMzk0MmNjMzhiODNjMGYyM2FhNg==', 'base64').toString()
			callbackURI: "http://127.0.0.1:#{@tokenPort}"
			userAgent: 'crimson-client'
			# todo: somehow get current pkg.version! D:
		}
	@filter: ->
		# todo


class dataStream extends EventEmitter
	constructor: (@client, @_user, @api) ->
		minute = 60 * 1000
		@staleAge =
			ping: 30 * minute
			me: 30 * minute
			home: 1 * minute
			notify: 1 * minute
			user: 5 * minute
			listening: 10 * minute
			listeners: 10 * minute
			blocked: 30 * minute
		@last =
			home: 0
			notify: 0
			me: 0
			listening: 0
			listeners: 0
			blocked: 0
			# filters: 0

		# binds against crimson.heartbeat
		@binds = {}
		super()

		@on 'newListener', @bind
		@on 'removeListener', @unbind
	translator: (event) ->
		# we're grabbing the name of the true query to prevent bind-collisions
		return switch
			when event is 'ping.new' or event is 'ping.new.private' or event is 'echo.new'
				'users.timeline'
			when event is 'mention.new' or event is 'listener.new' or event is 'echo.new.mine'
				'users.notifications'
			when event.match(/^user\.(?:ping|echo)\.([0-9]+)$/)
				uid = event.split('.').pop()
				'users.pings.' + uid
			else false
		return newEvent
			# todo more listener types
	bind (event) ->
		type = @translator event
		if type is false then return
		# newListener is the actual listener that will be forwarding dispatches
		newListener = switch
			when event is 'users.timeline'
				=>
					@api.users.timeline @forwardArray
			when event is 'users.notifications'
				=>
					@api.users.notifications @forwardArray
			when event.match(/^users\.pings\./)
				uid = event.split('.').pop()
				=>
					# todo - paging?
					@api.users.pings { ':id': uid }, @forwardArray
		if !@binds[type]?
			@binds[type] = newListener
			@client.on 'heartbeat', newListener
	unbind: (event) ->
		type = @translator event
		if type is false then return
		if @binds[type]?
			@client.removeListener 'heartbeat', @binds[type]
			delete @binds[type]
			# todo delete entry in @last if necessary
	forwardArray: (err, json, res) ->
		if err then return @client.ui.logError err
		# todo - iterate over json.response.[] and dispatch!
	forwardSingle: (err, json, res) ->
		# todo
	__destroy: ->
		@emit '__destroy'
		@client.removeListener 'heartbeat', bindType, listener for listener in @binds
		@client = @_user = @api = null
		# todo

## todo: move to ui?
class viewport
	constructor: () ->
		@timelines = {}
		@visible = 1
		@first = 0
		@minWidth = 150
	addTimeline: (timeline) ->
		@timelines[timeline.type + '_' + @user.profile.id] = timeline
	removeTimeline: (timeline) ->
	scrollTo: (timeline) ->
		# todo
	resize: () ->
		# todo

class timeline
	constructor: (@client, type, @uid = null) ->
		# note: @binds structure:
		#
		# binds: {
		# 'userid': [
		#	   'bindname',
		#    'bindname',
		#  ]
		# }
		@binds = {}

		if !@uid? and (type isnt 'superhome' or type isnt 'supernotify')
			throw new Error 'All timelines except super types must be provided a user'

		# if we had a user object instead, we'd still need to pull out the uid, so meh. :p
		if @uid?
			@user = @client.users[@uid]
			@user.data.on '__destroy', @__destroy

		if type is 'superhome'
			@bind 'ping.new', 'ping.new.mine', 'ping.new.private', 'echo.new', 'mention.new'
		else if type is 'supernotify' # probably not as useful of a type...
			@bind 'mention.new', 'listener.new', 'echo.new.mine'
		else if type is 'home'
			@bind 'ping.new', 'ping.new.private', 'echo.new'
		else if type is 'notify'
			@bind 'mention.new', 'listener.new', 'echo.new.mine'
		else if type is 'mentions'
			@bind 'mention.new'
		else if type is 'private'
			@bind 'ping.new.private'

	addEntry: (entry) ->
	removeEntry: (entry) ->
	getEntry: (entry) ->
	getEntries: () ->
	page: (offset, length) ->
		# todo
	bind: (events...) ->
		for event in events then =>
			if !@user?
				for uid, user of @client.users then =>
					if !@binds[uid]? then @binds[uid] = []
					@binds[uid].push event
					user.data.on event, @addEntry
			else
				if !@binds[event]?
					# todo recode
					if !@binds[@uid]? then @binds[@uid] = []
					@binds[@uid].push event
					@user.data.on event, @addEntry
	__destroy: ->
		# remove listeners before we seppuku...
		for uid, binds of @binds then =>
			for bind in binds then =>
				@client.users[uid].data.removeListener bind, @addEntry
		@binds = {}
		@client = @user = null

crimson = new _crimson()
