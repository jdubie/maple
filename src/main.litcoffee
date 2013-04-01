    fs         = require 'fs'
    path       = require 'path'
    mocha      = require 'mocha'
    async      = require 'async'
    express    = require 'express'
    commander  = require 'commander'
    debug      = require 'debug'
    h          = require './helper'
    Watcher    = require './watcher'
    Tester     = require './tester'
    Compiler   = require './compiler'
    Documenter = require './documenter'

    debug = debug('maple/main')

    dir = process.argv[2] ? process.cwd()

    unless fs.existsSync(dir)
      console.error "Path does not exist: #{dir}"
      process.exit()

      #watcher  = new Watcher(dir)
      #compiler = new Compiler(dir, watcher)
      #tester   = new Tester(dir, watcher)

      #compiler.on('ready', tester.start)
      #compiler.start()

    documenter = new Documenter(dir)

Start HTTP server

    app = express()
    app.use express.static path.join(__dirname, '..', 'public')

    htmlForName = (name, callback) ->
      name = h.deserializePath(name)
      htmlFile = path.join('docs', name + '.html')
      fs.readFile(htmlFile, 'utf8', callback)

    app.get '/modules/:id', (req, res) ->
      name = req.params.id
      htmlForName name, (err, html) ->
        res.json(module: {name, html})

    app.get '/modules', (req, res) ->
      files = documenter.files.map(h.relName(dir))
      files = files.map(h.removeExt)
      files = files.map(h.serializePath)

      debug 'files', files

      async.map files, htmlForName, (err, htmls) ->
        modules = []
        for i in [0...files.length]
          html = htmls[i]
          name = files[i]
          modules.push {html, name}
        res.json({modules})

    app.listen(3000)

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
