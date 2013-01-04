Backbone.ViewDSL is a tiny library which provides a DSL for defining
Backbone.View hierarchies. If you are tired of manually composing views in your
Backbone application and want to get rid of all accompanying boilerplate then
this library could help a bit.

Backbone.ViewDSL provides a DSL built on top of HTML with the following
features:

  * view instantiation (optionally loaded from AMD modules)

  * conditional exclusion of DOM elements from a final result

  * string and DOM node values interpolation

## Installation

You can simply get
[`backbone.viewdsl.js`](https://raw.github.com/andreypopp/backbone.viewdsl/master/backbone.viewdsl.js)
from the repository or use the repository as a submodule in your project. In
that case you will need all the dependencies to be in place —
[jQuery](http://jquery.com), [Backbone](http://http://backbonejs.org) and
[RSVP.js](https://github.com/tildeio/rsvp.js).

Otherwise you can use awesome [bower](http://twitter.github.com/bower/) package
manager and install Backbone.ViewDSL with:

    bower install backbone.viewdsl

This way you will have Backbone.ViewDSL and all the dependencies installed under
`./components` directory.

## Usage

Backbone.ViewDSL provides a view base class with additional methods to use DSL
for DOM rendering. There are two ways to use it — the first one is an ad-hoc
view creation with a `from` static method:

    sidebarPromise = Backbone.ViewDSL.View.from """
      <div class="sidebar">
        <ul class="sidebar-items">
          <li class="sidebar-item">...</li>
          ...
        </ul>
      </div>
      """

This way you get a `sidebarPromise`, a promise value which will resolve
asynchronously in the future. The reason it returns a promise is because
rendering process may require to load some additional resources using XHR (such
as additional view classes). You can execute some code with a constructed view
by attaching `then` callback to the promise:

    sidebarPromise.then (sidebar) ->
      console.log "View constructed: #{sidebar}"

Note that the `div.sidebar` will become the root element, the `el` of the view.

Another way to use `Backbone.ViewDSL.View` is to subclass it and use
`renderDOM(template, localContext)` method for rendering DOM:

    class SidebarView extends Backbone.ViewDSL.View
      tagName: "div"
      className: "sidebar"
      render: ->
        @renderDOM """
          <ul class="sidebar-items">
            <li class="sidebar-item">...</li>
            ...
          </ul>
          """

This way `renderDOM` method will also return a promise but the one which
resolves to DOM node which is rendered from template. As a second argument
`renderDOM` accepts an object which provides "local" values to template context
so actual context's prototype chain looks like `localContext -> this`.

## View instantiation

To instantiate a view you can use `view` DOM attribute:

    class MyView extends Backbone.ViewDSL.View

      render: ->
        @renderDOM """
          <div view="myapp.views.SidebarView" class="sidebar"></div>
          """

This way `myapp.views.SidebarView` will be instantiated and rendered with `div.sidebar`
element as the view's root element. All instantiated views become the "child
views" of a parent view and stored inside a `views` attribute — that means on
parent's `remove()` call they are also being freed by calling `remove()`.

You can also pass parameters to view constructor by using attributes which start
with `view-` prefix:

    class MyView extends Backbone.ViewDSL.View

      initialize: ->
        this.sidebar = new SidebarItems()

      render: ->
        @renderDOM """
          <div
            view="myapp.views.SidebarView"
            view-collection="sidebar"
            view-style="vertical"
            class="sidebar"></div>
          """

This will call a `myapp.views.SidebarView` constructor with `collection` and
`style` arguments — the first one will be equal to `sidebar` attribute of the
`MyView` instance, the second one — just a `"vertical"` string value. So this
will be equivalent to the following code:

    class MyView extends Backbone.View

      initialize: ->
        this.sidebar = new SidebarItems()

      render: ->
        this.sidebarView = new myapp.views.SidebarView
          className: 'sidebar'
          collection: this.sidebar
          style: 'vertical'
        this.sidebarView.render()
        this.$el.append(this.sidebarView.$el)

      remove: ->
        super
        this.sidebarView.remove()

Note that attributes those name contain more hyphens besides ones which are part
of the prefix will be converted to camelCase so `view-some-param` becomes
`someParam`.

## String and DOM node values interpolation

You can insert arbitrary strings, DOM nodes or jQuery elements into template:

    class MyView extends Backbone.ViewDSL.View

      name: ->
        $ '<span class="name">World</span>'

      render: ->
        @renderDOM """
          <div class="hello">
            Hello, {{name}}!
          </div>
          """

This will render a `Hello, <span class="name">World</span>` string inside
`div.hello` element. Note that you can also return just a raw string from
`name()` method — it will be converted to DOM `TextNode`; otherwise you can
return any DOM object.

## Conditional exclusion

To remove DOM nodes conditionally you can use `if` DOM attribute:

    class MyView extends Backbone.ViewDSL.View

      showConditional: ->
        this.options.showConditional

      render: ->
        @renderDOM """
          <div class="conditional" if="showConditional">
            ...
          </div>
          """

Element `div.conditional` will be removed if `showConditional()` method evaluates
to `false`. Note that you can also refer to view properties and not only methods
inside `if` attributes.

## Specs

Specs are strings which point to JS objects, specs can point to some global
object or to some object inside AMD module:

  * `module1/module2:obj1.obj2` points to `obj2` inside `obj1` in
    `module1/module2` AMD module.

  * `obj1.obj2` points to `obj2` inside `obj1` inside `window` object
