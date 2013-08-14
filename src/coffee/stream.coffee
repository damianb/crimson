{EventEmitter} = require 'events'
debug = (require 'debug')('stream')

class stream extends EventEmitter
	constructor: (@crimson, @api) ->
		@twitStream = @api.stream('user')
		@twitStream.on 'tweet', @tweetEmitter
		super()
	tweetEmitter: (event) ->
		# todo see what all types this falls under
		types = []

		@crimson.db.events.insert {
			eventType: types
			eventTime: Date.now()
			event: event
		}, (err, doc) =>
			if err
				debug 'stream.tweetEmitter nedb err: ' + err
				throw Err
			@emit type, doc for type in types
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
	withheldEmitter
	__destroy: ->
		@twitStream.removeListener 'tweet', @tweetEmitter
		@twitStream.removeListener 'delete', @deleteEmitter
