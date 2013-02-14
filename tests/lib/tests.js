// Generated by CoffeeScript 1.4.0

define(function(require) {
  var Compiler, outerHTML;
  Compiler = require('backbone.viewdsl2').Compiler;
  outerHTML = function($node) {
    return $('<div></div>').append($node).html();
  };
  return describe('Compiler', function() {
    it('should compile node w/o any directives', function() {
      var c, r, t;
      c = new Compiler();
      t = c.compile($('<div><span>a</span></div>'));
      r = t.render();
      expect(t.$node.data('hasActions')).not.to.be.ok;
      return expect(outerHTML(r)).to.be.equal('<div><span>a</span></div>');
    });
    it('should compile node w/ element directive', function() {
      var c, r, t;
      c = new Compiler();
      c.hello = function($node) {
        return function(scope, $node) {
          return $node.replaceWith($('<span>Hello, world</span>'));
        };
      };
      t = c.compile($('<div><hello></hello></div>'));
      r = t.render();
      expect(t.$node.data('hasActions')).to.be.ok;
      return expect(outerHTML(r)).to.be.equal('<div><span>Hello, world</span></div>');
    });
    it('should compile node w/ element directive', function() {
      var c, r, t;
      c = new Compiler();
      c.hello = function($node, name, value) {
        return function(scope, $node) {
          $node.html($("<span>" + value + "</span>"));
          return $node.removeAttr(name);
        };
      };
      t = c.compile($('<div><div hello="Huh?!"></div></div>'));
      r = t.render();
      expect(t.$node.data('hasActions')).to.be.ok;
      return expect(outerHTML(r)).to.be.equal('<div><div><span>Huh?!</span></div></div>');
    });
    return describe('built-in directives', function() {
      var render;
      render = function(t, s) {
        var c;
        c = new Compiler();
        t = c.compile($(t));
        return t.render(s);
      };
      it('should process attr-* directives', function() {
        var r;
        r = render('<div attr-c="c" attr-b="b"><span attr-a="a">a</span></div>', {
          a: 'aa',
          c: true,
          b: false
        });
        return expect(outerHTML(r)).to.be.equal('<div c=""><span a="aa">a</span></div>');
      });
      return it('should process class-* directives', function() {
        var r;
        r = render('<div class-c="b"><span class-a="a">a</span></div>', {
          a: false,
          b: true
        });
        return expect(outerHTML(r)).to.be.equal('<div class="c"><span>a</span></div>');
      });
    });
  });
});
