Compiler = require('../lib/compiler')
should = require('should')

describe 'Compiler', ->
  describe '#testName', ->
    it 'should work', ->
  describe '#getLibPath', ->
    #Compiler('..')
    #it 'should work for `src` file`', ->
    #  p = compiler.getLibPath('/home/user/maple/src/file.coffee')
    #  p.should.eql '/home/user/maple/lib/file.js'
    #it 'should work for `test_src` file`', ->
    #  p = compiler.getLibPath('/home/user/maple/test_src/file.coffee')
    #  p.should.eql '/home/user/maple/test_lib/file.js'
    #describe '@getLib', ->
    #  Compiler.getLib(

  describe '#validFile', ->
    it 'should work for .litcoffee files', ->
      c = new Compiler
      c.validFile('test.litcoffee').should.eql true
