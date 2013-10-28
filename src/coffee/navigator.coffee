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
	constructor: (@director) ->
		# todo

module.exports = navigator
