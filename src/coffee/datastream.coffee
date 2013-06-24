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
	forwardSort: (err, json, res) ->
		if err then return @client.ui.logError err
		results = {}
		proc = (response) =>
			type = switch
				when response.type is 'mention' then 'mention.new'
				when response.type is 'echo' and @client.users[response.data.echo.user_id]? then 'echo.new.mine'
				when response.type is 'echo' then 'echo.new'
				when response.type is 'listen' then 'listener.new'
			if results[response.type]? then results[response.type] = []
			results[type].push(response)
		proc response for response in json.responses
		@emit type, response for type, response of results
	forwardArray: (err, json, res) ->
		if err then return @client.ui.logError err
		results = {}
		proc = (response) =>
			type = switch
				when response.echo_id? and @client.users[response.echo.user_id]? then 'echo.new.mine'
				when response.echo_id? then 'echo.new'
				when response.is_private? is true then 'ping.new.private'
				else 'ping.new'
			if results[response.type]? then results[response.type] = []
			results[type].push(response)
		proc response for response in json.responses
		@emit type, response for type, response of results

		# todo - iterate over json.response.[] and dispatch!
		# todo - sort out entries by type before dispatch
	forwardSingle: (err, json, res) ->
		if err then return @client.ui.logError err
		# todo
	__destroy: ->
		@emit '__destroy'
		@client.removeListener 'heartbeat', bindType, listener for listener in @binds
		@client = @_user = @api = null
		# todo

module.exports = dataStream
