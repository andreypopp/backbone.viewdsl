define (require) ->

  {View} = require 'backbone.viewdsl'

  class LoadedView extends View

    render: ->
      this.$el.html('HI')

  {LoadedView}
