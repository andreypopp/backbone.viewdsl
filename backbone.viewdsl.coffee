define (require) ->

  $ = require 'jquery'
  Backbone = require 'backbone'
  rsvp = require 'rsvp'

  toArray = (o) ->
    Array::slice.call(o)

  getByPath = (o, p) ->
    if p.trim().length == 0
      return o
    for n in p.split('.')
      o = o[n]
      break if o == undefined
    o

  getBySpec = (spec) ->
    # TODO: implement AMD loading
    promise getByPath(window, spec)

  promise = (value) ->
    p = new rsvp.Promise()
    p.resolve(value)
    p

  promiseRequire = (moduleName) ->
    p = new rsvp.Promise()
    require moduleName, (module) -> p.resolve(module)
    p

  processNode = (context, node) ->
    processAttributes(context, node)
      .then (pragmas) ->
        if pragmas.remove and node.parentNode
          node.parentNode.removeChild(node)
        # TODO: interpolate TextNodes
        processNode(context, n) for n in toArray(node.childNodes)
        node

  processAttributes = (context, node) ->
    if node.attributes?.if
      attr = context[node.attributes.if.value]
      show = if $.isFunction(attr) then attr() else attr
      return promise {remove: true} unless show

    if node.attributes?.view
      getBySpec(node.attributes.view.value)
        .then (viewCls) ->
          # TODO: process more parameters, like class and so on
          view = new viewCls(el: node)
          view.render()
          context.addView(view) if context.addView
          return {remove: false}

    else
      promise {remove: false}

  class View extends Backbone.View

    @from: (template, options) ->
      node = $(template)
      node = if node.length == 1
        node[0]
      else
        throw new Error('templates only of single element are allowed')
      view = new this(el: node)
      processNode(view, node).then ->
        view.render()
        view

    constructor: ->
      super
      this.views = []

    processDOM: (template) ->
      # TODO: allow multiple DOM elements
      node = $(template)[0]
      processNode(this, node)

    renderDOM: (template) ->
      this.processDOM(template).then (node) =>
        this.$el.append(node)
        this

    addView: (view) ->
      this.views.push(view)

    remove: ->
      super
      for view in this.views
        view.remove()

  {View}
