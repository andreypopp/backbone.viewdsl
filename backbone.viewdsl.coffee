###

  Backbone.ViewDSL

  2013 (c) Andrey Popp <8mayday@gmail.com>

###

((root, factory) ->
  if typeof exports == 'object'
    module.exports = factory(require('underscore'), require('backbone'))
  else if typeof define == 'function' and define.amd
    define ['underscore', 'backbone'], (_, Backbone) ->
      root.Backbone.ViewDSL = factory(_, Backbone)
  else
    root.Backbone.ViewDSL = factory(root._, root.Backbone)

) this, (_, Backbone) ->

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
    o = $()
    for node in nodes
      o = o.add(node)
    o

  $parseHTML = (nodes) ->
    if isString(nodes)
      $fromArray $.parseHTML(nodes)
    else
      nodes

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
      this.parent = options?.parent
      this.views = []
      this.compiler = new this.compilerClass(this)

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
      for view in this.views
        view.remove()
      this.parent = undefined

    addView: (view, id) ->
      this.views.push(view)
      this[id] = view if id

    get: (p, options) ->
      this.getOwn(p, options) or this.parent?.get(p, options)

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

    compileInterpolation: ($node, path) ->
      (scope, $node) ->
        got = scope.get(path)
        got = document.createTextNode(got) if isString(got)
        $node.replaceWith(got)

    compileAttr: ($node, name, value) ->
      attrName = name.substring(5)
      $node.removeAttr(name)
      (scope, $node) ->
        got = scope.get(value)
        if isBoolean(got)
          $node.attr(attrName, '') if got
        else
          $node.attr(attrName, got)

    compileClass: ($node, name, value) ->
      className = name.slice(6)
      $node.removeAttr(name)
      (scope, $node) ->
        got = scope.get(value)
        if got
          $node.addClass(className)
        else
          $node.removeClass(className)

    compileShowIf: ($node, name, value) ->
      $node.removeAttr(name)
      (scope, $node) ->
        got = scope.get(value)
        if got then $node.show() else $node.hide()

    compileView: ($node, name, value) ->
      node = $node[0]
      element = not name?

      viewClass = if element
        spec = $node.attr('name')
        throw new Error("provide view attr") unless spec
        resolveSpec(spec, this)
      else
        $node.removeAttr(name)
        resolveSpec(value, this)

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

  class ActiveView extends View

    constructor: ->
      super
      if this.model
        this.listenTo this.model, 'change', =>
          this.digest()
      if this.collection
        this.listenTo this.collection, 'change add remove reset sort', =>
          this.digest()
      this.observe = {}

    digest: ->
      updates = {}

      for path, value of this.observe
        newValue = this.get(path)
        updates[path] = newValue unless isEqual(newValue, value)

      extend this.observe, updates

      for path, value of updates
        this.trigger("change:#{path}", value)

    reactOn: (p, options) ->
      value = this.get(p)
      if options?.observe
        this.observe[p] = value
      if options?.react
        options.react(value)
        if options.observe
          this.listenTo this, "change:#{p}", options.react

    remove: ->
      super
      this.observe = undefined

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
            got = $(document.createTextNode(got)) if isString(got)
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

  {Compiler, Template, View, ActiveView, $parseHTML}
