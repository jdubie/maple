fs           = require 'fs'
events       = require 'events'
path         = require 'path'
mkdirp       = require 'mkdirp'
CoffeeScript = require 'coffee-script'
debug        = require 'debug'
findit       = require 'findit'
_            = require 'underscore'

debug = debug('maple/compiler')

exports = module.exports = class Compiler extends events.EventEmitter
  constructor: (@dir, @watcher, @include=/.*\.coffee$/, @exclude=/node_modules/) ->

  event: (eventname, args...) ->
    debug("#{eventname}: #{args.join(' ')}")
    @emit(eventname, args)

  start: ->
    # compile everything in beginning
    @compileAll =>
      @event('ready')

    # watch everything
    @watcher.on('change', @compile)

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
    dstPath = path.join(@dir, Compiler.getLib(relPath), srcPath)
    path.join(path.dirname(dstPath), path.basename(dstPath, '.coffee') + '.js')

  @getLib: (file) ->
    switch file.split(path.sep)[1]
      when 'src' then 'lib'
      when 'test_src' then 'test'
      else throw new Error("invalid folder: #{file}")

  findSourceFiles: (callback) ->
    files = []
    finder = findit.find(@dir)
    finder.on 'file', (file, stat) ->
      files.push(file)
    finder.on 'end', ->
      callback(null, files)
