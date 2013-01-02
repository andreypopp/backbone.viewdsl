define (require) ->

  $ = require 'jquery'
  Backbone = require 'backbone'
  rsvp = require 'rsvp'

  rsvp.Promise::end = ->
    this.then undefined, (e) -> throw e

  toArray = (o) ->
    Array::slice.call(o)

  getByPath = (o, p) ->
    if p.trim().length == 0
      return [o, window]
    for n in p.split('.')
      ctx = o
      o = ctx[n]
      break if o == undefined
    [o, ctx]

  getBySpec = (spec) ->
    # TODO: implement AMD loading
    promise getByPath(window, spec)[0]

  promise = (value) ->
    p = new rsvp.Promise()
    p.resolve(value)
    p

  promiseRequire = (moduleName) ->
    p = new rsvp.Promise()
    require moduleName, (module) -> p.resolve(module)
    p

  replaceChild = (node, old, news) ->
    for n in news
      if typeof n.cloneNode == 'function'
        node.insertBefore(n, old)
      else if typeof n.item == 'function' and n.length or n.jquery
        for nn in n
          node.insertBefore(nn, old)
      else
        n = document.createTextNode(String(n))
        node.insertBefore(n, old)
    node.removeChild(old)
    node

  textNodeSplitRe = /({{)|(}})/

  processNode = (context, node) ->
    processAttributes(context, node)
      .then (pragmas) ->

        if pragmas.remove and node.parentNode
          node.parentNode.removeChild(node)

        if node.nodeType == 3
          replacements = processTextNode(context, node)
          if replacements
            replaceChild(node.parentNode, node, replacements)
          else
            node
        else
          # TODO: wait for child nodes to finish
          processNode(context, n) for n in toArray(node.childNodes)
          node

  processTextNode = (context, node) ->
    return unless textNodeSplitRe.test node.data
    data = node.data
    data = data.replace('{{', '{{\uF001')
    parts = data.split(textNodeSplitRe)
    parts = parts.filter (e) -> e and e != '{{' and e != '}}'
    for part in parts
      if part[0] == '\uF001'
        [attr, attrCtx] = getByPath(context, part.slice(1).trim())
        if $.isFunction(attr) then attr.call(attrCtx) else attr
      else
        part

  processAttributes = (context, node) ->
    if node.attributes?.if
      [attr, attrCtx] = getByPath(context, node.attributes.if.value)
      show = if $.isFunction(attr) then attr.call(attrCtx) else attr
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

  wrapTemplate = (template, requireSingleNode = false) ->
    nodes = $.parseHTML(template)
    if requireSingleNode and nodes.length != 1
      throw new Error('templates only of single element are allowed')
    if nodes.length > 1 or nodes[0].nodeType == 3
      fragment = document.createDocumentFragment()
      for node in nodes
        fragment.appendChild(node)
      fragment
    else
      nodes[0]

  class View extends Backbone.View

    @from: (template, options) ->
      node = wrapTemplate(template, true)
      view = new this(el: node)
      processNode(view, node).then ->
        view.render()
        view

    constructor: ->
      super
      this.views = []

    processDOM: (template) ->
      node = wrapTemplate(template)
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
