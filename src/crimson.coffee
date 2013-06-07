#`$ = window.$`
os = require 'os'
$('#version').text "running node-webkit, powered by node #{process.version} #{os.platform()}"
