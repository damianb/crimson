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

class timeline
	constructor: (@stream, @type) ->
		@active = false
		if !timeline.timelineEvents[@type]?
			throw new Error 'Unrecognized timeline type provided'
		@data = []
	focus: (fn) ->
		# todo query events database (or API) to obtain latest events

		@active = true
	blur: (fn) ->
		@data = []
		@active = false

		# safe to decouple timeline from view now
	insert: (entry, fn) ->
		# short-circuit. if we're not active, ignore the event.
		if !@active
			fn false
			return

		fn null, @data.push entry
	remove: (condition, expect, fn) ->
		# short-circuit. if we're not active, ignore the event.
		if !@active
			fn false
			return

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
