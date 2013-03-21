fs           = require 'fs'
events       = require 'events'
path         = require 'path'
mkdirp       = require 'mkdirp'
watch        = require 'node-watch'
CoffeeScript = require 'coffee-script'
debug        = require 'debug'
findit       = require 'findit'
_            = require 'underscore'

debug = debug('compiler')

exports = module.exports = class Compiler extends events.EventEmitter
  constructor: (@dir, @include=/.*\.coffee$/, @exclude=/node_modules/) ->

    # create `lib` directory
    mkdirp.sync(path.join(@dir, 'lib'))

    # create `test_lib` directory if `test_src` exists
    if path.existsSync(path.join(@dir, 'test_src'))
      mkdirp.sync(path.join(@dir, 'test_lib'))

  event: (eventname, args...) ->
    debug("#{eventname}: #{args.join(' ')}")
    @emit(eventname, args)

  start: ->
    # compile everything in beginning
    @compileAll =>
      @event('ready')

    # watch everything
    watch(@dir, @compile)

  compileAll: (callback) ->
    @findSourceFiles (err, files) =>
      files.forEach(@compile)
      callback?()

  validFile: (file) ->
    return false if file.match(@exclude)
    return true if file.match(@include)
    false

  compile: (file) =>

    # i.e. correct type an not in node_modules
    return unless @validFile(file)

    if fs.existsSync(file)
      @event('compiled', @relPath(file))
      coffee = fs.readFileSync(file, 'utf8')
      js = CoffeeScript.compile(coffee)
      dst = @getLibPath(file)
      mkdirp.sync(path.dirname(dst))
      fs.writeFileSync(dst, js)

  relPath: (file) ->
    file.replace(@dir, '')

  getLibPath: (file) ->
    relPath = file.split(@dir)[1]
    srcPath = relPath.split(path.sep)[2..].join(path.sep)
    dstPath = path.join(@dir, 'lib', srcPath)
    path.join(path.dirname(dstPath), path.basename(dstPath, '.coffee') + '.js')

  findSourceFiles: (callback) ->
    files = []
    finder = findit.find(@dir)
    finder.on 'file', (file, stat) ->
      files.push(file)
    finder.on 'end', ->
      callback(null, files)
