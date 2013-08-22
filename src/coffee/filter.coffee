{ $ } = global

class filter
	constructor: (@crimson) ->
		# todo

	runFilters: (doc) ->
		# is it a tweet?
		if doc.eventType.indexOf('tweet.new') isnt -1
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
