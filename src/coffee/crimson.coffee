{EventEmitter} = require 'events'
jade = require 'jade'
fs = require 'fs'
heelloApi = require 'heello'
http = require 'http'
os = require 'os'
pkg = require (__dirname + '/../../package.json')

class _crimson extends EventEmitter
	constructor: (options) ->
		@userId
		@username
		@timelines =
			home: null
			notify: null
		@filters = {}

		@tokenPort: 33233 #todo see how common this port is in use...
		@heello = new heelloApi {
			appId: new Buffer('ZThhYTg4NGJmM2NlYzk1NmQ2NGJjODc3NDc1N2U4Nzk5ZTFlZGEwZGY3MmNlNjQyOWYxYTRlZWNiN2ViZDQxYw==', 'base64').toString()
			appSecret: new Buffer('MDljMTE2MjRmN2EyZTZiNTRjODFmZDcxMjQzYTY5Y2Q5OTZmZDZhOTliM2ZjMzk0MmNjMzhiODNjMGYyM2FhNg==', 'base64').toString()
			callbackURI: "http://127.0.0.1:#{@tokenPort}"
			userAgent: 'crimson-client_' + pkg.version
		}
		super()
	heartbeat: () ->
		# todo
	addPing: () ->
		# todo
	@filter: () ->

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

tokenIntercept = (port) ->
	# asdf

$('#version').text "running node-webkit, powered by node #{process.version} #{os.platform()}"