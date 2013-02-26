// Generated by CoffeeScript 1.5.0
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

define(function(require) {
  var $parseHTML, ActiveView, Compiler, Model, View, extend, _ref;
  extend = require('underscore').extend;
  Model = require('backbone').Model;
  _ref = require('backbone.viewdsl'), Compiler = _ref.Compiler, View = _ref.View, ActiveView = _ref.ActiveView, $parseHTML = _ref.$parseHTML;
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
    it('should compile text only template', function() {
      var c, r, t;
      c = new Compiler();
      t = c.compile($parseHTML('hello, world'));
      r = t.render();
      expect(t.$node.data('hasActions')).not.to.be.ok;
      return expect(outerHTML(r)).to.be.equal('hello, world');
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
  describe('ActiveView', function() {
    var render;
    render = function(t, s) {
      var MyView, v;
      MyView = (function(_super) {

        __extends(MyView, _super);

        function MyView() {
          MyView.__super__.constructor.apply(this, arguments);
        }

        MyView.prototype.template = t;

        return MyView;

      })(ActiveView);
      v = new MyView({
        model: new Backbone.Model()
      });
      v.model.set(s);
      v.render();
      return v;
    };
    it('should process and observe attr-* directives', function() {
      var v;
      v = render('<div attr-c="model.c" attr-b="bind:model.b"><span attr-a="model.a.a">a</span></div>', {
        a: {
          a: 'aa'
        },
        c: true,
        b: false
      });
      expect(v.$el.html()).to.be.equal('<div c=""><span a="aa">a</span></div>');
      v.model.set('b', true);
      expect(v.$el.html()).to.be.equal('<div c="" b=""><span a="aa">a</span></div>');
      v.model.set('b', 'bb');
      return expect(v.$el.html()).to.be.equal('<div c="" b="bb"><span a="aa">a</span></div>');
    });
    it('should process and observe class-* directives', function() {
      var v;
      v = render('<div class-c="model.b.b"><span class-a="bind:model.a">a</span></div>', {
        a: false,
        b: {
          b: true
        }
      });
      expect(v.$el.html()).to.be.equal('<div class="c"><span>a</span></div>');
      v.model.set('a', true);
      return expect(v.$el.html()).to.be.equal('<div class="c"><span class="a">a</span></div>');
    });
    it('should process show-if directive', function() {
      var v;
      v = render('<div><span show-if="bind:model.a">a</span></div>', {
        a: false
      });
      expect(v.$el.html()).to.be.equal('<div><span style="display: none;">a</span></div>');
      v.model.set('a', true);
      return expect(v.$el.html()).to.be.equal('<div><span style="display: inline;">a</span></div>');
    });
    return describe('interpolation', function() {
      it('should interpolate values', function() {
        var v;
        v = render('<div>Hello, {{model.name}}!</div>', {
          name: 'World'
        });
        return expect(v.$el.html()).to.be.equal('<div>Hello, World!</div>');
      });
      return it('should interpolate values and observe them', function() {
        var v;
        v = render('<div>Hello, {{bind:model.name}}!</div>', {
          name: 'World'
        });
        expect(v.$el.html()).to.be.equal('<div>Hello, World!</div>');
        v.model.set('name', 'Andrey');
        return expect(v.$el.html()).to.be.equal('<div>Hello, Andrey!</div>');
      });
    });
  });
  return describe('View', function() {
    var render;
    render = function(t, s) {
      var MyView, v;
      MyView = (function(_super) {

        __extends(MyView, _super);

        function MyView() {
          MyView.__super__.constructor.apply(this, arguments);
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
      v = render('<div attr-c="c" attr-b="b"><span attr-a="a.a">a</span></div>', {
        a: {
          a: 'aa'
        },
        c: true,
        b: false
      });
      return expect(v.$el.html()).to.be.equal('<div c=""><span a="aa">a</span></div>');
    });
    it('should process class-* directives', function() {
      var v;
      v = render('<div class-c="b.b"><span class-a="a">a</span></div>', {
        a: false,
        b: {
          b: true
        }
      });
      return expect(v.$el.html()).to.be.equal('<div class="c"><span>a</span></div>');
    });
    it('should process show-if directive', function() {
      var v;
      v = render('<div><span show-if="a">a</span></div>', {
        a: false
      });
      expect(v.$el.html()).to.be.equal('<div><span style="display: none;">a</span></div>');
      v = render('<div><span show-if="a">a</span></div>', {
        a: true
      });
      return expect(v.$el.html()).to.be.equal('<div><span style="display: inline;">a</span></div>');
    });
    describe('interpolation', function() {
      it('should interpolate string values', function() {
        var v;
        v = render('<div>Hello, {{name}}!</div>', {
          name: 'World'
        });
        return expect(v.$el.html()).to.be.equal('<div>Hello, World!</div>');
      });
      it('should interpolate DOM values', function() {
        var v;
        v = render('<div>Hello, {{name}}!</div>', {
          name: document.createTextNode('World')
        });
        return expect(v.$el.html()).to.be.equal('<div>Hello, World!</div>');
      });
      it('should interpolate jQuery values', function() {
        var v;
        v = render('<div>Hello, {{name}}!</div>', {
          name: $('<span>World</span>')
        });
        return expect(v.$el.html()).to.be.equal('<div>Hello, <span>World</span>!</div>');
      });
      return it('should interpolate nested values', function() {
        var v;
        v = render('<div>Hello, {{my.name}}!</div>', {
          my: {
            name: 'World'
          }
        });
        return expect(v.$el.html()).to.be.equal('<div>Hello, World!</div>');
      });
    });
    describe('view directive', function() {
      window.Hello = (function(_super) {

        __extends(Hello, _super);

        function Hello() {
          Hello.__super__.constructor.apply(this, arguments);
        }

        Hello.prototype.template = "<span>hello</span>";

        return Hello;

      })(View);
      window.Hello2 = (function(_super) {

        __extends(Hello2, _super);

        function Hello2() {
          Hello2.__super__.constructor.apply(this, arguments);
        }

        Hello2.parameterizable = true;

        Hello2.prototype.render = function($template) {
          var $wrap;
          $wrap = $(document.createElement('div'));
          $wrap.append(this.renderTemplate($template));
          return this.$el.append($wrap);
        };

        return Hello2;

      })(View);
      it('should instantiate view from view element', function() {
        var v;
        v = render('<div><view name="Hello" a="a" b="b" id="v"></view></div>', {
          a: 42
        });
        expect(v.$el.html()).to.be.equal('<div><div><span>hello</span></div></div>');
        expect(v.views.length).to.be.equal(1);
        expect(v.v instanceof window.Hello).to.be.ok;
        expect(v.v.options.a).to.be.equal(42);
        return expect(v.v.options.b).to.be.equal('b');
      });
      return it('should instantiate view from view attr', function() {
        var v;
        v = render('<div><div view-id="v" view="Hello" view-a="a" view-b="b"></view></div>', {
          a: 42
        });
        expect(v.$el.html()).to.be.equal('<div><div><span>hello</span></div></div>');
        expect(v.views.length).to.be.equal(1);
        expect(v.v instanceof window.Hello).to.be.ok;
        expect(v.v.options.a).to.be.equal(42);
        return expect(v.v.options.b).to.be.equal('b');
      });
    });
    return describe('view directive w/ parameterizable views', function() {
      it('should pass view innerHTML as arg to render() when rendered via elem', function() {
        var v;
        v = render('<view name="Hello2" id="v"><span>Hello</span></view>');
        return expect(v.$el.html()).to.be.equal('<div><div><span>Hello</span></div></div>');
      });
      it('should pass view innerHTML as arg to render() when rendered via elem', function() {
        var v;
        v = render('<div view="Hello2" view-id="v"><span>Hello</span></div>');
        return expect(v.$el.html()).to.be.equal('<div><div><span>Hello</span></div></div>');
      });
      return it('should handle context chaining', function() {
        var v;
        v = render('<view name="Hello2" b="c" id="v">{{a}} - {{options.b}}</view>', {
          a: 'parent',
          c: 'child'
        });
        return expect(v.$el.html()).to.be.equal('<div><div>parent - child</div></div>');
      });
    });
  });
});
