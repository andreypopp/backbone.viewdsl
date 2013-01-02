define (require) ->

  {View} = require 'backbone.viewdsl'

  describe 'Array', ->
    describe '#indexOf()', ->
      it 'should return -1 when the value is not present', ->
        [1,2,3].indexOf(5).should.equal(-1)
        [1,2,3].indexOf(0).should.equal(-1)
