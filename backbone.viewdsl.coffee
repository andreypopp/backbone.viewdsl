((root, factory) ->
  if typeof define == 'function' and define.amd
    define ['jquery', 'rsvp', 'backbone', 'underscore'], (jQuery, RSVP, Backbone, _) ->
      jQuery = jQuery or root.jQuery
      RSVP = RSVP or root.RSVP
      Backbone = Backbone or root.Backbone
      _ = _ or root._
      root.Backbone.ViewDSL = factory(jQuery, RSVP, Backbone, _)
  else
    root.Backbone.ViewDSL = factory(root.jQuery, root.RSVP, root.Backbone, root._)

) this, (jQuery, RSVP, Backbone, _) ->

  RSVP.Promise::end = ->
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
    if /:/.test spec
      [module, path] = spec.split(':', 2)
      promiseRequire(module)
        .then (module) -> getByPath(module, path)[0]
    else
      promise getByPath(window, spec)[0]

  promise = (value) ->
    p = new RSVP.Promise()
    p.resolve(value)
    p

  join = (promises) ->
    p = new RSVP.Promise()
    results = []
    if promises.length > 0
      resultsToGo = promises.length
      for pr, idx in promises
        do (pr, idx) =>
          pr.then (result) ->
            results[idx] = result
            resultsToGo = resultsToGo - 1
            if resultsToGo == 0
              p.resolve(results)
    else
      p.resolve(results)
    p

  promiseRequire = (moduleName) ->
    p = new RSVP.Promise()
    require [moduleName], (module) -> p.resolve(module)
    p

  hypensToCamelCase = (o) ->
    o.replace /-([a-z])/g, (g) -> g[1].toUpperCase()

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
          return

        if node.nodeType == 3
          replacements = processTextNode(context, node)
          if replacements
            node = replaceChild(node.parentNode, node, replacements)
          return node

        join(processNode(context, n) for n in toArray(node.childNodes))
          .then -> node

  processTextNode = (context, node) ->
    return unless textNodeSplitRe.test node.data
    data = node.data
    data = data.replace(/{{/g, '{{\uF001')
    parts = data.split(textNodeSplitRe)
    parts = parts.filter (e) -> e and e != '{{' and e != '}}'
    for part in parts
      if part[0] == '\uF001'
        [attr, attrCtx] = getByPath(context, part.slice(1).trim())
        value = if jQuery.isFunction(attr) then attr.call(attrCtx) else attr
        value or ''
      else
        part

  processAttributes = (context, node) ->
    if node.attributes?.if
      [attr, attrCtx] = getByPath(context, node.attributes.if.value)
      show = if jQuery.isFunction(attr) then attr.call(attrCtx) else attr
      return promise {remove: true} unless show

    if node.attributes?.view
      getBySpec(node.attributes.view.value)
        .then (viewCls) ->
          viewParams = {}
          for attr in node.attributes when attr.name.slice(0, 5) == 'view-'
            attrName = hypensToCamelCase(attr.name.slice(5))
            attrValue = context[attr.value]
            [attrValue, attrCtx] = getByPath(context, attr.value)
            viewParams[attrName] = if jQuery.isFunction(attrValue)
              attrValue.call(attrCtx)
            else if attrValue == undefined
              attr.value
            else
              attrValue
          viewParams.el = node
          view = new viewCls(viewParams)
          view.render()
          context.addView(view) if context.addView
          return {remove: false}

    else
      promise {remove: false}

  wrapTemplate = (template, requireSingleNode = false) ->
    nodes = if template.jquery
      template.clone()
    else if typeof template.cloneNode == 'function'
      [template.cloneNode()]
    else
      jQuery.parseHTML(template)
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

    template: undefined

    @from: (template, options) ->
      node = wrapTemplate(template, true)
      view = new this(el: node)
      processNode(view, node).then ->
        view.render()
        view

    constructor: ->
      super
      this.views = []

    processDOM: (template, localContext) ->
      node = wrapTemplate(template)
      context = if localContext
        _.extend(Object.create(this), localContext)
      else
        this
      processNode(context, node)

    renderDOM: (template, localContext) ->
      this.processDOM(template, localContext).then (node) =>
        this.$el.append(node)
        this

    addView: (view) ->
      this.views.push(view)

    remove: ->
      super
      for view in this.views
        view.remove()

  {View}
