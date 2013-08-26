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
		if !doc.filtered? then doc.filtered = []

		# is it a tweet?
		if doc.eventType.has 'tweet.new'

			# these two checks should only occur in non-super timelines
			if !timeline.isSuper
				# blocked user?
				if timeline.user.blocked.has @doc.event.user.id_str
					doc.filtered.push {
						super: false
						user: timeline.user
						why: 'blocked_user'
					}

				# blocked retweeted user?
				if doc.event.retweeted_status? and timeline.user.blocked.has doc.event.retweeted_status.user.id_str
					doc.filtered.push {
						super: false
						user: timeline.user
						why: 'blocked_rt_user'
					}

			# filtered user?
			if @filteredUsers.has doc.event.user.id_str
				doc.filtered.push {
					super: timeline.isSuper
					user: timeline.user
					why: 'filtered_user'
				}

			# filtered retweeted user?
			if doc.event.retweeted_status? and @filteredUsers.has doc.event.retweeted_status.user.id_str
				doc.filtered.push {
					super: timeline.isSuper
					user: timeline.user
					why: 'filtered_rt_user'
				}

			# filtered application?
			if @filteredSources.has doc.event.source.name
				doc.filtered.push {
					super: timeline.isSuper
					user: timeline.user
					why: 'filtered_app'
				}

			# filtered text (will need to allow for regexps at some point)
		else if doc.eventType.has 'tweet.censored'
			# non-super timelines only
			if !timeline.isSuper
				# blocked user?
				if doc.event.user_id_str
					doc.filtered.push


			# things to filter:

			# author: is it a filtered or blocked user
			# retweeted: is it a retweet of a filtered user
			# text: does it contain a filtered word or phrase
			# text: does it match a regex filter
			# source: does it match a filtered application

			# todo

	addFilter: () ->
		# todo

	remFilter: () ->
		# todo

	__destroy: ->
		# todo

module.exports = filter
