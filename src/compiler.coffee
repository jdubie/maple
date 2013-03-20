fs           = require 'fs'
path         = require 'path'
mkdirp       = require 'mkdirp'
CoffeeScript = require 'coffee-script'
debug        = require 'debug'
findit       = require 'findit'
_            = require 'underscore'

debug = debug('compiler')

exports = module.exports = class Compiler
  constructor: (@dir) ->

    # create lib dir
    mkdirp.sync(path.join(@dir, 'lib'))

    # find all coffee-script files
    @findSourceFiles (err, files) =>
      @files = files

      # TODO handle error
      files.forEach(@watchFile)

      # compile everything on start so in compiled state
      files.forEach(@compile)

      # listen for addition of new files
      # TODO generalize this beyond just src
      dirWatcher = fs.watch(path.join(@dir, 'src'))
      dirWatcher.on 'change', (event, filename) ->
        debug 'dirWatcher', event, filename

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
    #watcher.on 'change', (event, filename) ->
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
      console.log @files

  getLibPath: (file) ->
    relPath = file.split(@dir)[1]
    srcPath = relPath.split(path.sep)[2..].join(path.sep)
    dstPath = path.join(@dir, 'lib', srcPath)
    path.join(path.dirname(dstPath), path.basename(dstPath, '.coffee') + '.js')
