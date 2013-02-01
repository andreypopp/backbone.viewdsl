((root, factory) ->
  if typeof define == 'function' and define.amd
    define ['jquery', 'backbone', 'underscore'], (jQuery, Backbone, _) ->
      root.Backbone.ViewDSL = factory(jQuery, Backbone, _)
  else
    root.Backbone.ViewDSL = factory(root.jQuery, root.Backbone, root._)
) this, (jQuery, Backbone, _) ->

  # Minimal promise implementation
  #
  # Promise.resolve() and Promise.reject() methods execute callbacks
  # immediatelly if a result is already available. This is done mostly because
  # of performance reasons and to minimize possible UI flicks.
  #
  # To prevent uncatched and unlogged exception it is always useful to call
  # Promise.done() method at the end of the chain.
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
      throw this.rejectedValue if this.rejectedValue

  _.extend(Promise.prototype, Backbone.Events)

  isPromise = (o) ->
    typeof o.then == 'function'

  promise = (value) ->
    return value if typeof value?.then == 'function'
    p = new Promise()
    p.resolve(value)
    p

  # Join several `promises` into one which resolves only when all `promises` are
  # resolved or fail fast.
  join = (promises) ->
    p = new Promise()
    results = []
    if promises.length > 0
      resultsToGo = promises.length
      for pr, idx in promises
        do (pr, idx) =>
          pr = promise(pr) if not isPromise(pr)
          success = (result) ->
            results[idx] = result
            resultsToGo = resultsToGo - 1
            if resultsToGo == 0
              p.resolve(results)
          fail = (reason) ->
            p.reject(reason)
          pr.then success, fail
    else
      p.resolve(results)
    p

  # Promise-based version of AMD require() call.
  promiseRequire = (moduleName) ->
    p = new Promise()
    require [moduleName], (module) -> p.resolve(module)
    p

  toArray = (o) ->
    Array::slice.call(o)

  # Get attribute from `o` object by dotted path `p`
  #
  # If `callIfMethod` argument is true and path points to a function then call
  # it preserving right context and use returned value as a result
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

  # Resolve spec
  #
  # Specs can be:
  # * `some/module:some.obj` resolves `some.obj` against `some/module` module
  # * `some.obj` resolves `some.obj` against `window`
  # * `@some.obj` resolves `some.obj` against `context` argument
  getBySpec = (spec, context = window) ->
    if /:/.test spec
      [module, path] = spec.split(':', 2)
      promiseRequire(module).then (module) -> getByPath(module, path).attr
    else if spec and spec[0] == '@'
      promise getByPath(context, spec.slice(1)).attr
    else
      promise getByPath(window, spec).attr

  hypensToCamelCase = (o) ->
    o.replace /-([a-z])/g, (g) -> g[1].toUpperCase()

  insertBefore = (o, n) ->
    p = o.parentNode
    if typeof n.cloneNode == 'function'
      p.insertBefore(n, o)
    else if typeof n.item == 'function' and n.length or n.jquery
      p.insertBefore(m, o) for m in n
    else if _.isArray(n)
      insertBefore(o, m) for m in n
    else
      p.insertBefore(document.createTextNode(String(n)), o)

  # Replace `o` DOM node with a list `ns` of DOM nodes
  replaceChild = (o, ns...) ->
    if not o.parentNode
      if ns.length == 1
        return ns[0]
      else
        return wrapInFragment(ns)

    insertBefore(o, n) for n in ns

    o.parentNode.removeChild(o)
    ns

  # Prepare `template` to be processed
  #
  # Argument `template` can be a DOM node, a jQuery element or just a string
  # with HTML markup. If `requireSingleNode` is true then it's required from
  # `template` to represent just a single DOM node.
  wrapTemplate = (template, requireSingleNode = false) ->
    nodes = if template.jquery
      template.clone()
    else if typeof template.cloneNode == 'function'
      [template.cloneNode(true)]
    else
      jQuery.parseHTML(template)

    if requireSingleNode and nodes.length != 1
      throw new Error('templates only of single element are allowed')
    if nodes.length > 1 or nodes[0].nodeType == Node.TEXT_NODE
      wrapInFragment(nodes)
    else
      nodes[0]

  wrapInFragment = (nodes) ->
    fragment = document.createDocumentFragment()
    fragment.appendChild(node) for node in nodes
    fragment

  # Render `node` in some context.
  #
  # Rendering context builds up from a `localContext`, `context` and a
  # `parentContext`. `context` is the "main" context here, it provides data for
  # rendering `node` and all writes ends-up there. `localContext` works like an
  # overlay for `context` — you can submit additional and temporal values there.
  # `parentContext` is a kind of a fallback for lookups which are missed from
  # `context`.
  #
  # If `forceClone` is false then `node` isn't cloned.
  render = (node, localContext, context, parentContext, forceClone = true) ->
    if not (typeof node.cloneNode == 'function')
      node = wrapTemplate(node)
    else if forceClone
      node = node.cloneNode(true)

    currentContext = if parentContext then Object.create(parentContext) else {}
    currentContext = _.extend(currentContext, context) if context
    currentContext = _.extend(Object.create(currentContext), localContext) if localContext
    currentContext = Object.create(currentContext)

    process(currentContext, node).then (result) ->
      for prop of currentContext when currentContext.hasOwnProperty(prop)
        context[prop] = currentContext[prop]
      result

  # The same as render, but only for those nodes are already in DOM.
  #
  # This can be useful if you want to define your app in original HTML.
  renderInPlace = (node, localContext, context, parentContext) ->
    render(node, localContext, context, parentContext, false)

  # Process single `node`.
  process = (context, node) ->

    # check if we already seen the node
    if node.seen
      return promise(node)
    else
      node.seen = true

    processAttributes(context, node).then (pragmas) ->
      if pragmas.skip
        promise()

      else if pragmas.remove
        node.parentNode.removeChild(node)
        promise()

      else
        processNode(context, node)

  # Process `node` content.
  processNode = (context, node) ->

    # text node interpolation
    if node.nodeType == Node.TEXT_NODE
      processTextNode(context, node).then (nodes) ->
        node = replaceChild(node, nodes...) if nodes
        node

    # view instantiation view <view /> tag
    else if node.tagName == 'VIEW'
      if not node.attributes.name
        throw new Error('<view> element should have a name attribute')
      spec = node.attributes.name.value
      node.removeAttribute('name')
      instantiateView(context: context, spec: spec, node: node, useNode: false)
        .then (view) -> 
          p = node.parentNode
          nodes = replaceChild(node, view.el)
          nodes

    # recursively traverse children
    else
      join(process(context, n) for n in toArray(node.childNodes)).then -> node

  textNodeSplitRe = /({{)|(}})/

  # Process `TextNode`'s content to interpolate values.
  processTextNode = (context, node) ->
    return promise() unless textNodeSplitRe.test node.data

    data = node.data
    data = data.replace(/{{/g, '{{\uF001')

    parts = data.split(textNodeSplitRe)
    parts = parts.filter (e) -> e and e != '{{' and e != '}}'

    nodes = for part in parts
      if part[0] == '\uF001'
        getByPath(context, part.slice(1).trim(), true).attr or ''
      else
        part

    join(nodes)

  processAttrRe = /^attr-/

  # Process `node`'s attributes.
  processAttributes = (context, node) ->
    if node.nodeType != Node.ELEMENT_NODE
      return promise {}

    # conditional exclusion
    if node.attributes?.if
      show = getByPath(context, node.attributes.if.value, true).attr
      node.removeAttribute('if')
      return promise {remove: true} unless show

    # DOM element references
    if node.attributes?['element-id']
      context[node.attributes?['element-id'].value] = $(node)
      node.removeAttribute('element-id')

    for attr in node.attributes when processAttrRe.test attr.name
      name = attr.name.substring(5)
      value = getByPath(context, attr.value, true).attr

      if _.isBoolean(value)
        node.setAttribute(name, '') if value
      else
        node.setAttribute(name, value)

      node.removeAttribute(attr.name)

    # view instantiation via view attribute
    if node.attributes?.view
      spec = node.attributes.view.value
      node.removeAttribute('view')
      instantiateView(context: context, spec: spec, node: node, useNode: true)
        .then (view) -> if view.parameterizable then {skip: true} else {}

    else
      promise {}

  # Instantiate view from `options`
  instantiateView = (options) ->
    getBySpec(options.spec, options.context).then (viewCls) ->
      if viewCls == undefined
        throw new Error("can't find a view by '#{options.spec}' spec")

      fromViewTag = options.node.tagName == 'VIEW'

      # read view params from node's attributes
      prefix = if fromViewTag then undefined else 'view-'
      {viewParams, viewId} = consumeViewParams(options.context, options.node, prefix)

      # create or init view
      view = if jQuery.isFunction(viewCls)
        viewParams.el = options.node if options.useNode
        new viewCls(viewParams)
      else
        viewCls.setElement(options.node) if options.useNode
        viewCls

      # set class on a view if view was instantiated from a <view> tag
      if fromViewTag and options.node.attributes['class']
        view.$el.addClass(options.node.attributes['class'].value)

      # notify view about being a part of a view hierarchy
      view.setParentContext(options.context) if view.setParentContext
      options.context.addView(view, viewId) if options.context.addView

      p = if view.parameterizable
        # if view is parameterizable we need to pass all DOM element inside
        # `node` to view's `render()` method so view can decide by its own what
        # to do next
        partial = $(options.node.removeChild(c) for c in toArray(options.node.childNodes))
        partial = wrapTemplate(partial)
        promise view.render(partial)
      else
        promise view.render()

      p.then -> view

  # Read view params from `node` in `context` using `prefix`
  consumeViewParams = (context, node, prefix) ->
    viewParams = {}
    viewId = undefined

    for a in toArray(node.attributes)
      if not (prefix and a.name.slice(0, prefix.length) == prefix or not prefix)
        continue

      attrName = if prefix then a.name.slice(prefix.length) else a.name
      attrName = hypensToCamelCase(attrName)

      if attrName == 'id'
        viewId = a.value
        node.removeAttribute(a.name)
        continue

      viewParams[attrName] = getByPath(context, a.value, true).attr or a.value

    {viewParams, viewId}

  # View class adapter to be used with `render()` method.
  class View extends Backbone.View

    template: undefined
    templateCached: undefined
    parameterizable: false

    @from: (template, localContext) ->
      node = wrapTemplate(template, true)
      view = new this(el: node)
      render(node, localContext, view, undefined, false).then ->
        view.render()
        view

    constructor: ->
      super
      this.views = []

    # Render `template` in a context of a view, optionally with `localContext`.
    renderTemplate: (template, localContext) ->
      render(template, localContext, this, this.parentContext)

    # Render `template` in a context of a view and append result to view's `el`.
    renderDOM: (template, localContext) ->
      this.renderTemplate(template, localContext).then (node) =>
        this.$el.append(node)
        this

    setParentContext: (parentContext) ->
      this.parentContext = parentContext

    addView: (view, viewId) ->
      this.views.push(view)
      this[viewId] = view if viewId

    # Default implementation of `render()` method which tries to render template
    # stored in `template` attribute of a view. If `template` is stored into
    # prototype then it caches it.
    render: (localContext) ->
      return unless this.template
      if this.hasOwnProperty('template')
        this.renderDOM(this.template, localContext)
      else
        if this.constructor::templateCached == undefined
          this.constructor::templateCached = wrapTemplate(this.constructor::template)
        this.renderDOM(this.constructor::templateCached, localContext)

    remove: ->
      super
      for view in this.views
        view.remove()

  class ParameterizableView extends View
    parameterizable: true

    render: (partial, localContext) ->
      if this.template
        localContext = _.extend({}, localContext, {partial: this.renderTemplate(partial)})
        super(localContext)
      else
        this.renderDOM(partial)

  {View, ParameterizableView, render, renderInPlace, wrapTemplate}
