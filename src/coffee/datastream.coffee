{EventEmitter} = require 'events'

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
				'users.pings.' + event.split('.').pop()
			else false
		return newEvent
			# todo more listener types
	bind: (event) ->
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
	# note: intended for use with forwardArray and forwardSingle
	# boils down a "response" object (something that we got back from the api) into
	# a number of different "events" which we'll dispatch through this eventemitter
	_processResponse: (response) ->
		types = []
		# if response.data exists, we're grabbing from heello.users.notifications
		# otherwise, it is almost guaranteed to be another endpoint that we're streaming in
		if response.data?
			if response.type is 'mention' then types.push 'mention.new'
			if response.type is 'echo' and @client.users[response.data.echo.user_id]? then types.push 'echo.new.mine'
			if response.type is 'echo' then types.push 'echo.new'
			if response.type is 'listen' then types.push 'listener.new'
			# for some reason, heello.users.notifications is a clusterfsck
			# and breaks the standard format they *almost* had going.
			# ....so to semi-standardize this for display, we have to do this ugly thing.
			# tell the velociraptors I said I'm sorry.
			response = response.data
		else
			if response.echo? and @client.users[response.echo.user_id]? then types.push 'echo.new.mine'
			if response.echo? then types.push 'echo.new'
			# if it's not from users.notifications and not an echo, it *should* be a ping
			if !response.echo? then types.push 'ping.new'
			# private	pings cannot be echoed, of course
			if response.is_private? is true then types.push 'ping.new.private'
		return types
	forwardArray: (err, json, res) ->
		if err then return @client.ui.logError err
		results = {}
		processTypes = (type, response) ->
			if results[type]? then results[type] = []
			if response.data? then response = response.data
			results[type].push(response)
		processTypes type, response for type in @_processResponse(response) for response in json.responses
		@emit type, responses for type, responses of results
	forwardSingle: (err, json, res) ->
		response = json.response
		if err then return @client.ui.logError err
		types = @_processResponse(response)
		if response.data? then response = response.data
		@emit type, [response] for type in types # we want to be able to expect arrays constantly from this forward call.
	forward: (err, json, res) ->
		# todo
		# non-standard forwarding/dispatch
		# to be used for grabbing profiles via API?
	__destroy: ->
		@emit '__destroy'
		@client.removeListener 'heartbeat', bindType, listener for listener in @binds
		@client = @_user = @api = null
		# todo

module.exports = dataStream
