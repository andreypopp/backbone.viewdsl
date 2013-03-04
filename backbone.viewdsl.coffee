###

  Backbone.ViewDSL

  2013 (c) Andrey Popp <8mayday@gmail.com>

###

((root, factory) ->
  if typeof exports == 'object'
    _ = require 'underscore'
    Backbone = require 'backbone'
    module.exports = factory(_, Backbone, require)
  else if typeof define == 'function' and define.amd
    define (require) ->
      _ = require 'underscore'
      Backbone = require 'backbone'
      root.Backbone.ViewDSL = factory(_, Backbone, require)
  else
    root.Backbone.ViewDSL = factory(root._, root.Backbone)

) this, (_, Backbone, require) ->

  {some, extend, toArray, isEqual, isBoolean, isString} = _

  resolvePath = (o, p) ->
    p = p.trim()
    return o if p.trim().length == 0
    for n in p.split('.')
      o = o[n]
      break if o == undefined
    o

  resolveSpec = (spec, ctx) ->
    if /:/.test spec
      throw new Error('not a CommonJS environment') unless require?
      [mod, name] = spec.split(':', 2)
      resolvePath(require(mod), name)
    else if /^this\./.test(spec)
      resolvePath(ctx, spec.substring(5))
    else if /^@/.test(spec)
      resolvePath(ctx, spec.substring(1))
    else
      resolvePath(window, spec)

  hypensToCamelCase = (o) ->
    o.replace /-([a-z])/g, (g) -> g[1].toUpperCase()

  knownTags = ///
  ^(DIV|SPAN|BODY|HTML|HEAD|SECTION|HEADER|H1|H2|H3|H4|H5|H6|EM
  |TR|TD|THEAD|TBODY|TABLE|INPUT|TEXTAREA|EMBED|FONT|DD|DT|DL
  |FORM|A|B|BIG|BR|HR|I|UL|LI|OL|META|OPTION|SELECT|SMALL
  |STRONG|TITLE|TT|U)$
  ///

  knownAttrs = ///
  ^(class|enabled|id)$
  ///

  textNodeSplitRe = /({{)|(}})/

  $fromArray = (nodes) ->
    if nodes == null
      nodes = [$ document.createTextNode('')]
    o = $()
    for node in nodes
      o = o.add(node)
    o

  $parseHTML = (nodes) ->
    if isString(nodes)
      $fromArray $.parseHTML(nodes)
    else
      nodes

  $nodify = (o) ->
    if isString(o)
      $parseHTML(o)
    else if o.jquery?
      o
    else if o.nodeType?
      $ o
    else
      $ document.createTextNode(String(o))

  $isEmpty = (n) ->
    return true if not n?
    if isString(n)
      n.trim() == ''
    else if n.jquery?
      n.size() == 0
    else if n.nodeType?
      false

  ###
    HTML compiler
  ###
  class Compiler

    constructor: (directives = {}) ->
      this.directives = directives

    compile: ($node) ->
      $wrap = $ document.createElement('div')
      $wrap.append($node)
      this.compileImpl($wrap)
      new Template($wrap)

    directiveFor: (name) ->
      name = 'attr' if name.slice(0, 5) == 'attr-'
      name = 'class' if name.slice(0, 6) == 'class-'
      directive = this.directives[hypensToCamelCase("compile-#{name}")]
      directive?.bind(this.directives)

    compileImpl: ($node) ->
      node = $node[0]
      if node.nodeType == Node.TEXT_NODE
        this.compileTextNode($node)
      else
        this.compileNode($node)

    compileTextNode: ($node) ->
      data = $node.text()
      return false unless textNodeSplitRe.test data

      data = data.replace(/{{/g, '{{\uF001')
      parts = data.split(textNodeSplitRe)
      parts = parts.filter (e) -> e and e != '{{' and e != '}}'

      nodes = for part in parts
        if part[0] == '\uF001'
          path = part.slice(1).trim()
          $part = $ document.createElement('span')
          action = this.directives.compileInterpolation($part, path)
          $part.data('hasActions', true)
          $part.data('actions', [action])
          $part
        else
          $ document.createTextNode(part)

      $node.replaceWith $fromArray nodes

      true

    compileNode: ($node) ->
      node = $node[0]

      if not knownTags.test node.tagName
        directive = this.directiveFor(node.tagName.toLowerCase())
      else
        directive = undefined

      actions = if directive then [directive($node)] else []

      attrActions = for attr in toArray(node.attributes)
        if knownAttrs.test attr.name
          continue
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
      $rendered.contents()

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

  class View extends Backbone.View
    @parameterizable: false
    template: undefined
    compilerClass: Compiler

    constructor: (options) ->
      super
      this.template = options?.template if options?.template?
      this.parent = options?.parent
      this.views = []
      this.compiler = new this.compilerClass(this)

      if this.model?
        this.listenTo this.model, 'change', =>
          this.digest()

      if this.collection?
        this.listenTo this.collection, 'change add remove reset sort', =>
          this.digest()

      this.observe = {}

    renderTemplate: (template) ->
      if not (template instanceof Template)
        template = this.compiler.compile($parseHTML template)
      template.render(this)

    render: ->
      throw new Error("undefined template") unless this.template
      if not (this.template instanceof Template)
        this.template = this.compiler.compile($parseHTML this.template)
      this.$el.append(this.template.render(this))

    remove: ->
      super
      this.removeViews()
      this.parent = undefined
      this.observe = undefined
      this.views = undefined

    removeViews: ->
      for view in this.views
        view.remove()

    addView: (view, id) ->
      this.views.push(view)
      this[id] = view if id

    get: (p, options) ->
      own = this.getOwn(p, options)
      return own if own != undefined
      this.parent?.get(p, options)

    getOwn: (p, options) ->
      p = p.trim()
      o = this
      return o if p.trim().length == 0
      for n in p.split('.')
        ctx = o
        o = if (ctx instanceof Backbone.Model)
          ctx.get(n) or ctx[n]
        else
          ctx[n]
        break if o == undefined
        if jQuery.isFunction(o)
          o = o.call(ctx)
      o

    reactOn: (p, options) ->
      value = this.get(p)
      if options?.observe
        this.observe[p] = value
      if options?.react
        options.react(value)
        if options.observe
          this.listenTo this, "change:#{p}", options.react

    digest: ->
      updates = {}

      for path, value of this.observe
        newValue = this.get(path)
        updates[path] = newValue unless isEqual(newValue, value)

      extend this.observe, updates

      for path, value of updates
        this.trigger("change:#{path}", value)

    compileInterpolation: ($node, value) ->
      observe = false
      if value.substring(0, 5) == 'bind:'
        value = value.substring(5)
        observe = true
      (scope, $node) ->
        $point = $node
        scope.reactOn value,
          observe: observe
          react: (got) ->
            got = $nodify(if got != undefined then got else '')
            $point.replaceWith(got)
            $point = got

    compileAttr: ($node, name, value) ->
      observe = false
      if value.substring(0, 5) == 'bind:'
        value = value.substring(5)
        observe = true
      attrName = name.substring(5)
      $node.removeAttr(name)
      (scope, $node) ->
        scope.reactOn value,
          observe: observe
          react: (got) ->
            if isBoolean(got)
              $node.attr(attrName, '') if got
            else
              $node.attr(attrName, got)

    compileClass: ($node, name, value) ->
      observe = false
      if value.substring(0, 5) == 'bind:'
        value = value.substring(5)
        observe = true
      className = name.slice(6)
      $node.removeAttr(name)
      (scope, $node) ->
        scope.reactOn value,
          observe: observe
          react: (got) ->
            if got
              $node.addClass(className)
            else
              $node.removeClass(className)

    compileShowIf: ($node, name, value) ->
      observe = false
      if value.substring(0, 5) == 'bind:'
        value = value.substring(5)
        observe = true
      $node.removeAttr(name)
      (scope, $node) ->
        scope.reactOn value,
          observe: observe
          react: (got) ->
            if got then $node.show() else $node.hide()

    compileForeach: ($node, name, value) ->
      this.viewDirective(CollectionView, $node, name, value)

    compileView: ($node, name, value) ->
      viewClass = if not name?
        spec = $node.attr('name')
        throw new Error("provide view attr") unless spec
        resolveSpec(spec, this)
      else
        $node.removeAttr(name)
        resolveSpec(value, this)
      this.viewDirective(viewClass, $node, name, value)

    viewDirective: (viewClass, $node, name, value) ->
      node = $node[0]
      element = not name?

      viewIdAttr = if element then 'id' else 'view-id'
      viewId = $node.attr(viewIdAttr)
      $node.removeAttr(viewIdAttr)

      template = if element or viewClass.parameterizable
        $node.contents().detach()

      (scope, $node) ->

        viewParams = {}

        for a in toArray(node.attributes)
          if not element and a.name.slice(0, 5) != 'view-'
            continue

          attrName = if element then a.name else a.name.slice(5)
          attrName = hypensToCamelCase(attrName)

          viewParams[attrName] = scope.get(a.value) or a.value

          $node.removeAttr(a.name) if not element

        viewParams.parent = scope
        viewParams.el = $node if not element

        view = new viewClass(viewParams)
        view.render(template)

        $node.replaceWith(view.$el) if element
        scope.addView(view, viewId)

  class CollectionView extends View
    @parameterizable: true

    template: undefined
    itemView: undefined
    makeItemView: undefined

    constructor: ->
      super
      this.listenTo this.collection,
        reset: this.onReset
        sort: this.onSort
        add: this.onAdd
        remove: this.onRemove

    render: (template) ->
      this.setupItemView(template)
      this.onReset()
      this

    setupItemView: (maybeTemplate) ->
      if not $isEmpty(maybeTemplate)
        this.template = maybeTemplate

      if this.template?
        this.template = $nodify(this.template)

      if this.options.itemView?
        this.itemView = resolveSpec(this.options.itemView, this)

      this.makeItemView = if this.itemView?
        (model, index) =>
          view = new this.itemView(model: model, index: index)
          view.render()
          view
      else if this.template
        (model, index) =>
          view = new View(
            template: this.template.clone(true, true),
            model: model, index: index)
          view.render()
          view
      else
        throw new Error("provide either 'template' or 'itemView' attr")

    viewByModel: (model) ->
      for view, idx in this.views
        if view.model.cid == model.cid
          return {view, idx}
      {view: undefined, idx: undefined}

    onReset: ->
      this.removeViews()
      this.collection.forEach (model) =>
        view = this.makeItemView(model, => this.collection.indexOf(model))
        this.$el.append(view.$el)
        this.views.push(view)

    onSort: ->
      $cur = undefined
      this.collection.forEach (model, newIdx) =>
        {view, idx} = this.viewByModel(model)
        this.views.splice(idx, 1)[0]
        this.views.splice(newIdx, view)
        view.options.index = newIdx
        view.$el.detach()
        view.digest()
        if not $cur
          this.$el.append view.$el
        else 
          view.$el.after $cur
          $cur = view.$el

    onAdd: (model) ->
      idx = this.collection.indexOf(model)
      view = this.makeItemView(model, => this.collection.indexOf(model))
      if idx >= this.$el.children().size()
        this.$el.append(view.$el)
      else
        this.$el.children().eq(idx).before(view.$el)
        for view in this.views[idx..]
          view.digest() if view?.digest?
      this.views.push(view)

    onRemove: (model) ->
      {view, idx} = this.viewByModel(model)
      if view
        view.remove()
        this.views.splice(idx, 1)
        for view in this.views[idx..]
          view.digest() if view?.digest?

  {Compiler, Template, View, CollectionView, $parseHTML}
