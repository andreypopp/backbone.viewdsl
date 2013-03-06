# Backbone.ViewDSL

Backbone.ViewDSL provides declarative view technology on top of Backbone.

The main feature of Backbone.ViewDSL is an extensible DOM templating engine
which allows you to

  * Interpolate string or DOM values
  * Instantiate sub-views directly from inside templates
  * Bind data to DOM text nodes or element attributes
  * Automatically setup references for DOM nodes being rendered
  * Create custom directives as custom HTML tags or attributes

To give a taste of these features there's a basic example

    class App extends Backbone.ViewDSL.View
      template: """
        <h1 element-id="$header">{{bind:user.name}}'s todos</h1>
        <view name="views:UserCard" model="user"></view>
        <foreach collection="todos">
          <view name="views:TodoView"></view>
        </foreach>
        """

This work was mainly inspired by [Angular.js][] but tries to stay as close to
Backbone style as possible so it is very easy to use in your application in a
completely non-intrusive way.

[Angular.js]: http://angularjs.org/

## Installation

You can grab [compiled JavaScript code][code] from the [repo][] or use `npm`:

    % npm install backbone.viewdsl

 or `bower` package managers:

    % bower install backbone.viewdsl

The only dependencies are jQuery, Backbone and underscore.js — if you use one of
the package managers they will be installed automatically, otherwise you should
download them by hand.

Backbone.ViewDSL designed to work in CommonJS environment as well as with any
available AMD loader (such as RequireJS). If you don't use nor AMD neither
CommonJS loading strategies then all the public API will be available through
the `Backbone.ViewDSL` browser global.

[code]: https://raw.github.com/andreypopp/backbone.viewdsl/master/backbone.viewdsl.js
[repo]: https://github.com/andreypopp/backbone.viewdsl

## Basic usage

The main usage pattern is exposed via `Backbone.ViewDSL.View` subclass of
`Backbone.View` with a custom implementation of `render()` method.

Usually you want to define a new subclass of it and set a `template` attribute:

    class Message extends Backbone.ViewDSL.View
      template: """
        {{greeting}}, {{options.name}}!
        """

      greeting: ->
        'Hello'

    view = new Message(name: 'World')
    view.render()

This template uses string interpolation to insert `options.name` value and a
result of `greeting()` method call inside the DOM text node. That way view's
`el` DOM element will have a form of `<div>Hello, World!</div>`.

Templates are always rendered in the context of a view so we can reference any
view's attribute inside them or call any methods without arguments. If you need
to reach some nested attribute or method then you can use usual dotted-path like
`a.b.c`.

## Sub-views instantiation

Backbone doesn't have an opinion on how to manage view hierarchies inside your
application so usually you cook something by yourself.

Backbone.ViewDSL tries to make this task a lot easier by providing you with a
*view* directive which allows instantiating sub-views right from inside
templates. The directive can be used as a `<view>` DOM element or `view` DOM
attribute.

The example would be

    class App extends Backbone.ViewDSL.View
      template: """
        <view name="views.Sidebar" model="user" id="sidebar"></view>
        <footer view="views.Footer" view-model="user" view-id="footer"></footer>
        """

    app = new App
    app.render()

This snippet of code alone makes a lot of things under the hood.

View `views.Sidebar` will be rendered and `app.user` will be passed into its
constructor as a `model` option. After that rendered view will be stored as
`app.sidebar` attribute.

There's a bit different story with `views.Footer` — it also gets `app.user` as a
constructor `model` option but instead of creating new DOM node for the view
itself it will reuse `<footer>` element. That could be useful if you don't know
before with what kind of element view will be used.

Without using Backbone.ViewDSL all of these would look like this:

    class App extends Backbone.View

      render: ->
        this.sidebar = new Sidebar(model: this.user)
        this.sidebar.render()
        this.$el.append(this.sidebar.$el)

        this.footer = new Footer(model: this.user, tagName: 'footer')
        this.footer.render()
        this.$el.append(this.footer.$el)

The variant which uses `Backbone.ViewDSL.ViewDSL` looks a lot cleaner, doesn't
it? Also `Backbone.ViewDSL.View` keeps track of all instantiated sub-views and
handles its disposal so no memory leaks will happen.

## String and DOM values interpolation

As it was already shown Backbone.ViewDSL allows you to insert specific
bits of text inside templates. But what's more interesting — you can also insert
entire DOM elements into templates, even with attached event handlers.

    class View extends Backbone.ViewDSL.ViewDSL
      template: """
        {{element}} {{jquery}}
        """
      element: ->
        document.createElement('div')
      jquery: ->
        $('<div>').addClass('klass')

Rendered view will have `<div></div> <div class="klass"></div>` as its content.
As you can see you can also insert jQuery objects into template.

## Referencing DOM nodes

Sometimes you need to reference DOM element from recently rendered template —
you can select it by using `this.$` method call but a better way would be to use
`element-id` attribute directive.

    class View extends Backbone.ViewDSL.View
      template: """
        <div class="main" element-id="block"></div>
        """

    view = new View
    view.render()

That way rendered `<div>` element will be available as `view.block` attribute.

## Other built-in directives

There are a couple of other built-in directives — `attr-*` and `class-*`
wildcard directives and `show-if` directive.

The `attr-*` directive can be used to attach attributes to DOM elements based on
some view's value. For example given the template

    <img attr-src="model.imageURL">

We will get `src` attribute set to value of `model.imageURL` view's attribute.
There's also a special case for attributes which has boolean interpretation
(`checked`, `contenteditable` and so on...)  — if expression evaluates to
`Boolean` value then attribute will be present if value is `true` in case of
`false` value attribute will not be rendered.

    class View extends Backbone.ViewDSL.View
      template: """
        <h1 attr-contenteditable="isEditable">title</h1>
        """
      isEditable: ->
        this.model.get('isEditable') and this.user.canEdit(this.model)

Note that `isEditable` method returns boolean value.

The `class-*` wildcard directive works like a `attr-*` directive but instead
regulates if element should receive an additional CSS class based on some view's
attribute or method.

    class View extends Backbone.ViewDSL.View
      template: """
        <h1 class-editable="isEditable">title</h1>
        """
      isEditable: ->
        this.model.get('isEditable') and this.user.canEdit(this.model)

In this example, `<h1>` will have class `editable` if and only if `isEditable`
method evaluates to `true`.

The last of the built-in directives — `show-if` controls if element is visible
based on some expression which evaluates to boolean value:

    <div show-if="this.collection.isEmpty">No items"</div>

The `<div>` element will be displayed only if `this.collection.isEmpty()`
evaluates to `true`. Methods `$.show()` and `$.hide()` are used to
correspondingly show and hide elements.

## Data-binding

You want your views to react to underlying data changes but manually maintaining
a set of `change` event handlers isn't an option.

For that reason a part of Backbone.ViewDSL directives like `attr-*`, `class-*`
and `show-if` as well as interpolation mechanism allows you to bind their action
on data changes and react to them accordingly.

To turn data-binding on you have to prefix all expressions with `bind:`
modifier:

    class View extends Backbone.ViewDSL.View
      redAllowed: true

      template: """
        <div class-red="bind:isRed">Hello, {{bind:model.name}}!</div>
        """

      isRed: ->
        this.model.get('red') and this.redAllowed

    view = new View(model: new Backbone.Model(name: 'World', red: false))
    view.render()

That way rendered view will react to data changes according to directive
actions.

## Creating custom directives

## Rendering collections

## Parametrizable views
