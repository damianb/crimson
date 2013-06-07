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
uglifyOpts = '-mce'
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

try
	which = require('which').sync
catch err
	if process.platform.match(/^win/)?
		console.log 'WARNING: the which module is required for windows\ntry: npm install which'
	which = null

task 'build', 'build less, coffeescript, jade files and uglify resulting js', ->
	invoke 'build:less'
	invoke 'build:jade'
	invoke 'build:coffee'


task 'build:jade', 'build jade files into html', ->
	for file, dest of files.jade
		exec "jade #{jadeOpts} < #{file} > #{dest}", (err, stdout, stderr) ->
			if err
				log 'jade: ' + err, stderr, true
			else
				log "jade: compiled #{file} successfully"

task 'build:less', 'build less files into css', ->
	for file, dest of files.less
		exec "lessc #{lessOpts} #{file} #{dest}", (err, stdout, stderr) ->
			if err
				log 'lessc: ' + err, stderr, true
			else
				log "lessc: compiled #{file} successfully"

task 'build:coffee', 'build coffeescript files into js', ->
	for file, dest of files.coffee
		exec "coffee #{coffeeOpts} -cs < #{file} > #{dest}", (err, stdout, stderr) ->
			if err
				log 'coffee: ' + err, stderr, true
			else
				log "coffee: compiled #{file} successfully"

task 'build:uglify', 'uglify/minify js files', ->
	for file, dest of files.uglify
		exec "uglifyjs #{uglifyOpts} < #{file} > #{dest}", (err, stdout, stderr) ->
			if err
				log 'coffee: ' + err, stderr, true
			else
				log "coffee: compiled #{file} successfully"

# warning: uglifyjs seems to be broken atm
task 'build:uglycoffee', 'uglify coffeescript files', ->
	for file, dest of files.uglycoffee
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
