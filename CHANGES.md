# 0.9.0

* remove `View.renderDOM(...)` method, use
  `View.renderTemplate(..).appendTo(this.el)` instead.
* remove semi-private `View.setParentScope(scope)` method

# 0.8.2

* added ParameterizeableView, shortcut for views which can take a piece of
  template as a parameter
