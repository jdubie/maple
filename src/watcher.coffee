events = require 'events'
watch  = require 'node-watch'

exports = module.exports = class Watcher extends events.EventEmitter
  constructor: (dir) ->
    watch dir, (filename) =>
      @emit('change', filename)
