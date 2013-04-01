helper
======

    path   = require 'path'
    findit = require 'findit'

TODO: make this something that can't appear in filenames

    SERIALIZE = '-' #

    exports.relName = (dir) ->
      (file) ->
        file.replace(dir, '')

TODO: turn this type of comment into unit test
lambda: `src/bar.coffee` -> `src/bar`

    exports.removeExt = (file) ->
      file.split('.')[0]

lambda: `src/bar` -> `src-bar`

    exports.serializePath = (file) ->
      file.replace(path.sep, SERIALIZE)

    exports.deserializePath = (file) ->
      file.replace(SERIALIZE, path.sep)

    exports.findFiles = ({dir, validFile}, callback) ->
      console.log 'findFiles', dir
      files = []
      finder = findit.find(dir)
      finder.on 'file', (file, stat) ->
        if validFile(file)
          files.push(file)
      finder.on 'end', ->
        callback(null, files)
