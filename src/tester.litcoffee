Tester
======

Runs

    events      = require 'events'
    path        = require 'path'
    cp          = require 'child_process'
    debug       = require 'debug'
    findit      = require 'findit'
    async       = require 'async'
    mdeps       = require 'module-deps'
    Mocha       = require 'mocha'
    DefaultDict = require 'defaultdict'
    Set         = require 'set'
    h           = require './helper'

    debug = debug('maple/tester')

class Tester
------------

# Events
- `pass`
- `fail`

    exports = module.exports = class Tester extends events.EventEmitter

      constructor: (@dir, @watcher, @include=/.*\/lib\/.*\.js$/, @exclude=/node_modules/) ->
        @deps = new DefaultDict(() -> new Set())

# start
- run test on all files
- test files when they change

      start: =>
        async.series [ @testAll, @watchAll ]

run tests as things change

      watchAll: (callback) =>
        @watcher.on 'change', (file) =>
          return unless @validFile(file)
          async.series [
            @testDepedencies(file)
            @updateDependants([file])
          ]

        callback()

      testAll: (callback) =>
        @findSourceFiles (files) =>
          async.series [
            @updateDependants(files)
            @testFiles(files)
          ], callback

      updateDependants: (files) =>
        (callback) =>
          debug 'updating Dependants'
          async.mapSeries(files, @fileDependants, callback)

      fileDependants: (filename, callback) =>
        deps = mdeps(filename)
        #deps.on('error', () ->) # TODO make sure these are in node_modules
        deps.on 'error', () ->
          callback()
        deps.on 'data', (data) =>
          if @validFile(data.id)# and data.id isnt filename
            @addDependency(filename, data.id)
            #console.log h.relName({filename, @dir}), 'depends on', h.relName({filename: data.id, @dir})
        deps.on('end', callback)

# addDependency
`a` depends on `b`
`b` changed so test and `b` and `a`

      addDependency: (a, b) ->
        @deps.get(b).add(a)

      testDepedencies: (file) =>
        (callback) =>
          values = @deps.get(file).values()
          @testFiles(values) (err) ->
            debug 'testFiles done'
            callback()

      testFiles: (files) =>
        (callback) =>
          async.map(files, @testFile, callback)

      testFile: (file, callback) =>
        file = @testName(file)
        debug "testing #{file}"

        args = [
          '--reporter', 'json-stream'
          file
        ]
        mocha = cp.spawn 'mocha', args
        mocha.stdout.on('data', @parseOut(file))
        mocha.on('exit', callback)

        # TODO get this working without child process

        #file = @testName(file)
        #debug "testing #{file}"

        #mocha = new Mocha(reporter: 'base')

        #mocha.addFile(file)
        #runner = mocha.run()
        #runner.on 'pass', (test) =>
        #  @event 'pass', test
        #runner.on 'fail', (test, err) =>
        #  @event 'fail', test, err
        #runner.on('end', callback)

        # END TODO

          # 
          # Initialize a `Runner` for the given `suite`.
          # 
          # Events:
          # 
          #   - `start`  execution started
          #   - `end`  execution complete
          #   - `suite`  (suite) test suite execution started
          #   - `suite end`  (suite) all tests (and sub-suites) have finished
          #   - `test`  (test) test execution started
          #   - `test end`  (test) test completed
          #   - `hook`  (hook) hook execution started
          #   - `hook end`  (hook) hook complete
          #   - `pass`  (test) test passed
          #   - `fail`  (test, err) test failed
          # 
          # @api public
          # 

# helpers

      findSourceFiles: (callback) ->
        files = []
        finder = findit.find(@dir)
        finder.on 'file', (file, stat) =>
          return unless @validFile(file)
          files.push(file)
        finder.on 'end', ->
          callback(files)


      validFile: (file) ->
        file = file.toString('utf8')
        return false if file.match(@exclude)
        return true if file.match(@include)
        false

This function both logs and formats and emits events for be consumed by browser

      event: (eventname, args...) =>
        switch eventname
          when 'ready' then debug 'ready'
          when 'pass'
            debug 'args[0]', args[0]
            fileExport = @exportFromResult(args[0])
            file = @fileFromTest(args[1])
            debug "#{eventname}: #{name}"
            @emit eventname, name
          when 'fail'
            # DO something different
          else
            debug "#{eventname}: #{args[0]}"
            #@emit(eventname, args...)

This file should emit events to be consumed by browser api

      parseOut: (file) =>
        (data) =>
          data = data.toString('utf8')
          msgs = data.split('\n')
          msgs = msgs.filter (msg) -> msg.length > 0
          msgs = msgs.map (msg) -> JSON.parse(msg)
          for msg in msgs
            @event(msg[0], msg[1], file) if msg[0] in ['pass', 'fail']

This function takes `'test/main.js' -> 'main'`
param `String` - `name`
return `String`

      nameFromTest: (name) ->
        name = name.split(path.sep)
        name = name.filter (elem) -> elem.length > 0 # remove leading /
        name = name[1..] # remove test
        name[name.length - 1] = path.basename(name[name.length - 1], '.js')
        name.join(path.sep)

This function 
param `Object`


      exportFromResult: () ->
        # TODO implement this

      relName: (filename) ->
        h.relName({filename, @dir})

      testName: (filename) ->
        relName = @relName(filename)
        relName = relName.split(path.sep)
        path.join('test', relName[2..]...)
