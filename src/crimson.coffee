{EventEmitter} = require 'events'
heelloApi = require 'heello'
os = require 'os'

class crimson extends EventEmitter
	constructor: (options) ->
		@userId
		@username
		@heello = null
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

class timeline
	constructor: (@type, @pings) ->
		if !@pings? then @pings = []

class ping
	constructor: (data) ->
		#todo

$('#version').text "running node-webkit, powered by node #{process.version} #{os.platform()}"

tokenInterceptor = () ->
	# todo
