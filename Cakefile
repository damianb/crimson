#
# requires, vars, and autoconfiguration
#

{spawn, exec} = require 'child_process'
fs = require 'fs'
path = require 'path'
util = require 'util'
mkdirp = require 'mkdirp'
async = require 'async'
isWindows = !!process.platform.match(/^win/)

# ANSI Terminal Colors
bold = '\x1b[0;1m'
green = '\x1b[0;32m'
reset = '\x1b[0m'
red = '\x1b[0;31m'

#
# build configuration (for tools and such)
#

appName = 'crimson'
jadeOpts = '-P'
coffeeOpts = '-bmc'
uglifyOpts = '-mc'
lessOpts = '--no-ie-compat -x'
buildDir = "build/{appName}.app"

#
# files to build/watch, etc.
#
files =
	builddirs: [
		'assets/css'
		'assets/img'
		'assets/js/crimson/'
		'assets/templates'
	]
	controllers: false
	jade: []
	less: [
		'crimson'
	]
	coffee: [
		'client'
		'client_authorize'
		'core'
		'global'
		'stream'
		'timeline'
		'ui'
	]
	copy: [
		'templates/entries.jade'
		'css/bootstrap.min.css'
		'js/bootstrap.min.js'
		'js/jquery.min.js'
		'js/jquery.hotkeys.js'
		'js/jquery.relatize_date.js'
		'img/glyphicons-halflings-white.png'
		'img/glyphicons-halflings.png'
	]
	rootcopy: [
		'package.json'
		'index.html' # won't need this soon
	]

#
# build command configuration!
#

buildCommands =
	# pre-build actions to run...should be async.  (file, fn) - or just (fn) to only run once
	pre:
		builddirs: (dir, fn) ->
			mkdirp path.normalize(buildDir + '/' + dir), (err) ->
				_log 'builddirs', dir, err
				fn? err
		coffee: (file, fn) ->
			compile 'coffeecopy', file, fn
		# todo: file-exists checks on less, jade, coffee, uglify, copy, rootcopy

	# command to exec...should be sync.  (file)
	run:
		less: (file) ->
			"lessc #{lessOpts} src/less/#{file}.less #{buildDir}/assets/css/#{file}.css"
		jade: (file) ->
			"jade #{jadeOpts} < src/jade/#{file}.jade > #{buildDir}/#{file}.html"
		coffee: (file) ->
			"coffee #{coffeeOpts} #{buildDir}/assets/js/{appName}/#{file}.coffee"
		uglify: (file) ->
			"uglifyjs #{uglifyOpts} < #{buildDir}/assets/js/#{file}.js > #{buildDir}/assets/js/#{file}.min.js"
		copy: (file) ->
			if isWindows
				"copy /Y #{path.normalize('src/' + file)} #{path.normalize(buildDir + '/assets/' + file)}"
			else
				"cp src/#{file} #{buildDir}/assets/#{file}"
		controllers: ->
			"coffee #{coffeeOpts} -j #{path.normalize(buildDir+'/assets/js/{appName}/controllers.js')} src/coffee/controllers.coffee src/coffee/controller/"
		rootcopy: (file) ->
			if isWindows
				"copy /Y #{path.normalize('src/buildroot/'+file)} #{path.normalize(buildDir+'/'+file)}"
			else
				"cp src/buildroot/#{file} #{buildDir}/#{file}"
		coffeecopy: (file) ->
			if isWindows
				cmd = "copy /Y #{path.normalize('src/coffee/'+file+'.coffee')} #{path.normalize(buildDir+'/assets/js/{appName}/'+file+'.coffee')}"
			else
				cmd = "cp src/coffee/#{file}.coffee #{buildDir}/assets/js/{appName}/#{file}.coffee"
		builddirs: false # deliberately ignoring the exec for builddir

	# post-build actions to run...should be async.  (file, fn) - or just (fn) to only run once
	post: {} #none

	messages:
		error:
			def: (type, file, err) ->
				"#{type}: failed to compile #{file}; #{err}"
			controllers: (type, file, err) ->
				"#{type}: failed to compile controllers; #{err}"
			copy: (type, file, err) ->
				"#{type}: failed to copy #{file}; #{err}"
			rootcopy: (type, file, err) ->
				"#{type}: failed to copy #{file}; #{err}"
			coffeecopy: (type, file, err) ->
				"#{type}: failed to copy #{file}.coffee; #{err}"
			builddirs: (type, file, err) ->
				"#{type}: failed to create directory #{file}"
		success:
			def: (type, file) ->
				"#{type}: compiled #{file} successfully"
			controllers: (type, file) ->
				"#{type}: compiled controllers successfully"
			copy: (type, file) ->
				"#{type}: copied #{file} successfully"
			rootcopy: (type, file) ->
				"#{type}: copied #{file} successfully"
			coffeecopy: (type, file) ->
				"#{type}: copied #{file}.coffee successfully"
			builddirs: (type, file) ->
				"#{type}: created directory #{file} successfully"

#
# mega tasks
#

task 'build', 'run all build tasks', ->
	async.eachSeries [
		'builddirs'
		'rootcopy'
		'less'
		#'jade'
		'coffee'
		'controllers'
		#'uglify'
		'copy'
	], build, (err) ->
		if err
			log 'build error!', err, true
		else
			log 'build complete!'

# todo - finish. Need to automate this for windows and stuff.
#task 'package', 'package a release', ->
#	async.eachSeries [
#		'builddirs'
#		'rootcopy'
#		'less'
#		'jade'
#		'coffee'
#		#'uglify'
#		'copy'
#	], build, (err) ->
#		if err
#			log 'build error!', err, true
#		else
#			log 'build complete!'

#
# individual build tasks
#

task 'build:builddirs', 'prepares build dir\'s structure', -> build 'builddir'
task 'build:jade', 'build jade files into html', -> build 'jade'
task 'build:less', 'build less files into css', -> build 'less'
task 'build:coffee', 'build coffeescript files into js', -> build 'coffee'
task 'build:controllers', 'build controllers', -> build 'controllers'
#task 'build:uglify', 'uglify/minify js files', -> build 'uglify'
task 'build:copy', 'copy necessary files to build dir', -> build 'copy'
task 'build:rootcopy', 'copy necessary files to build root dir', -> build 'rootcopy'

#
# helper functions
#

build = (type, final) ->
	# fileset is deliberately separate from type here.
	fileset = if type is 'uglify' then 'coffee' else type

	async.series [
		# prebuild!
		(fn) ->
			if buildCommands.pre[type]
				if buildCommands.pre[type].length is 2
					async.each files[fileset], buildCommands.pre[type], fn
				else # assuming .length is 1 here, only operating on a single arg
					buildCommands.pre[type] fn
			else
				fn null
		# exec!
		(fn) ->
			if !!buildCommands.run[type]
				if util.isArray files[fileset]
					async.each files[fileset], (file, cb) ->
						compile type, file, cb
					, fn
				else
					compile type, null, fn
			else if buildCommands.run[type] is false
				fn null
			else
				fn "missing run command for #{type} - provide a function as documented or boolean false to disable"
		# postbuild!
		(fn) ->
			if buildCommands.post[type]
				if buildCommands.post[type].length is 2
					async.each files[fileset], buildCommands.post[type], fn
				else # assuming .length is 1 here, only operating on a single arg
					buildCommands.post[type] fn
			else
				fn null
	], (err) ->
		final? err

compile = (type, file, fn) ->
		exec (buildCommands.run[type] file), (err, stdout, stderr) ->
			_log type, file, err, stderr
			fn? err

log = (message, explanation, isError = false) ->
	if isError
		message = "#{red} err: #{message}#{reset}"
	else
		message = green + message.trim() + reset
	util.log message + ' ' + (explanation or '')

_log = (type, file, err, moreErr) ->
	if err
		msg = buildCommands.messages.error[type] or buildCommands.messages.error.def
		log (msg type, file, err), moreErr, true
	else
		msg = buildCommands.messages.success[type] or buildCommands.messages.success.def
		log (msg type, file)
