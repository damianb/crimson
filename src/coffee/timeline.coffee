#
# crimson - desktop social network client
# ---
# @copyright (c) 2013 Damian Bushong <katana@codebite.net>
# @license MIT license
# @url <https://github.com/damianb/crimson>
# @twitter <https://twitter.com/burningcrimson>
#

{EventEmitter} = require 'events'
debug = (require 'debug')('timeline')
async = require 'async'
twitter = require 'twitter-text'

#
# Timeline object, holds events in a single array if active
#
class timeline
	constructor: (@user, @filter, @eventDb, @type) ->
		@active = false
		if !timeline.timelineEvents[@type]?
			throw new Error 'Unrecognized timeline type provided'

		# if we're a super timeline...
		@isSuper = !!(@type is 'superhome' or @type is 'supernotify')
		{@stream} = @user

		@data = []
	focus: (fn) ->
		# todo query events database (or use API queries) to obtain latest events.
		# ...API queries should likely happen during initial connection stages though
		#     - prepopulation of these columns' data is vital!
		# build our query based on timeline event types, etc.
		query =
			eventType:
				$in: timeline.timelineEvents

		# only use an ownerId if we're not using a ^super timeline
		if !@isSuper then query.ownerId = @user.id

		@eventDb.find query, (err, docs) =>
			docs.sort (a,b) ->
				if a.eventTime > b.eventTime then 1 else if b.eventTime > a.eventTime then -1 else 0
			docs.forEach (doc) ->
				@insert doc
			@active = true
			fn null, docs.length
	blur: (fn) ->
		@data = []
		@active = false

		# it's safe to decouple timeline from view now
		fn null
	insert: (entry, fn) ->
		# short-circuit. if we're not active, ignore the event.
		if !@active
			fn false
			return

		if entry.eventType.has 'tweet.new'
			entry.type = 'tweet'
			# override type to be retweet if it is such
			if entry.eventType.has 'retweet.new'
				entry.type 'retweet'
		else if entry.eventType.has 'dm.new'
			entry.type = 'dm'
		else if entry.eventType.has 'favorite.new'
			entry.type = 'favorite'
		else if entry.eventType.has 'follower.new'
			entry.type = 'follower'

		# todo apply filters?

		# note, entries should be handled properly on insertion. they may not all be tweets!
		# ( S-SENPAI, THAT'T NOT A TWEET! ///// )
		fn? null, @data.push entry
	prime: (fn) ->
		# fetches more data from the API according to timeline type.
		switch @type
			when 'home'
				# todo
			when 'mentions'
				# todo
			when 'messages'
				# todo reduce redundant redundancy
				async.parallel {
					receivedMessages: (callback) =>
						opts =
							count: 50
							include_entities: true
						@user.api.get 'direct_messages', opts, callback
					,
					sentMessages: (callback) =>
						opts =
							count: 50
							include_entities: true
						@user.api.get 'direct_messages/sent', opts, callback
				}, (err, res) =>
					# insert all results into events db - assuming they're not already in there.
					{receivedMessages, sentMessages} = res
					if receivedMessages.length
						receivedMessages.forEach (event) =>
							types = ['dm.new', 'dm.received']
							event.text = twitter.autoLink event.text, { urlEntities: event.entities.urls }
							query =
								event: event
							updateQuery =
								$set:
									eventTime: Date.now()
								$addToSet:
									ownerId: @user.id
									eventType: { $each: types }

							@eventDb.update query, updateQuery, { upsert: true }, (err, numReplaced, upsert) =>
								if err
									debug 'timeline.prime (receivedMessages) nedb err: ' + err
									throw err

								# until we know exactly what the hell the _id was that was modified with the update query,
								# we have to use this. ref: https://github.com/louischatriot/nedb/issues/72
								@eventsDb.findOne { 'event.direct_message.id_str': event.direct_message.id_str }, (err, doc) =>
									if err
										debug 'timeline.prime (receivedMessages) nedb err: ' + err
										throw err
									@data.push doc
					if sentMessages.length
						sentMessages.forEach (event) =>
							types = ['dm.new', 'dm.sent']
							event.text = twitter.autoLink event.text, { urlEntities: event.entities.urls }
							query =
								event: event
							updateQuery =
								$set:
									eventTime: Date.now()
								$addToSet:
									ownerId: @user.id
									eventType: { $each: types }

							@eventDb.update query, updateQuery, { upsert: true }, (err, numReplaced, upsert) =>
								if err
									debug 'timeline.prime (sentMessages) nedb err: ' + err
									throw err

								# until we know exactly what the hell the _id was that was modified with the update query,
								# we have to use this. ref: https://github.com/louischatriot/nedb/issues/72
								@eventsDb.findOne { 'event.direct_message.id_str': event.direct_message.id_str }, (err, doc) =>
									if err
										debug 'timeline.prime (sentMessages) nedb err: ' + err
										throw err
									@data.push doc
			when 'events'
				# todo
			else
				# probably a super timeline, we don't want to do -anything- in this case.
				fn? null

	remove: (condition, expect, fn) ->
		# short-circuit. if we're not active, ignore the event.
		if !@active
			fn false
			return
		debug "looking for data to remove from angular view data - entry.#{condition} = #{expect}"

		(@data.map (val, index) ->
			if val.condition is expect then return index
		).forEach (index) ->
			@data = @data.remove index
		fn null

	# static properties
	@timelineEvents =
		superhome: ['tweet.new', 'tweet.new.mine', 'retweet.new', 'retweet.new.mine', 'mention.new']
		supernotify: ['mention.new', 'follower.new', 'retweet.new.ofmine', 'favorite.new.ofmine']
		home: ['tweet.new', 'tweet.new.mine', 'retweet.new']
		mentions: ['mention.new']
		messages: ['dm.sent', 'dm.received']
		events: ['follower.new', 'retweet.new.ofmine', 'favorite.new.ofmine']

module.exports = timeline
