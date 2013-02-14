###

  Backbone.ViewDSL2

  2013 (c) Andrey Popp <8mayday@gmail.com>

###

###
  Minimal promise implementation

  Promise.resolve() and Promise.reject() methods execute callbacks
  immediatelly if a result is already available. This is done mostly because
  of performance reasons and to minimize possible UI flicks.

  To prevent uncatched and unlogged exception it is always useful to call
  Promise.done() method at the end of the chain.
###
define (require) ->

  {some, extend, toArray, isBoolean} = require 'underscore'
  Backbone = require 'backbone'


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

  hypensToCamelCase = (o) ->
    o.replace /-([a-z])/g, (g) -> g[1].toUpperCase()

  ###
    HTML compiler
  ###
  class Compiler

    compile: ($node) ->
      this.compileImpl($node)
      new Template($node)

    attr: ($node, name, value) ->
      attrName = name.substring(5)
      $node.removeAttr(name)
      (scope, $node) ->
        got = scope[value]
        if isBoolean(got)
          $node.attr(attrName, '') if got
        else
          $node.attr(attrName, got)

    class: ($node, name, value) ->
      className = name.slice(6)
      $node.removeAttr(name)
      (scope, $node) ->
        got = scope[value]
        if got
          $node.addClass(className)
        else
          $node.removeClass(className)

    directiveFor: (name) ->
      name = 'attr' if name.slice(0, 5) == 'attr-'
      name = 'class' if name.slice(0, 6) == 'class-'
      this[hypensToCamelCase(name)]

    compileImpl: ($node) ->
      node = $node[0]
      if node.nodeType == Node.TEXT_NODE
        this.compileTextNode($node)
      else
        this.compileNode($node)

    compileTextNode: ($node) ->
      $node
      false

    compileNode: ($node) ->
      node = $node[0]

      directive = this.directiveFor(node.tagName.toLowerCase())

      actions = if directive
        [directive($node)]
      else
        []

      attrActions = for attr in toArray(node.attributes)
        directive = this.directiveFor(attr.name)
        continue unless directive
        directive($node, attr.name, attr.value)

      actions = actions.concat(attrActions)

      hasChildActions = node.childNodes.length > 0 and \
        some(this.compileImpl($ child) for child in node.childNodes)

      hasActions = actions.length > 0 or hasChildActions

      $node.data('actions', actions) if actions.length > 0
      $node.data('hasActions', hasActions)

      hasActions

  ###
    Template object
  ###
  class Template

    constructor: ($node) ->
      this.$node = $node

    render: (scope = {}) ->
      $rendered = this.$node.clone(true, true)
      this.renderImpl(scope, $rendered)

    renderImpl: (scope, $node) ->
      return $node unless $node.data('hasActions')
      actions = $node.data('actions')
      if actions
        for action in actions
          {stop} = action(scope, $node) or {}
          break if stop

      for child in toArray($node[0].childNodes)
        this.renderImpl(scope, $(child))

      $node

  standardCompiler = new Compiler()

  class View extends Backbone.View
    template: undefined
    compiler: standardCompiler

    renderTemplate: (template) ->
      if not (template instanceof Template)
        template = this.compiler.compile(template)
      template.render(this)

    render: ->
      throw new Error('undefined template') unless this.template
      if not (this.template instanceof Template)
        this.template = this.compiler.compile(template)
      this.$el.append(this.template.render(this))

  {Compiler, Template, View}
