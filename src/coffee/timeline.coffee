{$} = global

class timeline
	constructor: (@user, type) ->
		{ @stream, @crimson } = @user
		if !@uid? and (type isnt 'superhome')
			throw new Error 'All timelines except super types must be provided a user'

		if !timeline.timelineEvents[type]?
			throw new Error 'unrecognized timeline type'

		@stream.on event, @addEntry for event in timeline.timelineEvents[type]
		@stream.on 'tweet.delete', @removeEntry
	addEntry: (entry) ->
		# todo DOM manipulation
	removeEntry: (entry) ->
		# todo DOM removal, remove from NeDB database?
	__destroy: ->
		@stream.removeListener event, @addEntry for event in timeline.timelineEvents[type]
		@stream.removeListener 'tweet.delete', @removeEntry
	@timelineEvents =
		superhome: 'tweet.new', 'tweet.new.mine', 'retweet.new', 'retweet.new.mine', 'mention.new'
		supernotify: 'mention.new', 'follower.new', 'retweet.new.ofmine', 'favorite.new.ofmine'
		home: 'tweet.new', 'tweet.new.mine', 'retweet.new'
		mentions: 'mention.new', 'mention.new.mine'
		events: 'follower.new', 'retweet.new.ofmine', 'favorite.new.ofmine'
