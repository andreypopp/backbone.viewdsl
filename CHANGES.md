# 0.10.0

* add DOM element class interpolation via `class-<classname>` attributes — if
  attribute value evaluates to truth then `classname` class will be added to DOM
  element

* add `Backbone.ViewDSL.ActiveView` which respond to underlying model changes
  and re-render itself

# 0.9.0

* remove `View.renderDOM(...)` method, use
  `View.renderTemplate(..).appendTo(this.el)` instead.
* remove semi-private `View.setParentScope(scope)` method

# 0.8.2

* added ParameterizeableView, shortcut for views which can take a piece of
  template as a parameter
