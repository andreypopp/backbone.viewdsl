Backbone.ViewDSL is a tiny library which provides a DSL for defining
Backbone.View hierarchies. If you are tired of manually composing views in your
Backbone application and want to get rid of all accompanying boilerplate then
this library could help you a bit.

Backbone.ViewDSL provides a DSL built on top of HTML with the following
features:

  * view instantiation (optionally loaded from AMD modules)
  * conditional exclusion of DOM elements from a final result
  * string and DOM node values interpolation

The basic example is to define a view which renders a chunk of HTML and instantiates
some sub-views:

    class App extends Backbone.ViewDSL.View
      template: """
        <h1>{{options.title}}</h1>
        <view name="app.views.Sidebar" id="sidebar" />
        <view name="app.views.Content" id="content" />
        <div class="footer">{{options.title}} by {{options.author}}</div>
        """

The code above is equivalent to the following piece of code written with "raw"
Backbone abstractions:

    class App extends Backbone.View
      render: ->
        this.$el.html """
          <h1>#{@options.title}</h1>
          <div class="footer">#{@options.title} by #{@options.author}</div>
          """
        $title = this.$('h1')
        this.content = new app.views.ContentView
        this.content.render()
        this.content.$el.after($title)
        this.sidebar = new app.views.SidebarView
        this.sidebar.render()
        this.sidebar.$el.after($title)

Which is, I think, more verbose and mostly consist of boilerplate. Also
`Backbone.ViewDSL.View` keeps track of instantiated views and handles its
disposal by removing all of them on a `remove()` call on parent view so you are
safe from memory leaks.

## Installation

You can simply get [`backbone.viewdsl.js`][Backbone.ViewDSL] from the repository
or use the repository as a submodule in your project. In that case you will need
all the dependencies to be in place — [jQuery][jQuery], [Backbone][Backbone] and
[RSVP.js][RSVP.js].

Otherwise you can use awesome [bower][bower] package manager and install
Backbone.ViewDSL with:

    bower install backbone.viewdsl

This way you will have Backbone.ViewDSL and all the dependencies installed under
`./components` directory.

## Usage

Backbone.ViewDSL provides a view base class with additional methods to use DSL
for DOM rendering. There are two ways to use it — the first one is an ad-hoc
view creation with a `from(template)` static method:

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

Static method `from(template)` accepts HTML strings, DOM elements or jQuery
elements as a `template` argument.

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
resolves to DOM node which is rendered from template. First argument `template`
can be a HTML string, DOM element or jQuery element. As a second argument
`renderDOM` accepts an object which provides "local" values to template context
so actual context's prototype chain looks like `localContext -> this`.

`Backbone.ViewDSL.View` also provides default implementation of
`render(localContext)` method which renders DOM from a template provided by
instance or prototype-level `template` attribute. In the latter case of
`template` attribute being attached to prototype — `render` method caches its
DOM representation not to parse template more than once when rendering multiple
view instances. So the easiest way to define view is:

    class SidebarView extends Backbone.ViewDSL.View
      tagName: "div"
      className: "sidebar"
      template: """
        <ul class="sidebar-items">
          <li class="sidebar-item">...</li>
          ...
        </ul>
        """

## View instantiation

There are two ways you can instantiate views — using `<view />` tag or
using `view` DOM attribute on any DOM element.

### Using `<view />` tag

If you use `<view />` tag then DOM element created by view will be used to
replace the `<view />` element in the resulting DOM, so the following code:

    class myapp.views.SidebarView extends Backbone.View
      className: 'sidebar'

    Backbone.ViewDSL.View.from """
      <div>
        <view name="myapp.views.SidebarView" />
      </div>
      """

will render DOM like this:

    <div>
      <div class="sidebar"></div>
    </div>

Note that `div.sidebar` element is created by `SidebarView` view. So usually it
is a good idea to use `<view />` tag to instantiate views which can only
function correctly with predefined `tagName` or `className` attributes.

See *Specs* section below to learn how to specify view constructor in `name`
attribute.

### Using `view` attribute

If you use `view` attribute on a DOM element then the DOM element will be passed
as an `el` argument to a view constructor so all attributes on the DOM element
such as `id` and `class` will be preserved. This example:

    class myapp.views.ClickableLabel extends Backbone.View
      className: 'sidebar'

    Backbone.ViewDSL.View.from """
      <div>
        <span view="myapp.views.ClickableLabel" class="some-class"></span>
      </div>
      """

will result in the following DOM:

    <div>
      <span class="some-class"></span>
    </div>

Using `view` attribute for instantiating views is useful with those views which
can work with different configurations of `tagName` and/or `className`
arguments.

See *Specs* section below to learn how to specify view constructor in `view`
attribute.

### Accessing instantiated views

Sometimes you need to assign a specific view to an attribute of a parent
view. You can do that with `view-id` attribute when you instantiate views using
`view` attribute on a DOM element or with just an `id` attribute if you use
`<view />` tag:

    view = Backbone.ViewDSL.View.from """
      <view name="SomeView" id="someView" />
      <div view="AnotherView" id="anotherView></div>
      """
    view.someView instanceof SomeView # true
    view.anotherView instanceof AnotherView # true

Also all instantiated views are stored inside `views` attribute of a parent
view.  This is useful because on a call to `remove()` method of a parent view we
can also call `remove()` method of every instantiated view — this way we can
prevent memory "zombie" views. That's exactly the way how
`Backbone.ViewDSL.View.remove()` is implemented.

### Passing arguments into view constructor

You can pass additional parameters into view constructor. Consider the example:

    class MyView extends Backbone.ViewDSL.View
      template: """
        <view name="Sidebar" model="sidebarItems" id="sidebar" />
        <ul view="Toolbar"
          view-id="toolbar"
          view-width="100"
          view-items="toolbarItems"></ul>
        """

      initialize: ->
        this.toolbarItems = ["create", "edit", "remove"]

      sidebarItems: ->
        ["links", "comments"]

    view = new MyView
    view.render()
    view.sidebar.options.model # ["links", "comments"]
    view.toolbar.options.items # ["create", "edit", "remove"]
    view.toolbar.options.width # "100"

As you can see, you use `view-` prefixed attributes if you instantiate views
with `view` attribute on a DOM element, otherwise, with `<view />` tag you just
use attributes without any prefix.

Argument names are obtained by removing the `view-` prefix (only in case it was
exist) from attribute names and then converting them to camelCase so
`view-some-param` and `some-param` attribute names become `someParam` argument
name.

Argument value are looked up on a parent view object using attribute values:

  * If value is found — it is used for an argument value (see `toolbarItems`
    in the example above).
  * If method is found — it is called and returned value is used for an
    argument value (see `sidebarItems` in the example above).
  * If no method and no value is found — then just string attribute value is
    used (see `view-width` attribute in the example above)

Note, that `view-id` and `id` attributes are treated specially and are not
passed to view constructor (see *Accessing instantiated views* section above).

### Inserting already instantiated views into DOM

Sometimes you don't need to instantiate view but instead want just to render and
insert a DOM element of an already created view — the following example shows
how to do that:

    class MyView extends Backbone.ViewDSL.View
      template: """
        <h1>Sidebar</h1>
        <view name="@sidebarView" />
        <div view="@footerView"></div>
        """

      initialize: ->
        this.sidebarView = new SidebarView
        this.footerView = new FooterView

When using `<view />` tag it is replaced with view's element `el` but when using
`view` attribute on a DOM element a view's `setElement` method is called with
corresponding DOM element.

Note the special form of specs in `name` and `view` attributes which refers to
objects inside the context, e.g. inside the `MyView` instance.

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

Specs are strings which point to JS objects. They can point to some global
object, to some object inside a context (a view which renders a DOM) or
to some object inside AMD module:

  * `module1/module2:obj1.obj2` points to `obj2` inside `obj1` in
    `module1/module2` AMD module.

  * `obj1.obj2` points to `obj2` inside `obj1` inside `window` object

  * `@obj` points to `obj` of a context (a view which renders a DOM)

[jQuery]: http://jquery.com
[Backbone]: http://backbonejs.org
[RSVP.js]: https://github.com/tildeio/rsvp.js
[Backbone.ViewDSL]: https://raw.github.com/andreypopp/backbone.viewdsl/master/backbone.viewdsl.js
[bower]: http://twitter.github.com/bower/
