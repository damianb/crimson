#
# crimson - desktop social network client
# ---
# @copyright (c) 2013 Damian Bushong <katana@codebite.net>
# @license MIT license
# @url <https://github.com/damianb/crimson>
# @twitter <https://twitter.com/burningcrimson>
#

{EventEmitter} = require 'events'
debug = (require 'debug')('compost')

#
# compost pile, where minor errors go to die.
#   or just lay unnoticed until someone's bright enough to open up the logs.
# todo: determine if it actually needs to be an eventemitter.
#
class compost extends EventEmitter
	constructor: (@errorDb) ->
		super()
