Tester = require('../lib/tester')

describe 'Tester', ->
  describe '#testName', ->
    it 'should work', ->

  describe '#nameFromTest', ->
    it 'should work in simple case', ->
      tester = new Tester
      tester.nameFromTest('test/main.js').should.eql 'main'
    it 'should work as root dir', ->
      tester = new Tester
      tester.nameFromTest('/test/main.js').should.eql 'main'
    it 'should work with nested directories', ->
      tester = new Tester
      tester.nameFromTest('test/dir/main.js').should.eql 'dir/main'

