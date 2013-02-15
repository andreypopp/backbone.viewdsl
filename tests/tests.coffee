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

    it 'should process show-if directive', ->
      v = render '<div><span show-if="a">a</span></div>',
        {a: false}
      expect(v.$el.html()).to.be.equal '<div><span style="display: none;">a</span></div>'
      v = render '<div><span show-if="a">a</span></div>',
        {a: true}
      expect(v.$el.html()).to.be.equal '<div><span style="display: inline;">a</span></div>'

    describe 'view directive', ->

      class window.Hello extends View
        template: "<span>hello</span>"

      it 'should instantiate view from view element', ->
        v = render '<div><view name="Hello" id="v"></view></div>'
        expect(v.$el.html()).to.be.equal '<div><div><span>hello</span></div></div>'
        expect(v.views.length).to.be.equal 1
        expect(v.v instanceof window.Hello).to.be.ok

      it 'should instantiate view from view attr', ->
        v = render '<div><div view-id="v" view="Hello"></view></div>'
        expect(v.$el.html()).to.be.equal '<div><div><span>hello</span></div></div>'
        expect(v.views.length).to.be.equal 1
        expect(v.v instanceof window.Hello).to.be.ok
