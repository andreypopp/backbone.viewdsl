* allow views to be parametrized by a chunk of markup, like
  ```
  <div view="MyView">
    <span>...</span>
  </div>
  ```
  would pass rendered children of div to MyView.render() method as an argument.
  There could be also an option to pass not yet rendered DOM template to view

  what about context for that? should we chain context with the parent ones?

* allow custom element/attributes handlers

* `{{mod2:mod1:val}}` syntax which is transformed into `mod2(mod1(val))`

* data-binding for interpolated values

* event binding
  ```
  <div view="MyView" onsomeevent="someMethod"></div>
  ```
  would do `this.listenTo view, "someevent", this.someMethod`

* explore possible integration paths with mozilla's x-tags
