{EventEmitter} = require 'events'
debug = (require 'debug')('stream')

class stream extends EventEmitter
	constructor: (@user) ->
		{@crimson, @api}
		@twitStream = @api.stream('user')
		@twitStream.on 'tweet', @tweetEmitter
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
		# follower.new - not tweet
		# favorite.new.ofmine - not tweet
		#
		query =
			ownerId: @user.id
			eventType: []
			eventTime: Date.now()
			event: event

		@crimson.db.events.insert query, (err, doc) =>
			if err
				debug 'stream.tweetEmitter nedb err: ' + err
				throw Err
			@emit type, doc for type in query.eventType

	deleteEmitter: (event) ->
		query =
			id_str: event.status.id_str
			user_id_str: event.status.user_id_str

		@crimson.db.events.remove query, false, (err) ->
			if err
				debug 'stream.deleteEmitter nedb err: ' + err
				throw Err
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
					throw Err
				@emit 'follower.new' doc

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
					throw Err
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
					throw Err
				@emit 'favorite.new.ofmine' doc

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
					throw Err
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
					throw Err
				@emit 'unfavorite.new.ofmine' doc

# todo - block tracking, so we know who we're ignoring the fuck out of.

	blockEmitter: (event) ->
		# todo

	unblockEmitter: (event) ->
		# todo

	# no way in hell am I doing lists here. not in the first versions. fuck that shit.

	emit: (args...) ->
		# please work on the first try, oh please oh please
		@crimson.emit.apply @crimson, args
		EventEmitter.emit.apply @, args

	__destroy: ->
		# todo remove all listeners from twitstream and close it and kill it with fire
		@twitStream.removeListener 'tweet', @tweetEmitter
		@twitStream.removeListener 'delete', @deleteEmitter
