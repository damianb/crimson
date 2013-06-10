fs = require 'fs'
{spawn, exec} = require 'child_process'
util = require 'util'

# ANSI Terminal Colors
bold = '\x1b[0;1m'
green = '\x1b[0;32m'
reset = '\x1b[0m'
red = '\x1b[0;31m'

jadeOpts = '-P'
coffeeOpts = '-b'
uglifyOpts = '-mc'
lessOpts = '--no-ie-compat -x'

files =
	jade:
		'src/index.jade': 'build/index.html'
	less:
		'src/crimson.less': 'build/assets/css/crimson.css'
	coffee:
		'src/crimson.coffee': 'build/assets/js/crimson.js'
	uglify:
		'build/assets/js/crimson.js': 'build/assets/js/crimson.min.js'
	uglycoffee:
		'src/crimson.coffee': 'build/assets/js/crimson.min.js'

task 'build', 'build all - less, jade, coffeescript', ->
	invoke 'build:less'
	invoke 'build:jade'
	invoke 'build:uglycoffee'
	#invoke 'build:coffee'

task 'watch', 'watch and rebuild files when changed', ->
	invoke 'watch:less'
	invoke 'watch:jade'
	invoke 'watch:uglycoffee'
	#invoke 'watch:coffee'

task 'build:jade', 'build jade files into html', ->
	for file, dest of files.jade
		compileJade file,dest

task 'build:less', 'build less files into css', ->
	for file, dest of files.less
		compileLess file,dest

task 'build:coffee', 'build coffeescript files into js', ->
	for file, dest of files.coffee
		compileCoffee file,dest

task 'build:uglify', 'uglify/minify js files', ->
	for file, dest of files.uglify
		compileUglify file,dest

# warning: uglifyjs seems to be broken atm
task 'build:uglycoffee', 'uglify coffeescript files', ->
	for file, dest of files.uglycoffee
		compileUglyCoffee file,dest

task 'watch:jade', 'watch jade files for changes and rebuild', ->
	invoke 'build:jade'
	for file, dest of files.jade
		fs.watchFile file, (curr, prev) ->
			if +curr.mtime isnt +prev.mtime
				compileJade file,dest

task 'watch:less', 'watch less files for changes and rebuild', ->
	invoke 'build:less'
	for file, dest of files.less
		fs.watchFile file, (curr, prev) ->
			if +curr.mtime isnt +prev.mtime
				compileLess file,dest

task 'watch:coffee', 'watch coffee files for changes and rebuild', ->
	invoke 'build:coffee'
	for file, dest of files.coffee
		fs.watchFile file, (curr, prev) ->
			if +curr.mtime isnt +prev.mtime
				compileCoffee file,dest

task 'watch:uglify', 'watch js files for changes and compress', ->
	invoke 'build:uglify'
	for file, dest of files.uglify
		fs.watchFile file, (curr, prev) ->
			if +curr.mtime isnt +prev.mtime
				compileUglify file,dest

task 'watch:uglycoffee', 'watch less files for changes and rebuild', ->
	invoke 'build:uglycoffee'
	for file, dest of files.uglycoffee
		fs.watchFile file, (curr, prev) ->
			if +curr.mtime isnt +prev.mtime
				compileUglyCoffee file,dest


compileLess = (file, dest) ->
	exec "lessc #{lessOpts} #{file} #{dest}", (err, stdout, stderr) ->
		if err
			log 'lessc: ' + err, stderr, true
		else
			log "lessc: compiled #{file} successfully"

compileJade = (file, dest) ->
	exec "jade #{jadeOpts} < #{file} > #{dest}", (err, stdout, stderr) ->
		if err
			log 'jade: ' + err, stderr, true
		else
			log "jade: compiled #{file} successfully"

compileCoffee = (file, dest) ->
	exec "coffee #{coffeeOpts} -cs < #{file} > #{dest}", (err, stdout, stderr) ->
		if err
			log 'coffee: ' + err, stderr, true
		else
			log "coffee: compiled #{file} successfully"

compileUglify = (file, dest) ->
	exec "uglifyjs #{uglifyOpts} < #{file} > #{dest}", (err, stdout, stderr) ->
		if err
			log 'uglifyjs: ' + err, stderr, true
		else
			log "uglifyjs: compiled #{file} successfully"

compileUglyCoffee = (file, dest) ->
	exec "coffee #{coffeeOpts} -cs < #{file} | uglifyjs #{uglifyOpts} > #{dest}", (err, stdout, stderr) ->
		if err
			log 'uglycoffee: ' + err, stderr, true
		else
			log "uglycoffee: compiled #{file} successfully"


log = (message, explanation, isError = false) ->
	if isError
		message = "#{red} err: #{message}#{reset}"
	else
		message = green + message.trim() + reset
	util.log message + ' ' + (explanation or '')

