define (require) ->

  $ = require 'jquery'
  Backbone = require 'backbone'
  rsvp = require 'rsvp'

  toArray = (o) ->
    Array::slice.call(o)

  getByPath = (o, p) ->
    for n in p.split('.')
      o = o[n]
      break if o == undefined
    o

  getBySpec = (spec) ->
    # TODO: implement AMD loading
    w getByPath(window, spec)

  domParamName2jsParamName = (paramName) ->
    throw 'not_implemented'

  cont = (func) ->
    ->
      deferred = w.defer()
      args = makeArray(arguments)
      args.splice 0, 0, (result, reason) ->
        if reason != undefined
          deferred.reject(reason)
        else
          deferred.resolve(result)
      func.apply(this, args)
      deferred.promise

  promiseRequire = cont (next, moduleName) ->
    require moduleName, (module) -> next module

  buildDOM = (context, template) ->
    node = document.createElement(template)
    processNode(context, node)

  processAttributes = (context, node) ->
    if node.attributes.view
      getBySpec(node.attributes.view.value)
        .then (viewCls) ->
          # TODO: process more parameters, like class and so on
          view = new viewCls(el: node)
          view.render()
          context.addView(view) if context.addView
          {lazy: view.lazy, remove: false}
    else
      w {lazy: false, remove: false}

  processNode = (context, node) ->
    processAttributes(context, node)
      .then ->

        # TODO: interpolate TextNodes

        # TODO: process <block> node
        # if node.tagName = 'BLOCK'
        #   processBlockNode(context, node)

        w.join(processNode(node, context) for node in toArray(node.childNodes))

  class View extends Backbone.View

    constructor: ->
      super
      this.views = []

    addView: (view) ->
      this.views.push(view)

    remove: ->
      super
      for view in this.views
        view.remove()

  {View}
