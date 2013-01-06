((root, factory) ->
  if typeof define == 'function' and define.amd
    define ['jquery', 'backbone', 'underscore'], (jQuery, Backbone, _) ->
      jQuery = jQuery or root.jQuery
      Backbone = Backbone or root.Backbone
      _ = _ or root._
      root.Backbone.ViewDSL = factory(jQuery, Backbone, _)
  else
    root.Backbone.ViewDSL = factory(root.jQuery, root.Backbone, root._)

) this, (jQuery, Backbone, _) ->

  class Promise
    noop = ->

    resolve = (promise, value) ->
      promise.trigger 'promise:resolved', detail: value
      promise.isResolved = true
      promise.resolvedValue = value

    reject = (promise, value) ->
      promise.trigger 'promise:failed', detail: value
      promise.isRejected = true
      promise.rejectedValue = value

    invokeCallback = (type, promise, callback, event) ->
      hasCallback = typeof callback == 'function'

      if hasCallback
        try
          value = callback(event.detail)
          succeeded = true
        catch e
          throw e if promise.isDone
          failed = true
          error = e
      else
        value = event.detail
        succeeded = true

      if value and typeof value.then == 'function'
        value.then(
          ((value) -> promise.resolve(value)),
          ((value) -> promise.reject(value)))
      else if hasCallback and succeeded
        promise.resolve(value)
      else if failed
        promise.reject(error)
      else
        promise[type](value)

    constructor: ->
      this.on 'promise:resolved', (e) =>
        this.trigger 'success', detail: e.detail
      this.on 'promise:failed', (e) =>
        this.trigger 'error', detail: event.detail
      this.isDone = false

    then: (done, fail) ->
      thenPromise = new Promise()
      if this.isResolved
        invokeCallback('resolve', thenPromise, done, detail: this.resolvedValue)
      if this.isRejected
        invokeCallback('reject', thenPromise, fail, detail: this.rejectedValue)
      this.on 'promise:resolved', (event) ->
        invokeCallback('resolve', thenPromise, done, event)
      this.on 'promise:failed', (event) ->
        invokeCallback('reject', thenPromise, fail, event)
      thenPromise

    resolve: (value) ->
      resolve this, value
      this.resolve = noop
      this.reject = noop

    reject: (value) ->
      reject this, value
      this.resolve = noop
      this.reject = noop

    done: ->
      this.isDone = true

  _.extend(Promise.prototype, Backbone.Events)


  toArray = (o) ->
    Array::slice.call(o)

  getByPath = (o, p, callIfMethod = false) ->
    if p.trim().length == 0
      return [o, window]
    for n in p.split('.')
      ctx = o
      o = ctx[n]
      break if o == undefined
    if callIfMethod and jQuery.isFunction(o)
      o = o.call(ctx)
    {attr: o, attrCtx: ctx}

  getBySpec = (spec, context = window) ->
    if /:/.test spec
      [module, path] = spec.split(':', 2)
      promiseRequire(module).then (module) -> getByPath(module, path).attr
    else if spec and spec[0] == '@'
      promise getByPath(context, spec.slice(1)).attr
    else
      promise getByPath(window, spec).attr

  promise = (value) ->
    p = new Promise()
    p.resolve(value)
    p

  join = (promises) ->
    p = new Promise()
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
    p = new Promise()
    require [moduleName], (module) -> p.resolve(module)
    p

  hypensToCamelCase = (o) ->
    o.replace /-([a-z])/g, (g) -> g[1].toUpperCase()

  replaceChild = (o, ns...) ->
    p = o.parentNode
    for n in ns
      if typeof n.cloneNode == 'function'
        p.insertBefore(n, o)
      else if typeof n.item == 'function' and n.length or n.jquery
        p.insertBefore(m, o) for m in n
      else
        p.insertBefore(document.createTextNode(String(n)), o)
    p.removeChild(o)
    ns

  render = (context, node, overlays...) ->
    synContext = makeContext(context, overlays...)
    process(synContext, node).then (result) ->
      for prop of synContext when synContext.hasOwnProperty(prop)
        context[prop] = synContext[prop]
      result

  process = (context, node) ->
    processAttributes(context, node).then (pragmas) ->
        if pragmas.remove and node.parentNode
          node.parentNode.removeChild(node)
          promise
        else
          processNode(context, node)

  processNode = (context, node) ->
    if node.nodeType == 3
      nodes = processTextNode(context, node)
      node = replaceChild(node, nodes...) if nodes
      promise node
    else if node.tagName == 'VIEW'
      if not node.attributes.name
        throw new Error('<view> element should have a name attribute')
      spec = node.attributes.name.value
      node.removeAttribute('name')
      {viewParams, viewId} = consumeViewParams(context, node)
      instantiateView(context, spec, viewParams, viewId).then (view) ->
        replaceChild(node, view.el)
    else
      join(process(context, n) for n in toArray(node.childNodes)).then -> node

  textNodeSplitRe = /({{)|(}})/

  processTextNode = (context, node) ->
    return unless textNodeSplitRe.test node.data
    data = node.data
    data = data.replace(/{{/g, '{{\uF001')
    parts = data.split(textNodeSplitRe)
    parts = parts.filter (e) -> e and e != '{{' and e != '}}'
    for part in parts
      if part[0] == '\uF001'
        getByPath(context, part.slice(1).trim(), true).attr or ''
      else
        part

  processAttributes = (context, node) ->
    if node.attributes?.if
      show = getByPath(context, node.attributes.if.value, true).attr
      return promise {remove: true} unless show

    if node.attributes?.view
      {viewParams, viewId} = consumeViewParams(context, node, 'view-')
      instantiateView(context, node.attributes.view.value, viewParams, viewId, node)
        .then -> {remove: false}
    else
      promise {remove: false}

  instantiateView = (context, spec, params, id, node) ->
    getBySpec(spec, context).then (viewCls) ->
        if viewCls == undefined
          throw new Error("can't find a view by '#{spec}' spec")
        view = if jQuery.isFunction(viewCls)
          params.el = node if node
          new viewCls(params)
        else
          viewCls.setElement(node) if node
          viewCls
        view.render()
        context.addView(view, id) if context.addView
        view

  consumeViewParams = (context, node, prefix) ->
    viewParams = {}
    viewId = undefined

    for a in node.attributes
      if not (prefix and a.name.slice(0, prefix.length) == prefix or not prefix)
        continue

      attrName = if prefix then a.name.slice(prefix.length) else a.name
      attrName = hypensToCamelCase(attrName)

      if attrName == 'id'
        viewId = a.value

      viewParams[attrName] = getByPath(context, a.value, true).attr or a.value

    {viewParams, viewId}

  wrapTemplate = (template, requireSingleNode = false) ->
    nodes = if template.jquery
      template.clone()
    else if typeof template.cloneNode == 'function'
      [template.cloneNode(true)]
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

  makeContext = (o, overlays...) ->
    Object.create(_.extend(Object.create(o), overlays...))

  class View extends Backbone.View

    template: undefined
    templateCached: undefined

    @from: (template, options) ->
      node = wrapTemplate(template, true)
      view = new this(el: node)
      render(view, node).then ->
        view.render()
        view

    constructor: ->
      super
      this.views = []

    renderDOM: (template, localContext) ->
      node = wrapTemplate(template)
      render(this, node, localContext).then (node) =>
        this.$el.append(node)
        this

    addView: (view, viewId) ->
      this.views.push(view)
      this[viewId] = view if viewId

    remove: ->
      super
      for view in this.views
        view.remove()

    render: (localContext) ->
      return unless this.template
      if this.hasOwnProperty('template')
        this.renderDOM(this.template, localContext)
      else
        if this.constructor::templateCached == undefined
          this.constructor::templateCached = wrapTemplate(this.constructor::template)
        this.renderDOM(this.constructor::templateCached, localContext)

  {View}
