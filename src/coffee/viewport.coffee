class viewport
	constructor: () ->
		@timelines = {}
		@visible = 1
		@first = 0
		@minWidth = 300
		@resizeTimer = null
	addTimeline: (timeline) ->
		timelineName = if timeline.user then "#{timeline.type}.#{timeline.user.id}" else timeline.type
		if !@timelines[timelineName]? then @timelines[timelineName] = timeline else false
		@redraw()
	removeTimeline: (timeline) ->
		timelineName = if timeline.user then "#{timeline.type}.#{timeline.user.id}" else timeline.type
		if !@timelines[timelineName]? then delete @timelines[timelineName]
		timeline.__destroy()
		@redraw()
		true
	scrollTo: (relative) ->
		numTimelines = Object.keys(@timelines).length
		viewportWidth = $('#viewport').width()
		maxTimelines = Math.floor(viewportWidth / minWidth)

		# make sure we CAN scroll in the first place... (this is a shortcut so we can bail out if necessary)
		if maxTimelines <= numTimelines then return false

		# todo - determine if we can move forward or back within the viewport
	resize: ->
		# throttle resizing, webkit likes to send resize events as the window is being dragged,
		# and not wait until the very end.
		if @resizeTimer? then clearTimeout @resizeTimer
		setTimeout @redraw, 800
		true
	redraw: ->
		numTimelines = Object.keys(@timelines).length
		viewportWidth = $('#viewport').width()
		maxTimelines = Math.floor(viewportWidth / minWidth)
		if numTimelines < maxTimelines then maxTimelines = numTimelines
		timelineWidth = viewportWidth / numTimelines
		overflowWidth = viewportWidth % numTimelines

		viewportOffset = first * viewportWidth

		# and now, resize (without animation for now, might change later)
		$('.column').width(timelineWidth)
		$('.column-overflow').width(overflowWidth)
		$('#viewport').css('margin-left', viewportOffset + 'px')
		true

module.exports = viewport
