define (require) ->

  {extend} = require 'underscore'
  {Model} = require 'backbone'
  {Compiler, View, ActiveView, $parseHTML} = require 'backbone.viewdsl'

  describe 'Compiler', ->

    outerHTML = ($node) ->
      $('<div></div>').append($node).html()

    it 'should compile node w/o any directives', ->
      c = new Compiler()
      t = c.compile $ '<div><span>a</span></div>'
      r = t.render()

      expect(t.$node.data('hasActions')).not.to.be.ok
      expect(outerHTML(r)).to.be.equal '<div><span>a</span></div>'

    it 'should compile text only template', ->
      c = new Compiler()
      t = c.compile $parseHTML 'hello, world'
      r = t.render()

      expect(t.$node.data('hasActions')).not.to.be.ok
      expect(outerHTML(r)).to.be.equal 'hello, world'

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

  describe 'ActiveView', ->
    render = (t, s) ->
      class MyView extends ActiveView
        template: t
      v = new MyView(model: new Backbone.Model())
      v.model.set s
      v.render()
      v

    it 'should process and observe attr-* directives', ->

      v = render '''
        <div attr-c="model.c" attr-b="bind:model.b"><span attr-a="model.a.a">a</span></div>
        ''',
        {a: {a: 'aa'}, c: true, b: false}
      expect(v.$el.html()).to.be.equal '<div c=""><span a="aa">a</span></div>'
      v.model.set 'b', true
      expect(v.$el.html()).to.be.equal '<div c="" b=""><span a="aa">a</span></div>'
      v.model.set 'b', 'bb'
      expect(v.$el.html()).to.be.equal '<div c="" b="bb"><span a="aa">a</span></div>'

    it 'should process and observe class-* directives', ->
      v = render '<div class-c="model.b.b"><span class-a="bind:model.a">a</span></div>',
        {a: false, b: {b: true}}
      expect(v.$el.html()).to.be.equal '<div class="c"><span>a</span></div>'
      v.model.set 'a', true
      expect(v.$el.html()).to.be.equal '<div class="c"><span class="a">a</span></div>'

    it 'should process show-if directive', ->
      v = render '<div><span show-if="bind:model.a">a</span></div>',
        {a: false}
      expect(v.$el.html()).to.be.equal '<div><span style="display: none;">a</span></div>'
      v.model.set 'a', true
      expect(v.$el.html()).to.be.equal '<div><span style="display: inline;">a</span></div>'

    describe 'interpolation', ->

      it 'should interpolate values', ->
        v = render '<div>Hello, {{model.name}}!</div>', {name: 'World'}
        expect(v.$el.html()).to.be.equal '<div>Hello, World!</div>'

      it 'should interpolate values and observe them', ->
        v = render '<div>Hello, {{bind:model.name}}!</div>', {name: 'World'}
        expect(v.$el.html()).to.be.equal '<div>Hello, World!</div>'
        v.model.set 'name', 'Andrey'
        expect(v.$el.html()).to.be.equal '<div>Hello, Andrey!</div>'

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

      v = render '<div attr-c="c" attr-b="b"><span attr-a="a.a">a</span></div>',
        {a: {a: 'aa'}, c: true, b: false}
      expect(v.$el.html()).to.be.equal '<div c=""><span a="aa">a</span></div>'

    it 'should process class-* directives', ->
      v = render '<div class-c="b.b"><span class-a="a">a</span></div>',
        {a: false, b: {b: true}}
      expect(v.$el.html()).to.be.equal '<div class="c"><span>a</span></div>'

    it 'should process show-if directive', ->
      v = render '<div><span show-if="a">a</span></div>',
        {a: false}
      expect(v.$el.html()).to.be.equal '<div><span style="display: none;">a</span></div>'
      v = render '<div><span show-if="a">a</span></div>',
        {a: true}
      expect(v.$el.html()).to.be.equal '<div><span style="display: inline;">a</span></div>'

    describe 'interpolation', ->

      it 'should interpolate string values', ->
        v = render '<div>Hello, {{name}}!</div>', {name: 'World'}
        expect(v.$el.html()).to.be.equal '<div>Hello, World!</div>'

      it 'should interpolate DOM values', ->
        v = render '<div>Hello, {{name}}!</div>', {name: document.createTextNode('World')}
        expect(v.$el.html()).to.be.equal '<div>Hello, World!</div>'

      it 'should interpolate jQuery values', ->
        v = render '<div>Hello, {{name}}!</div>', {name: $('<span>World</span>')}
        expect(v.$el.html()).to.be.equal '<div>Hello, <span>World</span>!</div>'

      it 'should interpolate nested values', ->
        v = render '<div>Hello, {{my.name}}!</div>', {my: {name: 'World'}}
        expect(v.$el.html()).to.be.equal '<div>Hello, World!</div>'

    describe 'view directive', ->

      class window.Hello extends View
        template: "<span>hello</span>"

      class window.Hello2 extends View
        @parameterizable: true
        render: ($template) ->
          $wrap = $ document.createElement('div')
          $wrap.append this.renderTemplate($template)
          this.$el.append $wrap

      it 'should instantiate view from view element', ->
        v = render '<div><view name="Hello" a="a" b="b" id="v"></view></div>', {a: 42}
        expect(v.$el.html()).to.be.equal '<div><div><span>hello</span></div></div>'
        expect(v.views.length).to.be.equal 1
        expect(v.v instanceof window.Hello).to.be.ok
        expect(v.v.options.a).to.be.equal 42
        expect(v.v.options.b).to.be.equal 'b'

      it 'should instantiate view from view attr', ->
        v = render '''
          <div><div view-id="v" view="Hello" view-a="a" view-b="b"></view></div>
          ''', {a: 42}
        expect(v.$el.html()).to.be.equal '<div><div><span>hello</span></div></div>'
        expect(v.views.length).to.be.equal 1
        expect(v.v instanceof window.Hello).to.be.ok
        expect(v.v.options.a).to.be.equal 42
        expect(v.v.options.b).to.be.equal 'b'

    describe 'view directive w/ parameterizable views', ->

      it 'should pass view innerHTML as arg to render() when rendered via elem', ->
        v = render '<view name="Hello2" id="v"><span>Hello</span></view>'
        expect(v.$el.html()).to.be.equal '<div><div><span>Hello</span></div></div>'

      it 'should pass view innerHTML as arg to render() when rendered via elem', ->
        v = render '<div view="Hello2" view-id="v"><span>Hello</span></div>'
        expect(v.$el.html()).to.be.equal '<div><div><span>Hello</span></div></div>'

      it 'should handle context chaining', ->
        v = render '<view name="Hello2" b="c" id="v">{{a}} - {{options.b}}</view>',
          {a: 'parent', c: 'child'}
        expect(v.$el.html()).to.be.equal '<div><div>parent - child</div></div>'
