* `<view name="spec" />` construct for instantiating views with its own element
  configuration (preserving view's tagName, className and attributes)

* allow views to be parametrized by a chunk of markup, like
  ```
  <div view="MyView">
    <span>...</span>
  </div>
  ```
  would pass rendered children of div to MyView.render() method as an argument.
  There could be also an option to pass not yet rendered DOM template to view

* allow view instantiations to be not instantiations but just to append node of
  some view to DOM if spec refers on already instantiated view. In that case we
  should just call render() method before inserting view's element into DOM

* allow spec to refer to object inside context, like
  ```
  <div view="@someView"></div>
  ```
