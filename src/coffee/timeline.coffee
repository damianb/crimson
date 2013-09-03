{$} = global

class timeline
	constructor: (@type, @user) ->
		{ @stream, @crimson } = @user
		@isSuper = if @type is 'superhome' or @type is 'supernotify' then true else false

		if !@stream? and !@isSuper
			throw new Error 'All timelines except super types must be provided a stream'
		else if @isSuper
			@stream = @crimson

		if !timeline.timelineEvents[@type]?
			throw new Error 'Unrecognized timeline type provided'

		@stream.on event, @addEntry.bind(@) for event in timeline.timelineEvents[@type]
		@stream.on 'tweet.delete', @removeEntry.bind @
		@stream.on '__destroy', @__destroy.bind @

	domifyEntry: (entry) ->
		if entry.entryTypes.has 'tweet.new'
			entry.type = 'tweet'
			# override type to be retweet if it is such
			if entry.entryTypes.has 'retweet.new'
				entry.type 'retweet'
		else if entry.entryTypes.has 'dm.new'
			entry.type = 'dm'
		else if entry.entryTypes.has 'favorite.new'
			entry.type = 'favorite'
		else if entry.entryTypes.has 'follower.new'
			entry.type = 'follower'

		return entry

	addEntry: (entries...) ->
		# note, entries should be handled properly on insertion. they may not all be tweets!
		# ( S-SENPAI, THAT'T NOT A TWEET! ///// )
		# this is horribly broken at the moment.
		# $('#timeline').prepend @crimson.ui.entryTemplate { entries: entries }

	updateEntry: (identifier, entry) ->
		# todo

	removeEntry: (entry) ->
		# if it's a tweet...
		$("#timeline .entry[data-nedb-id='#{entry._id}']").remove()

	showEntry: (entry) ->
		$("#timeline .entry[data-nedb-id='#{entry._id}']").show()

	hideEntry: (entry) ->
		$("#timeline .entry[data-nedb-id='#{entry._id}']").hide()

	minimize: (fn) ->
		$('#timeline').html('')
		fn null

	restore: (fn) ->
		# build our query based on timeline event types, etc.
		query =
			eventType:
				$in: timeline.timelineEvents

		# only use an ownerId if we're not using a ^super timeline
		if !@isSuper then query.ownerId = @user.id

		@crimson.db.event.find query, (err, docs) =>
			docs.sort (a,b) ->
				if a.eventTime > b.eventTime then 1 else if b.eventTime > a.eventTime then -1 else 0
			@addEntry.apply @, docs
			fn null

	__destroy: ->
		@stream.removeListener event, @addEntry.bind(@) for event in timeline.timelineEvents[type]
		@stream.removeListener 'tweet.delete', @removeEntry

	@timelineEvents =
		superhome: ['tweet.new', 'tweet.new.mine', 'retweet.new', 'retweet.new.mine', 'mention.new']
		supernotify: ['mention.new', 'follower.new', 'retweet.new.ofmine', 'favorite.new.ofmine']
		home: ['tweet.new', 'tweet.new.mine', 'retweet.new']
		mentions: ['mention.new']
		messages: ['dm.sent', 'dm.received']
		events: ['follower.new', 'retweet.new.ofmine', 'favorite.new.ofmine']

module.exports = timeline
