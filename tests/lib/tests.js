// Generated by CoffeeScript 1.4.0
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

define(function(require) {
  var Compiler, View, extend, _ref;
  extend = require('underscore').extend;
  _ref = require('backbone.viewdsl2'), Compiler = _ref.Compiler, View = _ref.View;
  describe('Compiler', function() {
    var outerHTML;
    outerHTML = function($node) {
      return $('<div></div>').append($node).html();
    };
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
      c.directives.compileHello = function($node) {
        return function(scope, $node) {
          return $node.replaceWith($('<span>Hello, world</span>'));
        };
      };
      t = c.compile($('<div><hello></hello></div>'));
      r = t.render();
      expect(t.$node.data('hasActions')).to.be.ok;
      return expect(outerHTML(r)).to.be.equal('<div><span>Hello, world</span></div>');
    });
    return it('should compile node w/ element directive', function() {
      var c, r, t;
      c = new Compiler();
      c.directives.compileHello = function($node, name, value) {
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
  });
  return describe('View', function() {
    var render;
    render = function(t, s) {
      var MyView, v;
      MyView = (function(_super) {

        __extends(MyView, _super);

        function MyView() {
          return MyView.__super__.constructor.apply(this, arguments);
        }

        MyView.prototype.template = t;

        return MyView;

      })(View);
      v = new MyView();
      extend(v, s);
      v.render();
      return v;
    };
    it('should compile and render template', function() {
      var v;
      v = render('<div></div>');
      return expect(v.$el.html()).to.be.equal('<div></div>');
    });
    it('should process attr-* directives', function() {
      var v;
      v = render('<div attr-c="c" attr-b="b"><span attr-a="a">a</span></div>', {
        a: 'aa',
        c: true,
        b: false
      });
      return expect(v.$el.html()).to.be.equal('<div c=""><span a="aa">a</span></div>');
    });
    return it('should process class-* directives', function() {
      var v;
      v = render('<div class-c="b"><span class-a="a">a</span></div>', {
        a: false,
        b: true
      });
      return expect(v.$el.html()).to.be.equal('<div class="c"><span>a</span></div>');
    });
  });
});
