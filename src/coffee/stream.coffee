{EventEmitter} = require 'events'
twitter = require 'twitter-text'
{$} = global
debug = (require 'debug')('stream')

class stream extends EventEmitter
	constructor: (@user) ->
		{@crimson, @api} = @user
		@twitStream = @api.stream 'user'
		@couple false
		super()

	filter: (doc) ->
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
			for match in @crimson.filtered.text
				do (match) ->
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

	tweetEmitter: (event) ->
		# todo parse out all the types necessary
		#
		# tweet.new
		# tweet.new.mine
		# retweet.new
		# retweet.new.mine
		# retweet.new.ofmine
		# mention.new
		#

		# until DMs are supported in twit...
		if event.direct_message?
			@dmEmitter event
			return

		types = ['tweet.new']

		# our tweet?
		if event.user.id_str is @user.id then types.push 'tweet.new.mine'

		# is it a retweet?
		if event.retweeted_status?
			types.push 'retweet.new'
			# retweet of our tweet?
			if event.retweeted_status.user.id_str is @user.id then types.push 'retweet.new.ofmine'
			# we retweeted?
			if event.user.id_str is @user.id then types.push 'retweet.new.mine'

		# Indentception.
		# Oh, and check for a mention.
		if event.entities.user_mentions.length > 0
			for mention in event.entities.user_mentions
				do (mention) =>
					if mention.id_str is @user.id and !types.has 'mention.new'
						types.push 'mention.new'

		# fuck you twitter and your html tweet.source bullshit. seriously, fuck you.
		source = $(event.source)
		event.source =
			link: source.attr('href')
			name: source.text()

		event.text = twitter.autoLink event.text, { urlEntities: event.entities.urls }

		# todo run filters by the tweet here, indicate in doc.filteredBy and doc.hide if the tweet was ignored,
		# and if so by what filters (we will count blocking as a filter) so that in the future if a filter is removed,
		# we can just pull anything it affected and see if there were any other filters acting on it at the same time.

		# because we're not guaranteed that this tweet hasn't already been received on another account,
		# we have to assume it might have been, and then use an upsert if it hasn't been
		query =
			event: event
		updateQuery =
			$set:
				eventTime: Date.now()
			$addToSet:
				ownerId: @user.id
				eventType: { $each: types }
		@crimson.db.events.update query, updateQuery, { upsert: true }, (err, numReplaced, upsert) =>
			if err
				debug 'stream.tweetEmitter nedb err: ' + err
				throw err

			# until we know exactly what the f the _id was that was modified with the update query,
			# we have to use this. ref: https://github.com/louischatriot/nedb/issues/72
			@crimson.db.events.findOne { 'event.id_str': event.id_str }, (err, doc) =>
				@emit type, doc for type in types

	dmEmitter: (event) ->
		types = ['dm.new']
		if event.direct_message.recipient_id is @user.id
			types.push 'dm.received'
		else if event.direct_message.sender_id is @user.id
			types.push 'dm.sent'
		#else
			# I...hope this never happens.

		event.text = twitter.autoLink event.text, { urlEntities: event.entities.urls }

		query =
			event: event
		updateQuery =
			$set:
				eventTime: Date.now()
			$addToSet:
				ownerId: @user.id
				eventType: { $each: types }

		@crimson.db.events.update query, updateQuery, { upsert: true }, (err, numReplaced, upsert) =>
			if err
				debug 'stream.dmEmitter nedb err: ' + err
				throw err

			# until we know exactly what the f the _id was that was modified with the update query,
			# we have to use this. ref: https://github.com/louischatriot/nedb/issues/72
			@crimson.db.events.findOne { 'event.direct_message.id_str': event.direct_message.id_str }, (err, doc) =>
				@emit type, doc for type in types

	deleteEmitter: (event) ->
		query =
			id_str: event.status.id_str
			user_id_str: event.status.user_id_str

		@crimson.db.events.remove query, false, (err) ->
			if err
				debug 'stream.deleteEmitter nedb err: ' + err
				throw err
			@emit 'tweet.delete', event

	# scumbag twitter, acts as if we can iterate over a range when they moved on to snowflake ids
	scrubgeoEmitter: (event) ->
		# todo...maybe never. idk

	connectEmitter: ->
		@emit 'twitter.connecting'

	disconnectEmitter: (dropMsg) ->
		@emit 'twitter.disconnected', dropMsg

	reconnectEmitter: (req, res, interval) ->
		@emit 'twitter.reconnecting', interval

	withheldTweetEmitter: (event) ->
		withheld =
			eventType: ['tweet.censored']
			type: 'tweet'
			id_str: event.id
			user_id_str: event.user_id
			withheld_in_countries: event.withheld_in_countries
		@emit 'tweet.censored', withheld

	withheldUserEmitter: (event) ->
		withheld =
			eventType: ['tweet.censored']
			type: 'user'
			user_id_str: event.id
			withheld_in_countries: event.withheld_in_countries
		@emit 'tweet.censored', withheld

	friendsEmitter: (friends) ->
		@user.friends = friends
		@emit 'twitter.friends', friends

	userUpdateEmitter: (event) ->
		@user.profile = event.source
		@emit 'twitter.userupdate'

	followEmitter: (event) ->
		if @user.id is event.source.id_str
			# we're following them
			@user.friends.push event.target.id_str
			@emit 'twitter.newfriend', event.target
		else
			# they're following us
			query =
				ownerId: @user.id
				eventType: ['follower.new']
				eventTime: Date.now()
				event: event
			@crimson.db.events.insert query, (err, doc) =>
				if err
					debug 'stream.followEmitter nedb err: ' + err
					throw err
				@emit 'follower.new', doc

	unfollowEmitter: (event) ->
		@user.friends.remove event.target.id_str
		@emit 'twitter.lostfriend', event.target

	# to hell with you damn brits, it's FAVORITE. OR. NOT OUR. THIS CODE IS NOT BRITISH.
	favoriteEmitter: (event) ->
		if @user.id is event.source.id_str
			# us, to theirs
			query =
				ownerId: @user.id
				eventType: 'tweet.new'
				event:
					id_str: event.target_object.id_str
					favorited: { $set: true }
			@crimson.db.events.update query, (err) =>
				if err
					debug 'stream.favoriteEmitter nedb err: ' + err
					throw err
				@emit 'twitter.favorited', event.target_object
		else
			# them, to ours
			query =
				ownerId: @user.id
				eventType: ['favorite.new.ofmine']
				eventTime: Date.now()
				event: event
			@crimson.db.events.insert query, (err, doc) =>
				if err
					debug 'stream.favoriteEmitter nedb err: ' + err
					throw err
				@emit 'favorite.new.ofmine', doc

	unfavoriteEmitter: (event) ->
		if @user.id is event.source.id_str
			# us, to theirs
			query =
				ownerId: @user.id
				eventType: 'tweet.new'
				event:
					id_str: event.target_object.id_str
					favorited: { $set: false }
			@crimson.db.events.update query, (err) =>
				if err
					debug 'stream.unfavoriteEmitter nedb err: ' + err
					throw err
				@emit 'twitter.unfavorited', event.target_object
		else
			# them, to ours

			# discard previous favoriting notifications here
			query =
				ownerId: @user.id
				eventType: 'favorite.new.ofmine'
				'event.target_object.id_str': event.target_object.id_str
			@crimson.db.events.remove query, (err) =>
				if err
					debug 'stream.unfavoriteEmitter nedb err: ' + err
					throw err
				@emit 'unfavorite.new.ofmine', doc

	# todo trigger a filter update...?
	blockEmitter: (event) ->
		@user.blocked.push event.target.id_str
		@emit 'twitter.blocked', event.target

	unblockEmitter: (event) ->
		@user.blocked.remove event.target.id_str
		@emit 'twitter.unblocked', event.target

	# no way in hell am I doing lists here. not in the first versions. fuck that shit.

	couple: (decouple = false) ->
		method = if decouple then 'removeListener' else 'addListener'

		# the standard bs
		@twitStream[method] 'tweet', @tweetEmitter.bind @
		@twitStream[method] 'direct_message', @dmEmitter.bind @
		@twitStream[method] 'delete', @deleteEmitter.bind @
		# disabled for now
		#method 'scrub_geo', @scrubgeoEmitter
		@twitStream[method] 'connect', @connectEmitter.bind @
		@twitStream[method] 'disconnect', @disconnectEmitter.bind @
		@twitStream[method] 'reconnect', @reconnectEmitter.bind @
		@twitStream[method] 'status_withheld', @withheldTweetEmitter.bind @
		@twitStream[method] 'user_withheld', @withheldUserEmitter.bind @
		@twitStream[method] 'friends', @friendsEmitter.bind @

		# special user stream events
		@twitStream[method] 'user_update', @userUpdateEmitter.bind @
		@twitStream[method] 'follow', @followEmitter.bind @
		@twitStream[method] 'unfollow', @unfollowEmitter.bind @
		@twitStream[method] 'favorite', @favoriteEmitter.bind @
		@twitStream[method] 'unfavorite', @unfavoriteEmitter.bind @
		@twitStream[method] 'blocked', @blockEmitter.bind @
		@twitStream[method] 'unblocked', @unblockEmitter.bind @

	emit: (args...) ->
		# please work on the first try, oh please oh please
		@crimson.emit.apply @crimson, args
		EventEmitter::emit.apply @, args

	__destroy: ->
		# todo remove all listeners from twitstream and close it and kill it with fire
		@twitStream.stop()
		@couple true
		@emit '__destroy'

module.exports = stream
