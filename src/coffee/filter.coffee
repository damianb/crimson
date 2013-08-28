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
				if doc.event.retweeted_status? and timeline.user.blocked.has doc.event.retweeted_status.user.id_str
					doc.filtered[timeline.user.id].push {
						why: 'blocked_rt_user'
						what: doc.event.retweeted_status.user.id_str
					}

			# filtered user?
			if @filteredUsers.has doc.event.user.id_str
				doc.filtered.super.push {
					why: 'filtered_user'
					what: doc.event.user.id_str
				}

			# filtered retweeted user?
			if doc.event.retweeted_status? and @filteredUsers.has doc.event.retweeted_status.user.id_str
				doc.filtered.super.push {
					why: 'filtered_rt_user'
					what: doc.event.retweeted_status.user.id_str
				}

			# filtered application?
			if @filteredSources.has doc.event.source.name
				doc.filtered.super.push {
					why: 'filtered_app'
					what: doc.event.source.name
				}

			# filtered text (will need to allow for regexps at some point)
			# todo
		else if doc.eventType.has 'tweet.censored'
			# non-super timelines only
			if !timeline.isSuper and timeline.user.blocked.has doc.event.user_id_str
				doc.filtered[timeline.user.id].push {
					why: 'blocked_user'
					what: doc.event.user_id_str
				}

			if @filteredUsers.has doc.event.user_id_str
				doc.filtered[timeline.user.id].push {
					why: 'filtered_user'
					what: doc.event.user_id_str
				}

		return doc


	addFilter: () ->
		# todo

	remFilter: () ->
		# todo

	__destroy: ->
		# todo

module.exports = filter
