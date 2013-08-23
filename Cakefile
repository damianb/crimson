{spawn, exec} = require 'child_process'
fs = require 'fs'
path = require 'path'
util = require 'util'
mkdirp = require 'mkdirp'
async = require 'async'

# ANSI Terminal Colors
bold = '\x1b[0;1m'
green = '\x1b[0;32m'
reset = '\x1b[0m'
red = '\x1b[0;31m'

# options for our various tools
jadeOpts = '-P'
coffeeOpts = '-b'
uglifyOpts = '-mc'
lessOpts = '--no-ie-compat -x'

# files to build/watch, etc.
files =
	builddir: [
		'assets/css'
		'assets/img'
		'assets/js'
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

task 'build', 'build all - less, jade, coffeescript', ->
	async.eachSeries [
		'builddir'
		'rootcopy'
		'less'
		'jade'
		#'uglycoffee'
		'coffee'
		'copy'
	], build, (err) ->
		if err
			log 'build error!', err, true
		else
			log 'build complete!'

task 'watch', 'watch and rebuild files when changed', ->
	invoke 'watch:less'
	invoke 'watch:jade'
	#invoke 'watch:uglycoffee'
	invoke 'watch:coffee'
	invoke 'watch:copy'

# individual build tasks
task 'build:builddir', 'prepares build directory by creating needed structure', -> build 'builddir'
task 'build:jade', 'build jade files into html', -> build 'jade'
task 'build:less', 'build less files into css', -> build 'less'
task 'build:coffee', 'build coffeescript files into js', -> build 'coffee'
task 'build:uglify', 'uglify/minify js files', -> build 'uglify'
task 'build:uglycoffee', 'build coffescript files & minify', -> build 'uglycoffee'
task 'build:copy', 'copy necessary files to build dir', -> build 'copy'
task 'build:rootcopy', 'copy necessary files to build root dir', -> build 'rootcopy'

# individual watch tasks
task 'watch:jade', 'watch jade files for changes and rebuild', -> watch 'jade'
task 'watch:less', 'watch less files for changes and rebuild', -> watch 'less'
task 'watch:coffee', 'watch coffee files for changes and rebuild', -> watch 'coffee'
task 'watch:uglify', 'watch js files for changes and compress', -> watch 'uglify'
task 'watch:uglycoffee', 'watch less files for changes and rebuild', -> watch 'uglycoffee'
task 'watch:copy', 'watch for misc changes and copy to build dir', -> watch 'copy'

build = (type, fn) ->
	fileset = switch
		when type is 'uglify' then 'coffee'
		when type is 'uglycoffee' then 'coffee'
		else type

	async.each files[fileset], (file, cb) ->
		compile type, file, cb
	, (err) ->
		fn err

	#for file in files[fileset]
	#	compile type, file, (err) ->
	#		if err then fn err
	#fn null

watch = (type) ->
	invoke 'build:'+type
	fileset = switch
		when type is 'uglify' then 'coffee'
		when type is 'uglycoffee' then 'coffee'
		else type
	for file in files[fileset] then do ->
		_file = file
		path = switch
			when type is 'less' then "src/less/#{_file}.less"
			when type is 'jade' then "src/jade/#{_file}.jade"
			when type is 'coffee' then "src/coffee/#{_file}.coffee"
			when type is 'uglify' then "build/assets/js/#{_file}.js"
			when type is 'uglycoffee' then "src/coffee/#{_file}.coffee"
			when type is 'copy' then "src/#{_file}"
			when type is 'rootcopy' then "src/buildroot/#{_file}"
		fs.watchFile path, (curr, prev) ->
			if +curr.mtime isnt +prev.mtime
				compile type,_file

compile = (type, file, fn) ->
	if type is 'builddir'
		mkdirp path.normalize('build/' + file), (err) ->
			if err
				log "#{type}: failed to create directory #{file}", err, true
			else
				log "#{type}: created directory #{file} successfully"
			fn? err
	else
		cmdLine = switch
			when type is 'less' then "lessc #{lessOpts} src/less/#{file}.less build/assets/css/#{file}.css"
			when type is 'jade' then "jade #{jadeOpts} < src/jade/#{file}.jade > build/#{file}.html"
			when type is 'coffee' then "coffee #{coffeeOpts} -cs < src/coffee/#{file}.coffee > build/assets/js/crimson.#{file}.js"
			when type is 'uglify' then "uglifyjs #{uglifyOpts} < build/assets/js/#{file}.js > build/assets/js/#{file}.min.js"
			when type is 'uglycoffee' then "coffee #{coffeeOpts} -cs < src/coffee/#{file}.coffee | uglifyjs #{uglifyOpts} > build/assets/js/#{file}.min.js"
			when type is 'copy' and process.platform.match(/^win/) then "copy /Y #{path.normalize('src/' + file)} #{path.normalize('build/assets/' + file)}"
			when type is 'copy' and !process.platform.match(/^win/) then "cp -u src/#{file} build/assets/#{file}"
			when type is 'rootcopy' and process.platform.match(/^win/) then "copy /Y #{path.normalize('src/buildroot/' + file)} #{path.normalize('build/' + file)}"
			when type is 'rootcopy' and !process.platform.match(/^win/) then "cp -u src/buildroot/#{file} build/#{file}"
			else throw new Error 'unknown compile type'
		exec cmdLine, (err, stdout, stderr) ->
			if err
				log "#{type}: failed to compile #{file}; #{err}", stderr, true
			else
				log "#{type}: compiled #{file} successfully"
			fn? err

log = (message, explanation, isError = false) ->
	if isError
		message = "#{red} err: #{message}#{reset}"
	else
		message = green + message.trim() + reset
	util.log message + ' ' + (explanation or '')

