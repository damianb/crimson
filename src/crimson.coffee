{EventEmitter} = require 'events'
jade = require 'jade'
fs = require 'fs'
heelloApi = require 'heello'
os = require 'os'

class _crimson extends EventEmitter
	constructor: (options) ->
		@userId
		@username
		@heello = null
		@timelines =
			home: null
			notify: null
		@filters = {}
		super()
	heartbeat: () ->
		# todo
	addPing: () ->
		# todo
	@filter: () ->
	@appKey: new Buffer('ZThhYTg4NGJmM2NlYzk1NmQ2NGJjODc3NDc1N2U4Nzk5ZTFlZGEwZGY3MmNlNjQyOWYxYTRlZWNiN2ViZDQxYw==', 'base64').toString()
	@appSecret: new Buffer('MDljMTE2MjRmN2EyZTZiNTRjODFmZDcxMjQzYTY5Y2Q5OTZmZDZhOTliM2ZjMzk0MmNjMzhiODNjMGYyM2FhNg==', 'base64').toString()
	@localPort

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

class ping
	constructor: (data) ->
		#todo

$('#version').text "running node-webkit, powered by node #{process.version} #{os.platform()}"