{$} = global

class timeline
	constructor: (@type, @user) ->
		{ @stream, @crimson } = @user
		if !@stream? and (@type isnt 'superhome' or @type isnt 'supernotify')
			throw new Error 'All timelines except super types must be provided a datastream'
		else if @type is 'superhome' or @type is 'supernotify'
			@stream = @crimson

		if !timeline.timelineEvents[@type]?
			throw new Error 'Unrecognized timeline type provided'

		@stream.on event, @addEntry for event in timeline.timelineEvents[@type]
		@stream.on 'tweet.delete', @removeEntry
	addEntry: (entries...) ->
		$('#timeline').prepend @crimson.ui.entryTemplate {
			entries: entries
		}
	removeEntry: (entry) ->
		$("#timeline .entry.tweet[data-id='#{ entry.id }']").remove()
	minimize: (fn) ->
		$('#timeline').html('')
		fn null
	restore: (fn) ->
		# build our query based on timeline event types, etc.
		query = {}

		# only use an ownerId if we're not using a ^super timeline
		if @type isnt 'superhome' and @type isnt 'supernotify'
			query.ownerId = @user.id
		query.eventType = { $in: tiemline.timelineEvents }
		@crimson.db.event.find query, (err, docs) =>
			docs.sort (a,b) ->
				if a.eventTime > b.eventTime then 1 else if b.eventTime > a.eventTime then -1 else 0
			$('#timeline').prepend @crimson.ui.entryTemplate {
				entries: docs
			}
			fn null
	__destroy: ->
		@stream.removeListener event, @addEntry for event in timeline.timelineEvents[type]
		@stream.removeListener 'tweet.delete', @removeEntry
	@timelineEvents =
		superhome: 'tweet.new', 'tweet.new.mine', 'retweet.new', 'retweet.new.mine', 'mention.new'
		supernotify: 'mention.new', 'follower.new', 'retweet.new.ofmine', 'favorite.new.ofmine'
		home: 'tweet.new', 'tweet.new.mine', 'retweet.new'
		mentions: 'mention.new', 'mention.new.mine'
		events: 'follower.new', 'retweet.new.ofmine', 'favorite.new.ofmine'
