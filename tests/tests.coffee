define (require) ->

  {extend} = require 'underscore'
  {Compiler, View} = require 'backbone.viewdsl2'

  describe 'Compiler', ->

    outerHTML = ($node) ->
      $('<div></div>').append($node).html()

    it 'should compile node w/o any directives', ->
      c = new Compiler()
      t = c.compile $ '<div><span>a</span></div>'
      r = t.render()

      expect(t.$node.data('hasActions')).not.to.be.ok
      expect(outerHTML(r)).to.be.equal '<div><span>a</span></div>'

    it 'should compile node w/ element directive', ->
      c = new Compiler()
      c.directives.compileHello = ($node) ->
        (scope, $node) ->
          $node.replaceWith($ '<span>Hello, world</span>')
      t = c.compile $ '<div><hello></hello></div>'
      r = t.render()

      expect(t.$node.data('hasActions')).to.be.ok
      expect(outerHTML(r)).to.be.equal '<div><span>Hello, world</span></div>'

    it 'should compile node w/ element directive', ->
      c = new Compiler()
      c.directives.compileHello = ($node, name, value) ->
        (scope, $node) ->
          $node.html($ "<span>#{value}</span>")
          $node.removeAttr(name)
      t = c.compile $ '<div><div hello="Huh?!"></div></div>'
      r = t.render()

      expect(t.$node.data('hasActions')).to.be.ok
      expect(outerHTML(r)).to.be.equal '<div><div><span>Huh?!</span></div></div>'


  describe 'View', ->

    render = (t, s) ->
      class MyView extends View
        template: t
      v = new MyView()
      extend v, s
      v.render()
      v

    it 'should compile and render template', ->
      v = render '<div></div>'
      expect(v.$el.html()).to.be.equal '<div></div>'

    it 'should process attr-* directives', ->

      v = render '<div attr-c="c" attr-b="b"><span attr-a="a">a</span></div>',
        {a: 'aa', c: true, b: false}
      expect(v.$el.html()).to.be.equal '<div c=""><span a="aa">a</span></div>'

    it 'should process class-* directives', ->
      v = render '<div class-c="b"><span class-a="a">a</span></div>',
        {a: false, b: true}
      expect(v.$el.html()).to.be.equal '<div class="c"><span>a</span></div>'
