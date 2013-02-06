((root, factory) ->
  if typeof define == 'function' and define.amd
    define ['jquery', 'backbone', 'underscore'], (jQuery, Backbone, _) ->
      root.Backbone.ViewDSL = factory(jQuery, Backbone, _)
  else
    root.Backbone.ViewDSL = factory(root.jQuery, root.Backbone, root._)
) this, (jQuery, Backbone, _) ->

  {isString, isArray, isBoolean, isEqual, extend, toArray} = _

  ###
    Minimal promise implementation

    Promise.resolve() and Promise.reject() methods execute callbacks
    immediatelly if a result is already available. This is done mostly because
    of performance reasons and to minimize possible UI flicks.

    To prevent uncatched and unlogged exception it is always useful to call
    Promise.done() method at the end of the chain.
  ###
  class Promise
    extend this.prototype, Backbone.Events

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

    appendTo: (target) ->
      this.then (node) -> $(node).appendTo(target)

    prependTo: (target) ->
      this.then (node) -> $(node).prependTo(target)

  isPromise = (o) ->
    typeof o.then == 'function'

  promise = (value) ->
    return value if typeof value?.then == 'function'
    p = new Promise()
    p.resolve(value)
    p

  ###
    Join several `promises` into one which resolves only when all `promises` are
    resolved or fail fast.
  ###
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

  ###
    Promise-based version of AMD require() call.
  ###
  promiseRequire = (moduleName) ->
    p = new Promise()
    require [moduleName], (module) -> p.resolve(module)
    p

  ###
    Get attribute from `o` object by dotted path `p`

    If `callIfMethod` argument is true and path points to a function then call
    it preserving right scope and use returned value as a result
  ###
  getByPath = (o, p, callIfMethod = false) ->
    p = p.trim()
    return o if p.trim().length == 0
    for n in p.split('.')
      ctx = o
      o = ctx[n]
      break if o == undefined
      if callIfMethod and jQuery.isFunction(o)
        o = o.call(ctx)
    o

  ###
    Resolve spec

    Specs can be:
    * `some/module:some.obj` resolves `some.obj` against `some/module` module
    * `some.obj` resolves `some.obj` against `window`
    * `@some.obj` resolves `some.obj` against `scope` argument
  ###
  getBySpec = (spec, scope) ->
    if /:/.test spec
      [module, path] = spec.split(':', 2)
      promiseRequire(module).then (module) -> getByPath(module, path)
    else if spec and spec[0] == '@'
      promise scope.get(spec.slice(1))
    else
      promise getByPath(window, spec)

  hypensToCamelCase = (o) ->
    o.replace /-([a-z])/g, (g) -> g[1].toUpperCase()

  $fromArray = (nodes) ->
    o = $()
    for node in nodes
      o = o.add(node)
    o

  ###
    Prepare `template` to be processed

    Argument `template` can be a DOM node, a jQuery element or just a string
    with HTML markup. If `requireSingleNode` is true then it's required from
    `template` to represent just a single DOM node.
  ###
  asNode = (node, clone = true) ->
    nodes = if node.jquery
      if clone then node.clone() else node
    else if typeof node.cloneNode == 'function'
      $(if clone then node.cloneNode(true) else node)
    else if isArray(node)
      $fromArray(node)
    else
      $fromArray($.parseHTML(String(node)))

    nodes

  ###
    Scope
  ###
  class Scope

    constructor: (ctx, locals, parent) ->
      this.ctx = ctx
      this.locals = locals
      this.parent = parent

    get: (path, callIfMethod = false) ->
      result = getByPath(this.locals, path, callIfMethod) if this.locals?
      return result if result?

      result = getByPath(this.ctx, path, callIfMethod)
      return result if result?

      result = this.parent.get(path, callIfMethod) if this.parent?
      return result if result?

  ###
    Interpreter which interprets markup constructs and perform actions.
  ###
  class Interpreter
    @scope: Scope

    textNodeSplitRe: /({{)|(}})/
    processAttrRe: /^attr-/

    constructor: (scope) ->
      this.scope = scope

    render: (template, clone = true) ->
      $node = asNode(template, clone)
      join(this.process($ n) for n in $node)

    process: ($node) ->
      return promise($node) if $node.data('seen')

      $node.data('seen', true)

      this.processAttributes($node).then (pragmas) =>
        if pragmas.skip
          promise($node)

        else if pragmas.remove
          $node.remove()
          promise()

        else
          this.processNode($node)

    processNode: ($node) ->
      node = $node[0]

      # text node interpolation
      if node.nodeType == Node.TEXT_NODE
        this.processTextNode($node).then (nodes) =>
          nodes.replaceAll($node) if nodes?
          nodes

      # view instantiation view <view /> tag
      else if node.tagName == 'VIEW'
        spec = $node.attr('name')
        if not spec?
          throw new Error('<view> element should have a name attribute')
        $node.removeAttr('name')
        this.instantiateView($node, {spec: spec, useNode: false})
          .then (view) =>
            view.$el.replaceAll($node)
            view.$el

      # recursively traverse children
      else
        join(this.process($ n) for n in toArray(node.childNodes)).then => $node

    processTextNode: ($node) ->
      return promise() unless this.textNodeSplitRe.test $node.data

      data = $node.text()
      data = data.replace(/{{/g, '{{\uF001')

      parts = data.split(this.textNodeSplitRe)
      parts = parts.filter (e) -> e and e != '{{' and e != '}}'

      nodes = for part in parts
        if part[0] == '\uF001'
          path = part.slice(1).trim()
          node = this.processInterpolation(path)
          continue unless node?
          node
        else
          document.createTextNode(part)

      join(nodes).then (nodes) ->
        $fromArray(nodes)

    processInterpolation: (path) ->
      node = this.scope.get(path, true)
      return if not node? or node == ''
      promise(node).then (node) ->
        asNode(node)

    processAttributes: ($node) ->
      node = $node[0]

      if node.nodeType != Node.ELEMENT_NODE
        return promise {}

      # conditional exclusion
      if node.attributes?.if
        show = this.scope.get(node.attributes.if.value, true)
        $node.removeAttr('if')
        return promise {remove: true} unless show

      # DOM element references
      if node.attributes?['element-id']
        if this.scope.ctx?
          this.scope.ctx[node.attributes?['element-id'].value] = $($node)
        $node.removeAttr('element-id')

      for attr in node.attributes when attr? and this.processAttrRe.test(attr.name)
        name = attr.name.substring(5)
        this.processAttrInterpolation($node, {name: attr.name, value: attr.value}, name)

      # view instantiation via view attribute
      if node.attributes?.view
        spec = node.attributes.view.value
        $node.removeAttr('view')
        this.instantiateView($node, {spec: spec, useNode: true})
          .then (view) ->
            if view.parameterizable then {skip: true} else {}

      else
        promise {}

    processAttrInterpolation: ($node, attr, attrName) ->
      value = this.scope.get(attr.value, true)

      if isBoolean(value)
        $node.prop(attrName, value)
      else
        $node.attr(attrName, value)

      $node.removeAttr(attr.name)

    instantiateView: ($node, options) ->
      node = $node[0]
      getBySpec(options.spec, this.scope).then (viewCls) =>
        if viewCls == undefined
          throw new Error("can't find a view by '#{options.spec}' spec")

        fromViewTag = node.tagName == 'VIEW'

        # read view params from node's attributes
        prefix = if fromViewTag then undefined else 'view-'
        {viewParams, viewId} = this.consumeViewParams($node, prefix)

        # create or init view
        view = if jQuery.isFunction(viewCls)
          viewParams.el = $node if options.useNode
          new viewCls(viewParams)
        else
          viewCls.setElement($node) if options.useNode
          viewCls

        # set class on a view if view was instantiated from a <view> tag
        if fromViewTag and node.attributes['class']
          view.$el.addClass(node.attributes['class'].value)

        # notify view about being a part of a view hierarchy
        view.parentScope = this.scope
        if this.scope.ctx?.addView?
          this.scope.ctx.addView(view, viewId)

        p = if view.parameterizable
          # if view is parameterizable we need to pass all DOM element inside
          # `node` to view's `render()` method so view can decide by its own what
          # to do next
          partial = $(node.childNodes).remove()
          promise view.render(partial)
        else
          promise view.render()

        p.then -> view

    consumeViewParams: ($node, prefix) ->
      node = $node[0]
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

        viewParams[attrName] = this.scope.get(a.value, true) or a.value

      {viewParams, viewId}

  ###
    View which can render process DSL.
  ###
  class View extends Backbone.View
    @interpreter: Interpreter

    template: undefined
    parameterizable: false
    parentScope: undefined

    @from: (template, locals) ->
      $node = asNode(template)
      if $node.length != 1
        throw new Error('templates only of single element are allowed')
      view = new this(el: $node)
      scope = new this.interpreter.scope(view, locals)
      interpreter = new this.interpreter(scope)
      interpreter.render($node, false).then ->
        view.render()
        view

    constructor: ->
      super
      this.views = []

    addView: (view, viewId) ->
      this.views.push(view)
      this[viewId] = view if viewId

    renderTemplate: (template, locals) ->
      scope = new this.constructor.interpreter.scope(this, locals, this.parentScope)
      interpreter = new this.constructor.interpreter(scope)
      interpreter.render(template)

    render: (locals) ->
      return promise(this) unless this.template?
      this
        .renderTemplate(this.template, locals)
        .appendTo(this.$el)
        .then => this

    remove: ->
      super
      for view in this.views
        view.remove()

  ###
    View parametrized with some template.
  ###
  class ParameterizableView extends View
    parameterizable: true

    render: (partial, locals) ->
      if this.template
        locals = extend({}, locals, {partial: this.renderTemplate(partial)})
        super(locals)
      else
        this.renderTemplate(partial).appendTo(this.$el)

  class ObservableScope extends Scope
    extend this.prototype, Backbone.Events

    constructor: ->
      super
      if this.ctx?
        for k, v of this.ctx when this.ctx.hasOwnProperty(k)
          if (v instanceof Backbone.Model)
            v.on 'change', => this.digest()
          else if (v instanceof Backbone.Collection)
            v.on 'change add remove reset sort', => this.digest()
      this.observe = {}

    get: (path, callIfMethod = false) ->
      result = super
      this.observe[path] = result
      result

    digest: ->
      updates = {}

      for path, value of this.observe
        newValue = this.get(path, true)
        updates[path] = newValue unless isEqual(newValue, value)

      extend this.observe, updates

      for path, value of updates
        this.trigger("change:#{path}", value)

  class BindingInterpreter extends Interpreter
    @scope: ObservableScope

    processInterpolation: (path) ->
      super.then ($node) =>
        $storedNode = $node
        if this.scope?
          this.scope.on "change:#{path}", (value) ->
            $newNode = asNode(value)
            $storedNode.replaceWith($newNode)
            $storedNode = $newNode
        $node

    processAttrInterpolation: ($node, attr, attrName) ->
      super
      if this.scope?
        this.scope.on "change:#{attr.value}", (value) =>
          if isBoolean(value)
            $node.prop(attrName, value)
          else
            $node.attr(attrName, value)

          $node.removeAttr(attr.name)

  class ActiveView extends View
    @interpreter: BindingInterpreter

  {View, ParameterizableView, ActiveView}
