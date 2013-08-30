debug = (require 'debug')('filter')
{ $ } = global

class filter
	constructor: (@crimson, @user) ->

	run: (doc) ->
		if !doc.filtered? then doc.filtered = {}
		if !doc.filtered.super? then doc.filtered.super = []
		if !doc.filtered[@user.id]? then doc.filtered[@user.id] = []

		# is it a tweet?
		if doc.eventType.has 'tweet.new'
			# blocked user?
			if @user.blocked.has doc.event.user.id_str
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
			if @crimson.filtered.users.has doc.event.user.id_str
				doc.filtered.super.push {
					why: 'filtered_user'
					what: doc.event.user.id_str
				}

			# filtered retweeted user?
			if doc.eventType.has 'retweet.new' and @crimson.filtered.users.has doc.event.retweeted_status.user.id_str
				doc.filtered.super.push {
					why: 'filtered_rt_user'
					what: doc.event.retweeted_status.user.id_str
				}

			# filtered application?
			if @crimson.filtered.sources.has doc.event.source.name
				doc.filtered.super.push {
					why: 'filtered_app'
					what: doc.event.source.name
				}

			# filtered text (will need to allow for regexps at some point)
			for match in @crimson.filtered.text do
				(match) ->
					text = if doc.eventType.has 'retweet.new' then doc.event.retweeted_status.text else doc.event.text
					if text.search(match) isnt -1
						doc.filtered.super.push {
							why: 'filtered_text'
							what: match
						}
		else if doc.eventType.has 'tweet.censored'
			if @user.blocked.has doc.event.user_id_str
				doc.filtered[timeline.user.id].push {
					why: 'blocked_user'
					what: doc.event.user_id_str
				}

			if @crimson.filtered.users.has doc.event.user_id_str
				doc.filtered.super.push {
					why: 'filtered_user'
					what: doc.event.user_id_str
				}
		else if doc.eventType.has 'follower.new', 'favorite.new.ofmine'
			if @user.blocked.has doc.event.source.user_id_str
				doc.filtered[timeline.user.id].push {
					why: 'blocked_user'
					what: doc.event.source.user_id_str
				}

			if @crimson.filtered.users.has doc.event.source.user_id_str
				doc.filtered.super.push {
					why: 'filtered_user'
					what: doc.event.source.user_id_str
				}

		return doc

	addFilter: () ->
		# Fuck. we have to go through everything in the current timeline that's visible and run through it all.
		# this will take an nedb query, at least
		# todo

	remFilter: () ->
		# todo
		# IT SHOULD ALWAYS BE IN THE DOM, JUST NOT VISIBLE! (display:none) so we don't lose where it is in the DOM!
		# todo: dom modifications, nedb updates

	__destroy: ->
		# todo

module.exports = filter
