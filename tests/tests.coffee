define (require) ->

  {Compiler} = require 'backbone.viewdsl2'

  outerHTML = ($node) ->
    $('<div></div>').append($node).html()

  describe 'Compiler', ->

    it 'should compile node w/o any directives', ->
      c = new Compiler()
      t = c.compile $ '<div><span>a</span></div>'
      r = t.render()

      expect(t.$node.data('hasActions')).not.to.be.ok
      expect(outerHTML(r)).to.be.equal '<div><span>a</span></div>'

    it 'should compile node w/ element directive', ->
      c = new Compiler()
      c.hello = ($node) ->
        (scope, $node) ->
          $node.replaceWith($ '<span>Hello, world</span>')
      t = c.compile $ '<div><hello></hello></div>'
      r = t.render()

      expect(t.$node.data('hasActions')).to.be.ok
      expect(outerHTML(r)).to.be.equal '<div><span>Hello, world</span></div>'

    it 'should compile node w/ element directive', ->
      c = new Compiler()
      c.hello = ($node, name, value) ->
        (scope, $node) ->
          $node.html($ "<span>#{value}</span>")
          $node.removeAttr(name)
      t = c.compile $ '<div><div hello="Huh?!"></div></div>'
      r = t.render()

      expect(t.$node.data('hasActions')).to.be.ok
      expect(outerHTML(r)).to.be.equal '<div><div><span>Huh?!</span></div></div>'

    describe 'built-in directives', ->

      render = (t, s) ->
        c = new Compiler()
        t = c.compile $ t
        t.render(s)

      it 'should process attr-* directives', ->
        r = render '<div attr-c="c" attr-b="b"><span attr-a="a">a</span></div>',
          {a: 'aa', c: true, b: false}
        expect(outerHTML(r)).to.be.equal '<div c=""><span a="aa">a</span></div>'

      it 'should process class-* directives', ->
        r = render '<div class-c="b"><span class-a="a">a</span></div>',
          {a: false, b: true}
        expect(outerHTML(r)).to.be.equal '<div class="c"><span>a</span></div>'
