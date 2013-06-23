class timeline
	constructor: (@client, type, @uid = null, options = {}) ->
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
		else
			@user = null

		if type is 'superhome'
			@bind 'ping.new', 'ping.new.mine', 'ping.new.private', 'echo.new', 'mention.new'
		# probably not as useful of a type...
		else if type is 'supernotify'
			@bind 'mention.new', 'listener.new', 'echo.new.mine'
		else if type is 'home'
			@bind 'ping.new', 'ping.new.private', 'echo.new'
		else if type is 'notify'
			@bind 'mention.new', 'listener.new', 'echo.new.mine'
		else if type is 'mentions'
			@bind 'mention.new'
		else if type is 'private'
			@bind 'ping.new.private'
		else if type is 'user'
			if !options.uid?
				throw new Error 'cannot use a user timeline without specifying a user id'
			@bind 'user.ping.' + options.uid
			if options.showEchoes
				@bind 'user.echo.' + options.uid
		# todo more column types
	addEntry: (entry) ->
		# todo DOM manipulation
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
					if !@binds[@uid]? then @binds[@uid] = []
					@binds[@uid].push event
					@user.data.on event, @addEntry
	__destroy: ->
		# remove listeners before we seppuku...
		for uid, binds of @binds then =>
			for bind in binds then =>
				@client.users[uid].data.removeListener bind, @addEntry
		@binds = {}
		@client = @user = @uid = null
