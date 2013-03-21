events      = require 'events'
path        = require 'path'
debug       = require 'debug'
findit      = require 'findit'
async       = require 'async'
mdeps       = require 'module-deps'
Mocha       = require 'mocha'
DefaultDict = require 'defaultdict'
Set         = require 'set'
h           = require './helper'

debug = debug('maple/tester')

exports = module.exports = class Tester extends events.EventEmitter
  constructor: (@dir, @include=/.*\/lib\/.*\.js$/, @exclude=/node_modules/) ->
    @deps = new DefaultDict(() -> new Set())

  start: =>
    async.series [

      # run test on all files
      @testAll

    #  # test files when they change
    #  @watchAll

    ]

  watchAll: (callback) ->

    # run tests as things change
    watch @dir, (file) ->
      return unless @validFile(file)
      async.series [
        @testDepedencies([file])
        @updateDependants([file])
      ], callback

  testAll: (callback) =>
    @findSourceFiles (files) =>
      async.parallel [
        @updateDependants(files)
        @testFiles(files)
      ], callback

  updateDependants: (files) =>
    (callback) =>
      async.map(files, @fileDependants, callback)

  fileDependants: (filename, callback) =>
    debug 'updateDependants', filename
    deps = mdeps(filename)
    deps.on 'data', (data) =>
      if @validFile(data.id)# and data.id isnt filename
        @addDependency(filename, data.id)
        #console.log h.relName({filename, @dir}), 'depends on', h.relName({filename: data.id, @dir})
    deps.on('close', callback)

  # a depends on b
  #
  # b changed so test and b and a
  addDependency: (a, b) ->
    @deps.get(b).add(a)

  testDepedencies: (files) ->
    (callback) ->

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

  event: (eventname, args...) ->
    debug "#{eventname}: #{args[0]}"
    @emit(eventname, args...)

  testFiles: (files) ->
    (callback) =>
      async.map(files, @testFile, callback)

  relName: (filename) ->
    h.relName({filename, @dir})

  testName: (filename) ->
    relName = @relName(filename)
    relName = relName.split(path.sep)
    path.join('test_lib', relName[2..]...)

  testFile: (file, callback) =>
    debug "testing #{@testName(file)}"

    mocha = new Mocha(reporter: 'base')

    mocha.addFile(file)
    runner = mocha.run()
    runner.on 'pass', (test) =>
      @event 'pass', test
    runner.on 'fail', (test, err) =>
      @event 'fail', test, err
    runner.on('end', callback)

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
