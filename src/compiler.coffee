fs           = require 'fs'
path         = require 'path'
mkdirp       = require 'mkdirp'
CoffeeScript = require 'coffee-script'
Set          = require 'set'
debug        = require 'debug'
findit       = require 'findit'
_            = require 'underscore'

debug = debug('compiler')

exports = module.exports = class Compiler
  constructor: (@dir) ->

    # create lib dir
    mkdirp.sync(path.join(@dir, 'lib'))

    # watchers
    @watchers = []

    # find all coffee-script files
    @compileAll()

    # listen for addition of new files
    # TODO generalize this beyond just src
    # TODO this doesn't work for adding recursive folders
    dirWatcher = fs.watch(path.join(@dir, 'src'))
    dirWatcher.on 'change', (event, filename) =>
      return unless event is 'rename'
      debug 'new file', event, filename
      @compileAll()

  compileAll: (callback) ->

    # free all old watchers
    watcher.close() for watcher in @watchers

    # initialize watched files to empty set
    @files = new Set()

    @findSourceFiles (err, files) =>
      @files.addAll(files)

      # watch each file
      files.forEach(@watchFile)

      # compile everything on start so in compiled state
      files.forEach(@compile)

  findSourceFiles: (callback) ->
    files = []
    finder = findit.find(@dir)
    finder.on 'file', (file, stat) ->
      # ignore node_modules
      return if file.match /node_modules/

      # watch coffee-script files
      if file.match /.*.coffee$/
        files.push(file)

    finder.on 'end', ->
      callback(null, files)

  watchFile: (file) =>
    watcher = fs.watch(file)
    @watchers.push(watcher) # remember watch so can close later
    watcher.on 'change', (event) =>
      return unless event is 'change'
      # TODO debounce events (3 change events fire for a vim save)
      @compile(file)

  compile: (file) =>
    debug 'compiling', file
    if fs.existsSync(file)
      coffee = fs.readFileSync(file, 'utf8')
      js = CoffeeScript.compile(coffee)
      dst = @getLibPath(file)
      mkdirp.sync(path.dirname(dst))
      fs.writeFileSync(dst, js)
    else
      @files = _(@files).filter (file) -> file isnt file

  getLibPath: (file) ->
    relPath = file.split(@dir)[1]
    srcPath = relPath.split(path.sep)[2..].join(path.sep)
    dstPath = path.join(@dir, 'lib', srcPath)
    path.join(path.dirname(dstPath), path.basename(dstPath, '.coffee') + '.js')
