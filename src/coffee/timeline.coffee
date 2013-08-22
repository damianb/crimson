{$} = global

class timeline
	constructor: (@type, @user) ->
		{ @stream, @crimson } = @user
		@isSuper = if @type is 'superhome' or @type is 'supernotify' then true else false

		if !@stream? and !@isSuper
			throw new Error 'All timelines except super types must be provided a datastream'
		else if @isSuper
			@stream = @crimson

		if !timeline.timelineEvents[@type]?
			throw new Error 'Unrecognized timeline type provided'

		@stream.on event, @addEntry for event in timeline.timelineEvents[@type]
		@stream.on 'tweet.delete', @removeEntry
		@stream.on '__destroy', @__destroy

	addEntry: (entries...) ->
		# todo apply filters on entries, remove any that we don't want
		# should this move farther up the stack? filter once instead of per-timeline?
		$('#timeline').prepend @crimson.ui.entryTemplate { entries: entries }

	removeEntry: (entry) ->
		# todo verify if entry is actually a tweet
		$("#timeline .entry.tweet[data-id='#{ entry.id }']").remove()

	minimize: (fn) ->
		$('#timeline').html('')
		fn null

	restore: (fn) ->
		# build our query based on timeline event types, etc.
		query = {}

		# only use an ownerId if we're not using a ^super timeline
		if @isSuper then query.ownerId = @user.id
		query.eventType = { $in: timeline.timelineEvents }
		@crimson.db.event.find query, (err, docs) =>
			docs.sort (a,b) ->
				if a.eventTime > b.eventTime then 1 else if b.eventTime > a.eventTime then -1 else 0
			@addEntry.apply @, docs
			fn null

	__destroy: ->
		@stream.removeListener event, @addEntry for event in timeline.timelineEvents[type]
		@stream.removeListener 'tweet.delete', @removeEntry

	@timelineEvents =
		superhome: ['tweet.new', 'tweet.new.mine', 'retweet.new', 'retweet.new.mine', 'mention.new']
		supernotify: ['mention.new', 'follower.new', 'retweet.new.ofmine', 'favorite.new.ofmine']
		home: ['tweet.new', 'tweet.new.mine', 'retweet.new']
		mentions: ['mention.new', 'mention.new.mine']
		events: ['follower.new', 'retweet.new.ofmine', 'favorite.new.ofmine']
