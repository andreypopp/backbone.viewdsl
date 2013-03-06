# must have

* View.digest() to emit 'digest' event
* Views can subscribe to other views' 'digest' events (needed when view resolves
  expression not from own but from one of the parents' scopes)
* CollectionView shouldn't introduce additional `<div>` element when it is being
  parametrized by DOM with just a single element inside

# not likely

* extend show-if, attr- and class- to work as elements, that way they should
  apply on its parent element so it can be possible to apply directives to
  View.el
* more complex expressions
  * boolean: or, not, and
  * arithemtics: +, -, /, *
  * literals: strings, numbers
  * function calls
  * ternary expressions; if pred then ... else ...
