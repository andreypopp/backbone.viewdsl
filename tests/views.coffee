define (require) ->

  {View} = require 'backbone.viewdsl'

  class LoadedView extends View
    className: 'loaded-view'

    render: ->
      this.$el.html('HI')

  {LoadedView}
