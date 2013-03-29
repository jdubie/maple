    findit = require 'findit'

    exports.relName = ({filename, dir}) ->
      filename.replace(dir, '')

    exports.findFiles = ({dir, validFile}, callback) ->
      console.log 'findFiles', dir
      files = []
      finder = findit.find(dir)
      finder.on 'file', (file, stat) ->
        if validFile(file)
          files.push(file)
      finder.on 'end', ->
        callback(null, files)
