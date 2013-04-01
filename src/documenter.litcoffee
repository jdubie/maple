Documenter
==========

Require dependencies

    path  = require 'path'
    docco = require 'docco'
    debug = require 'debug'
    h     = require './helper'

    debug = debug('maple/documenter')

    module.exports = class Documenter
      constructor: (@dir, @watcher) ->
        @include = /.*\.(lit)?coffee$/
        @exclude = /(?:node_modules|test_src)/ # TODO document src in future

        @documentAll()

      documentAll: (callback) =>
        h.findFiles {@dir, @validFile}, (err, files) =>
          files = files.map (file) => @relPath(file)
          debug 'files', files
          @files = files
          args = files
          docco.document({
            args
            output: 'docs/src'
            template: path.join(__dirname, '..', 'views', 'linear.jst')
          })

      validFile: (file) =>
        return false if file.match(@exclude)
        return true if file.match(@include)
        false

      relPath: (file) =>
        file.replace(@dir + '/', '')
