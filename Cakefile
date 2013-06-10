fs = require 'fs'
{spawn, exec} = require 'child_process'
util = require 'util'

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
	jade: [
		'index'
	]
	less: [
		'crimson'
	]
	coffee: [
		'crimson'
		'client'
	]
	uglify: [
		'crimson'
		'client'
	]
	uglycoffee: [
		'crimson'
		'client'
	]

task 'build', 'build all - less, jade, coffeescript', ->
	invoke 'build:less'
	invoke 'build:jade'
	invoke 'build:uglycoffee'

task 'watch', 'watch and rebuild files when changed', ->
	invoke 'watch:less'
	invoke 'watch:jade'
	invoke 'watch:uglycoffee'

# individual build tasks
task 'build:jade', 'build jade files into html', -> build 'jade'
task 'build:less', 'build less files into css', -> build 'less'
task 'build:coffee', 'build coffeescript files into js', -> build 'coffee'
task 'build:uglify', 'uglify/minify js files', -> build 'uglify'
task 'build:uglycoffee', 'uglify coffeescript files', -> build 'uglycoffee'

# individual watch tasks
task 'watch:jade', 'watch jade files for changes and rebuild', -> watch 'jade'
task 'watch:less', 'watch less files for changes and rebuild', -> watch 'less'
task 'watch:coffee', 'watch coffee files for changes and rebuild', -> watch 'coffee'
task 'watch:uglify', 'watch js files for changes and compress', -> watch 'uglify'
task 'watch:uglycoffee', 'watch less files for changes and rebuild', -> watch 'uglycoffee'

build = (type) ->
	for file in files[type]
		compile type,file

watch = (type) ->
	invoke 'build:'+type
	for file in files[type]
		fs.watchFile file, (curr, prev) ->
			if +curr.mtime isnt +prev.mtime
				compile type,file

compile = (type, file) ->
	cmdLine = switch
		when type is 'less' then "lessc #{lessOpts} src/#{file}.less build/assets/css/#{file}.css"
		when type is 'jade' then "jade #{jadeOpts} < src/#{file}.jade > build/#{file}.html"
		when type is 'coffee' then "coffee #{coffeeOpts} -cs < src/#{file}.coffee > build/assets/js/#{file}.js"
		when type is 'uglify' then "uglifyjs #{uglifyOpts} < build/assets/js/#{file}.js > build/assets/js/#{file}.min.js"
		when type is 'uglycoffee' then "coffee #{coffeeOpts} -cs < src/#{file}.coffee | uglifyjs #{uglifyOpts} > build/assets/js/#{file}.min.js"
		else throw new Error 'unknown compile type'
	exec cmdLine, (err, stdout, stderr) ->
		if err
			log type + ': ' + err, stderr, true
		else
			log "#{type}: compiled #{file} successfully"

log = (message, explanation, isError = false) ->
	if isError
		message = "#{red} err: #{message}#{reset}"
	else
		message = green + message.trim() + reset
	util.log message + ' ' + (explanation or '')

