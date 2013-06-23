class viewport
	constructor: () ->
		@timelines = {}
		@visible = 1
		@first = 0
		@minWidth = 150
	addTimeline: (timeline) ->
		timelineName = if timeline.user then "#{timeline.type}.#{timeline.user.id}" else timeline.type
		if !@timelines[timelineName]? then @timelines[timelineName] = timeline else false
	removeTimeline: (timeline) ->
		timelineName = if timeline.user then "#{timeline.type}.#{timeline.user.id}" else timeline.type
		if !@timelines[timelineName]? then delete @timelines[timelineName]
		timeline.__destroy()
		true
	scrollTo: (timeline) ->
		# todo
	resize: () ->
		# todo

module.exports = viewport
