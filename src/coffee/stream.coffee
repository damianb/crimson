{EventEmitter} = require 'events'
debug = (require 'debug')('stream')

class stream extends EventEmitter
	constructor: (@user) ->
		{@crimson, @api} = @user
		@twitStream = @api.stream('user')
		couple false
		super()

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

		types = ['tweet.new']
		query =
			event: event
		updateQuery =
			$set:
				eventTime: Date.now()
			$addToSet:
				ownerId: @user.id
				eventType: types
		@crimson.db.events.update query, updateQuery, { upsert: true }, (err, numReplaced, upsert) =>
			if err
				debug 'stream.tweetEmitter nedb err: ' + err
				throw err
			# @emit type, doc for type in query.eventType
			# todo get affected entry

	deleteEmitter: (event) ->
		query =
			id_str: event.status.id_str
			user_id_str: event.status.user_id_str

		@crimson.db.events.remove query, false, (err) ->
			if err
				debug 'stream.deleteEmitter nedb err: ' + err
				throw err
			@emit 'tweet.delete', event

	scrubgeoEmitter: (event) ->
		# todo

	connectEmitter: ->
		@emit 'twitter.connecting'

	disconnectEmitter: (dropMsg) ->
		@emit 'twitter.disconnected', dropMsg

	reconnectEmitter: (req, res, interval) ->
		@emit 'twitter.reconnecting', interval

	withheldTweetEmitter: (event) ->
		withheld =
			type: 'tweet'
			id_str: event.id
			user_id_str: event.user_id
			withheld_in_countries: event.withheld_in_countries
		@emit 'tweet.censored', withheld

	withheldUserEmitter: (event) ->
		withheld =
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

			# discard any and all notifications here
			query =
				ownerId: @user.id
				eventType: 'favorite.new.ofmine'
				'event.target_object.id_str': event.target_object.id_str
			@crimson.db.events.remove query, (err) =>
				if err
					debug 'stream.unfavoriteEmitter nedb err: ' + err
					throw err
				@emit 'unfavorite.new.ofmine', doc

	blockEmitter: (event) ->

		@user.blocked.push event.target.id_str
		@emit 'twitter.blocked', event.target

	unblockEmitter: (event) ->
		@user.blocked.remove event.target.id_str
		@emit 'twitter.unblocked', event.target

	# no way in hell am I doing lists here. not in the first versions. fuck that shit.

	couple: (decouple = false) ->
		method = if decouple then 'removeListener' else 'on'

		# the standard bs
		@twitStream[method] 'tweet', @tweetEmitter
		@twitStream[method] 'delete', @deleteEmitter
		# disabled for now
		#@twitStream[method] 'scrub_geo', @scrubgeoEmitter
		@twitStream[method] 'connect', @connectEmitter
		@twitStream[method] 'disconnect', @disconnectEmitter
		@twitStream[method] 'reconnect', @reconnectEmitter
		@twitStream[method] 'status_withheld', @withheldTweetEmitter
		@twitStream[method] 'user_withheld', @withheldUserEmitter
		@twitStream[method] 'friends', @friendsEmitter

		# special user stream events
		@twitStream[method] 'user_update', @userUpdateEmitter
		@twitStream[method] 'follow', @followEmitter
		@twitStream[method] 'unfollow', @unfollowEmitter
		@twitStream[method] 'favorite', @favoriteEmitter
		@twitStream[method] 'unfavorite', @unfavoriteEmitter
		@twitStream[method] 'blocked', @blockedEmitter
		@twitStream[method] 'unblocked', @unblockedEmitter

	emit: (args...) ->
		# please work on the first try, oh please oh please
		@crimson.emit.apply @crimson, args
		EventEmitter.emit.apply @, args

	__destroy: ->
		# todo remove all listeners from twitstream and close it and kill it with fire
		@twitStream.close
		@couple true

