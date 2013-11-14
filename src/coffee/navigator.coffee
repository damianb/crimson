#
# crimson - desktop social network client
# ---
# @copyright (c) 2013 Damian Bushong <katana@codebite.net>
# @license MIT license
# @url <https://github.com/damianb/crimson>
# @twitter <https://twitter.com/burningcrimson>
#

debug = (require 'debug')('navigator')
timeline = require './timeline'

#
# Timeline navigator - holds all timelines for all accounts, including super accounts
#  Name inspired by the Guild Navigators of the Dune verse.
#
class navigator
	constructor: (@director, @compost) ->
		@activeTimeline = null
		@timelines =
			super:
				home: null
				notify: null
			user: {}
		# todo make initial active timeline the @timelines.super.home timeline by default
	addAccount: () ->
		# todo
	delAccount: () ->
		# todo
	changeFocus: () ->
		# change what timeline we're focusing on!
		# must change active timeline. will have to deactivate the prior active timeline however (if there was one).

		# todo

module.exports = navigator
