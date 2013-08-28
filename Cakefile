###
crimson - desktop social network client
---
author: Damian Bushong <katana@codebite.net>
license: MIT license
url: https://github.com/damianb/crimson
twitter: https://twitter.com/burningcrimson
###

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

jadeOpts = '-P'
coffeeOpts = '-b'
uglifyOpts = '-mc'
lessOpts = '--no-ie-compat -x'
buildDir = 'build/crimson.app'

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
	jade: [
		'index'
		'authorize'
	]
	less: [
		'crimson'
	]
	coffee: [
		'client'
		'core'
		'filter'
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
		# todo: file-exists checks on less, jade, coffee, uglify, copy, rootcopy

	# command to exec...should be sync.  (file)
	run:
		less: (file) ->
			"lessc #{lessOpts} src/less/#{file}.less #{buildDir}/assets/css/#{file}.css"
		jade: (file) ->
			"jade #{jadeOpts} < src/jade/#{file}.jade > #{buildDir}/#{file}.html"
		coffee: (file) ->
			"coffee #{coffeeOpts} -mo #{buildDir}/assets/js/crimson/ src/coffee/#{file}.coffee"
		uglify: (file) ->
			"uglifyjs #{uglifyOpts} < #{buildDir}/assets/js/#{file}.js > #{buildDir}/assets/js/#{file}.min.js"
		copy: (file) ->
			if isWindows
				"copy /Y #{path.normalize('src/' + file)} #{path.normalize(buildDir + '/assets/' + file)}"
			else
				"cp -u src/#{file} #{buildDir}/assets/#{file}"
		rootcopy: (file) ->
			if isWindows
				"copy /Y #{path.normalize('src/buildroot/'+file)} #{path.normalize(buildDir+'/'+file)}"
			else
				"cp -u src/buildroot/#{file} #{buildDir}/#{file}"
		coffeecopy: (file) ->
			if isWindows
				cmd = "copy /Y #{path.normalize('src/coffee/'+file+'.coffee')} #{path.normalize(buildDir+'/assets/js/crimson/'+file+'.coffee')}"
			else
				cmd = "cp -u src/coffee/#{file}.coffee #{buildDir}/assets/js/crimson/#{file}.coffee"
		builddirs: false # deliberately ignoring the exec for builddir

	# post-build actions to run...should be async.  (file, fn) - or just (fn) to only run once
	post:
		coffee: (file, fn) ->
			compile 'coffeecopy', file, fn

	messages:
		error:
			def: (type, file, err) ->
				"#{type}: failed to compile #{file}; #{err}"
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

task 'build', 'build all - less, jade, coffeescript', ->
	async.eachSeries [
		'builddirs'
		'rootcopy'
		'less'
		'jade'
		'coffee'
		#'uglify'
		'copy'
	], build, (err) ->
		if err
			log 'build error!', err, true
		else
			log 'build complete!'

task 'watch', 'watch and rebuild files when changed', ->
	invoke 'watch:less'
	invoke 'watch:jade'
	invoke 'watch:coffee'
	invoke 'watch:copy'

#
# individual build tasks
#

task 'build:builddirs', 'prepares build dir\'s structure', -> build 'builddir'
task 'build:jade', 'build jade files into html', -> build 'jade'
task 'build:less', 'build less files into css', -> build 'less'
task 'build:coffee', 'build coffeescript files into js', -> build 'coffee'
#task 'build:uglify', 'uglify/minify js files', -> build 'uglify'
task 'build:copy', 'copy necessary files to build dir', -> build 'copy'
task 'build:rootcopy', 'copy necessary files to build root dir', -> build 'rootcopy'

#
# individual watch tasks
#

task 'watch:jade', 'watch jade files for changes and rebuild', -> watch 'jade'
task 'watch:less', 'watch less files for changes and rebuild', -> watch 'less'
task 'watch:coffee', 'watch coffee files for changes and rebuild', -> watch 'coffee'
task 'watch:copy', 'watch for misc changes and copy to build dir', -> watch 'copy'

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
				async.each files[fileset], (file, cb) ->
					compile type, file, cb
				, fn
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

watch = (type) ->
	invoke 'build:'+type
	# fileset is deliberately separate from type here.
	fileset = if type is 'uglify' then 'coffee' else type
	for file in files[fileset]
		do (file) ->
			path = switch
				when type is 'less' then "src/less/#{file}.less"
				when type is 'jade' then "src/jade/#{file}.jade"
				when type is 'coffee' then "src/coffee/#{file}.coffee"
				when type is 'copy' then "src/#{file}"
				when type is 'rootcopy' then "src/buildroot/#{file}"
			fs.watchFile path, (curr, prev) ->
				if +curr.mtime isnt +prev.mtime
					compile type, file

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
