Compiler
========

This module watches `\*.coffee` and `\*.litcoffee` files and compiles them

Require dependencies
--------------------

    fs           = require 'fs'
    events       = require 'events'
    path         = require 'path'
    cp           = require 'child_process'
    async        = require 'async'
    mkdirp       = require 'mkdirp'
    CoffeeScript = require 'coffee-script'
    debug        = require 'debug'
    findit       = require 'findit'
    _            = require 'underscore'

Debug to stdout

    debug = debug('maple/compiler')

class Compiler
--------------
*Events*:
- `ready`     all files compiled
- `compiled`  compiled file

    exports = module.exports = class Compiler extends events.EventEmitter

Initialized with a `@watcher` which emitts `change` events whenever something
changes in `@dir`. Also, will ignore files matching regex `@exclude` and
including filenames matching `@include`

      constructor: (@dir, @watcher,
        @include=/.*\.(lit)?coffee$/, @exclude=/node_modules/) ->



      event: (eventname, args...) ->
        debug("#{eventname}: #{args.join(' ')}")
        @emit(eventname, args)

compile everything in beginning

      start: ->
        @compileAll =>
          @event('ready')

watch everything

        @watcher.on('change', @compile)

      compileAll: (callback) ->
        @findSourceFiles (err, files) =>
          async.map(files, @compile, callback)

      validFile: (file) ->
        return false if file.match(@exclude)
        return true if file.match(@include)
        false

      compile: (file, callback) =>

        # i.e. correct type an not in node_modules
        return callback?() unless @validFile(file)

        if fs.existsSync(file)
          args = [
            '-o', 'lib'
            '-c', file
          ]
          coffee = cp.spawn './node_modules/.bin/coffee', args
          coffee.on 'exit', (exit) =>
            throw new Error("coffee -c exited non-zero: #{exit}") if exit isnt 0
            @event('compiled', @relPath(file))
            callback?()

          #coffee = fs.readFileSync(file, 'utf8')
          #js = CoffeeScript.compile(coffee)
          #fs.writeFileSync(dst, js)

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
