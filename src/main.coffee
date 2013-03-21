fs        = require 'fs'
path      = require 'path'
mocha     = require 'mocha'
express   = require 'express'
commander = require 'commander'
debug     = require 'debug'
Tester    = require './tester'
Compiler  = require './compiler'

debug = debug('main')

dir = process.argv[2] ? process.cwd()

unless fs.existsSync(dir)
  console.error "Path does not exist: #{dir}"
  process.exit()

compiler = new Compiler(dir)
tester   = new Tester(dir)

compiler.on('ready', tester.start)
compiler.start()

#
#app = express()
#app.use express.static path.join(__dirname, 'public')
#
#app.get '/tests', (req, res, next) ->
#
#  # stream events
#  streamer = new Streamer(res)
#watcher.on 'change', (event, filename) ->
#  console.log 'wewer'
#    results = test(event, filename)
#    results.on '
#    streamer.write(message)
#
#  watcher.on 'error', ->
#    streamer.close()
#
#app.listen(3002)
#
#class Streamer
#  constructor: (@response) ->
#    @response.header('Content-Type', 'text/event-stream')
#    @response.header('Cache-Control', 'no-cache')
#    @response.header('Connection', 'keep-alive')
#
#  write: (message) ->
#    @response.write("data: #{JSON.stringify(message)}\n")
#
#  close: () ->
#    @response.write("data: #{JSON.stringify(state: 'done')}\n")
#    @response.end()
