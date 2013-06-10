{EventEmitter} = require 'events'
jade = require 'jade'
fs = require 'fs'
os = require 'os'
$('#version').text "running node-webkit, powered by node #{process.version} #{os.platform()}"

class _crimson extends EventEmitter
	constructor: (options) ->
		@timelines = {
			home: null
			notify: null
		}
		super()

class timeline extends EventEmitter
	constructor: (@type, @pings)
		if !@pings? then @pings = []
		@lastPingId = null
	addPing: (ping) ->
		@lastPingId = ping.id if ping.id > @lastPingId
		@pings.push ping
		@emit 'newPing', ping
	paging: (offset, count) ->
		# todo