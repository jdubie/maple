events = require 'events'
path   = require 'path'
debug  = require 'debug'
findit = require 'findit'
async  = require 'async'
mdeps  = require 'module-deps'
Mocha  = require 'mocha'

debug = debug('maple/tester')

exports = module.exports = class Tester extends events.EventEmitter
  constructor: (@dir, @include=/.*\/lib\/.*\.js$/, @exclude=/node_modules/) ->

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
        #@updateDependants(files)
        @testFiles(files)
      ], callback

  updateDependants: (files) ->
    (callback) =>
      async.map(files, @fileDependants, callback)

  fileDependants: (file, callback) ->
    debug 'updateDependants', file
    deps = mdeps(file)
    deps.on 'data', (data) ->
      debug 'data', data.id, data.deps
    deps.on('close', callback)

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
    filename.replace(@dir, '')

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
