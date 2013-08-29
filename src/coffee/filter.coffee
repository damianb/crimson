debug = (require 'debug')('filter')
{ $ } = global

class filter
	constructor: (@crimson) ->
		@filtered =
			users: []
			sources: []
			text: []

		@crimson.db.preferences.findOne { key: 'filter' }, (err, doc) =>
			if err
				debug 'filter.constructor nedb err: ' + err
				return err

			@filtered.users = doc.filters.users
			@filtered.sources = doc.filters.sources
			@filtered.text = doc.filters.text

	runFilters: (timeline, doc) ->
		if !doc.filtered? then doc.filtered = {}
		if !doc.filtered.super? then doc.filtered.super = []
		if !doc.filtered[timeline.user.id]? then doc.filtered[timeline.user.id] = []

		# is it a tweet?
		if doc.eventType.has 'tweet.new'
			# these two checks should only occur in non-super timelines
			if !timeline.isSuper
				# blocked user?
				if timeline.user.blocked.has doc.event.user.id_str
					doc.filtered[timeline.user.id].push {
						why: 'blocked_user'
						what: doc.event.user.id_str
					}

				# blocked retweeted user?
				if doc.eventType.has 'retweet.new' and timeline.user.blocked.has doc.event.retweeted_status.user.id_str
					doc.filtered[timeline.user.id].push {
						why: 'blocked_rt_user'
						what: doc.event.retweeted_status.user.id_str
					}

			# filtered user?
			if @filtered.users.has doc.event.user.id_str
				doc.filtered.super.push {
					why: 'filtered_user'
					what: doc.event.user.id_str
				}

			# filtered retweeted user?
			if doc.eventType.has 'retweet.new' and @filtered.users.has doc.event.retweeted_status.user.id_str
				doc.filtered.super.push {
					why: 'filtered_rt_user'
					what: doc.event.retweeted_status.user.id_str
				}

			# filtered application?
			if @filtered.sources.has doc.event.source.name
				doc.filtered.super.push {
					why: 'filtered_app'
					what: doc.event.source.name
				}

			# filtered text (will need to allow for regexps at some point)
			for match in @filtered.text do
				(match) ->
					text = if doc.eventType.has 'retweet.new' then doc.event.retweeted_status.text else doc.event.text
					if text.search(match) isnt -1
						doc.filtered.super.push {
							why: 'filtered_text'
							what: match
						}
		else if doc.eventType.has 'tweet.censored'
			# non-super timelines only
			if !timeline.isSuper and timeline.user.blocked.has doc.event.user_id_str
				doc.filtered[timeline.user.id].push {
					why: 'blocked_user'
					what: doc.event.user_id_str
				}

			if @filteredUsers.has doc.event.user_id_str
				doc.filtered.super.push {
					why: 'filtered_user'
					what: doc.event.user_id_str
				}
		else if doc.eventType.has 'follower.new', 'favorite.new.ofmine'
			# non-super timelines only
			if !timeline.isSuper and timeline.user.blocked.has doc.event.source.user_id_str
				doc.filtered[timeline.user.id].push {
					why: 'blocked_user'
					what: doc.event.source.user_id_str
				}

			if @filtered.users.has doc.event.source.user_id_str
				doc.filtered.super.push {
					why: 'filtered_user'
					what: doc.event.source.user_id_str
				}

		return doc

	addFilter: () ->
		# todo

	remFilter: () ->
		# todo
		# IT SHOULD ALWAYS BE IN THE DOM, JUST NOT VISIBLE! (display:none) so we don't lose where it is in the DOM!

	__destroy: ->
		# todo

module.exports = filter
