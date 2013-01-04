// Generated by CoffeeScript 1.4.0
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

define(function(require) {
  var View;
  View = require('backbone.viewdsl').View;
  window.SomeView = (function(_super) {

    __extends(SomeView, _super);

    function SomeView() {
      return SomeView.__super__.constructor.apply(this, arguments);
    }

    return SomeView;

  })(View);
  return describe('View', function() {
    describe('basic DOM rendering', function() {
      it('should construct a view from a text only template', function(done) {
        var promise;
        promise = View.from('Hello');
        return promise.then(function(view) {
          expect(view.el.tagName).to.be.equal(void 0);
          expect(view.$el.text()).to.be.equal('Hello');
          return done();
        }).end();
      });
      it('should construct a view from DOM template', function(done) {
        var promise;
        promise = View.from("<div class=\"some-class\">Hello</div>");
        return promise.then(function(view) {
          expect(view.el.tagName).to.be.equal('DIV');
          expect(view.$el.text()).to.be.equal('Hello');
          expect(view.$el.hasClass('some-class')).to.be.ok;
          return done();
        }).end();
      });
      it('should render text into view', function(done) {
        var MyView, view;
        MyView = (function(_super) {

          __extends(MyView, _super);

          function MyView() {
            return MyView.__super__.constructor.apply(this, arguments);
          }

          MyView.prototype.render = function() {
            return this.renderDOM('Hello');
          };

          return MyView;

        })(View);
        view = new MyView();
        return view.render().then(function() {
          expect(view.$el.length).to.be.equal(1);
          expect(view.$el.text()).to.be.equal('Hello');
          return done();
        }).end();
      });
      it('should render DOM into view', function(done) {
        var MyView, view;
        MyView = (function(_super) {

          __extends(MyView, _super);

          function MyView() {
            return MyView.__super__.constructor.apply(this, arguments);
          }

          MyView.prototype.render = function() {
            return this.renderDOM("<div class=\"some-class\">Hello</div>");
          };

          return MyView;

        })(View);
        view = new MyView();
        return view.render().then(function() {
          var el;
          expect(view.$el.length).to.be.equal(1);
          el = $(view.$el.children()[0]);
          expect(el[0].tagName).to.be.equal('DIV');
          expect(el.text()).to.be.equal('Hello');
          expect(el.hasClass('some-class')).to.be.ok;
          return done();
        }).end();
      });
      it('should render multiple DOM elements into view', function(done) {
        var MyView, view;
        MyView = (function(_super) {

          __extends(MyView, _super);

          function MyView() {
            return MyView.__super__.constructor.apply(this, arguments);
          }

          MyView.prototype.render = function() {
            return this.renderDOM("<div class=\"some-class\">Hello</div>\n<div class=\"another-class\">Hello2</div>");
          };

          return MyView;

        })(View);
        view = new MyView();
        return view.render().then(function() {
          expect(view.$el.children().length).to.be.equal(2);
          expect(view.$('.some-class').length).to.be.equal(1);
          expect(view.$('.another-class').length).to.be.equal(1);
          expect(view.$('.some-class').text()).to.be.equal('Hello');
          expect(view.$('.another-class').text()).to.be.equal('Hello2');
          return done();
        }).end();
      });
      return it('should throw an error if constructing view from multiple elements', function() {
        return expect(function() {
          return View.from('<div></div><div></div>');
        }).to["throw"](Error);
      });
    });
    describe('view instantiation', function() {
      it('should instantiate views by global spec', function(done) {
        var promise;
        promise = View.from("<div class=\"some-class\">\n  <div view=\"SomeView\">Some View</div>\n</div>");
        return promise.then(function(view) {
          var subview;
          expect(view.views.length).to.be.equal(1);
          expect(view instanceof View).to.be.ok;
          subview = view.views[0];
          expect(subview.el.tagName).to.be.equal('DIV');
          expect(subview.$el.text()).to.be.equal('Some View');
          expect(subview instanceof SomeView).to.be.ok;
          return done();
        }).end();
      });
      it('should instantiate views by AMD spec', function(done) {
        var LoadedView, promise;
        LoadedView = require('views').LoadedView;
        promise = View.from("<div class=\"some-class\">\n  <div view=\"views:LoadedView\"></div>\n</div>");
        return promise.then(function(view) {
          var subview;
          expect(view.views.length).to.be.equal(1);
          expect(view instanceof View).to.be.ok;
          subview = view.views[0];
          expect(subview.el.tagName).to.be.equal('DIV');
          expect(subview.$el.text()).to.be.equal('HI');
          expect(subview instanceof LoadedView).to.be.ok;
          return done();
        }).end();
      });
      return it('should instantiate view by global spec inside other view', function(done) {
        var MyView, view;
        MyView = (function(_super) {

          __extends(MyView, _super);

          function MyView() {
            return MyView.__super__.constructor.apply(this, arguments);
          }

          MyView.prototype.initialize = function() {
            return this.propParam = 'prop!';
          };

          MyView.prototype.methodParam = function() {
            return this.constructor.name;
          };

          MyView.prototype.render = function() {
            return this.renderDOM("<div class=\"some-class\">\n  <div\n    view=\"SomeView\"\n    view-some-param=\"methodParam\"\n    view-another-param=\"propParam\"\n    view-absent-param=\"some string\"\n    >Some View</div>\n</div>");
          };

          return MyView;

        })(View);
        view = new MyView();
        return view.render().then(function() {
          var subview;
          expect(view.views.length).to.be.equal(1);
          expect(view instanceof View).to.be.ok;
          subview = view.views[0];
          expect(subview.el.tagName).to.be.equal('DIV');
          expect(subview.$el.text()).to.be.equal('Some View');
          expect(subview instanceof SomeView).to.be.ok;
          expect(subview.options.someParam).to.be.equal('MyView');
          expect(subview.options.anotherParam).to.be.equal('prop!');
          expect(subview.options.absentParam).to.be.equal('some string');
          return done();
        }).end();
      });
    });
    describe('conditional blocks', function() {
      it('should conditionally render by view property', function(done) {
        var MyView, view;
        MyView = (function(_super) {

          __extends(MyView, _super);

          function MyView() {
            return MyView.__super__.constructor.apply(this, arguments);
          }

          MyView.prototype.initialize = function(options) {
            this.show1 = options.show1;
            return this.show2 = options.show2;
          };

          MyView.prototype.render = function() {
            return this.renderDOM("<div>\n  <div if=\"show1\" class=\"show1\"></div>\n  <div if=\"show2\" class=\"show2\"></div>\n</div>");
          };

          return MyView;

        })(View);
        view = new MyView({
          show1: true,
          show2: false
        });
        return view.render().then(function() {
          expect(view.$('.show1').length).to.be.equal(1);
          expect(view.$('.show2').length).to.be.equal(0);
          return done();
        }).end();
      });
      it('should conditionally render by view property by path', function(done) {
        var MyView, view;
        MyView = (function(_super) {

          __extends(MyView, _super);

          function MyView() {
            return MyView.__super__.constructor.apply(this, arguments);
          }

          MyView.prototype.initialize = function(options) {
            return this.obj = {
              show1: options.show1,
              show2: options.show2
            };
          };

          MyView.prototype.render = function() {
            return this.renderDOM("<div>\n  <div if=\"obj.show1\" class=\"show1\"></div>\n  <div if=\"obj.show2\" class=\"show2\"></div>\n</div>");
          };

          return MyView;

        })(View);
        view = new MyView({
          show1: true,
          show2: false
        });
        return view.render().then(function() {
          expect(view.$('.show1').length).to.be.equal(1);
          expect(view.$('.show2').length).to.be.equal(0);
          return done();
        }).end();
      });
      it('should conditionally render by view function', function(done) {
        var MyView, view;
        MyView = (function(_super) {

          __extends(MyView, _super);

          function MyView() {
            return MyView.__super__.constructor.apply(this, arguments);
          }

          MyView.prototype.initialize = function(options) {
            this._show1 = options.show1;
            return this._show2 = options.show2;
          };

          MyView.prototype.show1 = function() {
            return this._show1;
          };

          MyView.prototype.show2 = function() {
            return this._show2;
          };

          MyView.prototype.render = function() {
            return this.renderDOM("<div>\n  <div if=\"show1\" class=\"show1\"></div>\n  <div if=\"show2\" class=\"show2\"></div>\n</div>");
          };

          return MyView;

        })(View);
        view = new MyView({
          show1: true,
          show2: false
        });
        return view.render().then(function() {
          expect(view.$('.show1').length).to.be.equal(1);
          expect(view.$('.show2').length).to.be.equal(0);
          return done();
        }).end();
      });
      return it('should conditionally render by view function by path', function(done) {
        var MyClass, MyView, view;
        MyClass = (function() {

          function MyClass() {}

          MyClass.prototype.show1 = function() {
            return this._show1;
          };

          MyClass.prototype.show2 = function() {
            return this._show2;
          };

          return MyClass;

        })();
        MyView = (function(_super) {

          __extends(MyView, _super);

          function MyView() {
            return MyView.__super__.constructor.apply(this, arguments);
          }

          MyView.prototype.initialize = function(options) {
            this.obj = new MyClass;
            this.obj.show1 = options.show1;
            return this.obj.show2 = options.show2;
          };

          MyView.prototype.render = function() {
            return this.renderDOM("<div>\n  <div if=\"obj.show1\" class=\"show1\"></div>\n  <div if=\"obj.show2\" class=\"show2\"></div>\n</div>");
          };

          return MyView;

        })(View);
        view = new MyView({
          show1: true,
          show2: false
        });
        return view.render().then(function() {
          expect(view.$('.show1').length).to.be.equal(1);
          expect(view.$('.show2').length).to.be.equal(0);
          return done();
        }).end();
      });
    });
    return describe('text node interpolation', function() {
      it('should interpolate strings in basic text template', function(done) {
        var MyView, view;
        MyView = (function(_super) {

          __extends(MyView, _super);

          function MyView() {
            return MyView.__super__.constructor.apply(this, arguments);
          }

          MyView.prototype.initialize = function(options) {
            return this.name = options.name;
          };

          MyView.prototype.render = function() {
            return this.renderDOM("Hello, {{name}}!");
          };

          return MyView;

        })(View);
        view = new MyView({
          name: 'World'
        });
        return view.render().then(function() {
          expect(view.$el.text()).to.be.equal('Hello, World!');
          return done();
        }).end();
      });
      it('should interpolate missing values to empty string', function(done) {
        var MyView, view;
        MyView = (function(_super) {

          __extends(MyView, _super);

          function MyView() {
            return MyView.__super__.constructor.apply(this, arguments);
          }

          MyView.prototype.render = function() {
            return this.renderDOM("Hello, {{name}}!");
          };

          return MyView;

        })(View);
        view = new MyView({
          name: 'World'
        });
        return view.render().then(function() {
          expect(view.$el.text()).to.be.equal('Hello, !');
          return done();
        }).end();
      });
      it('should interpolate values from local context', function(done) {
        var MyView, view;
        MyView = (function(_super) {

          __extends(MyView, _super);

          function MyView() {
            return MyView.__super__.constructor.apply(this, arguments);
          }

          MyView.prototype.initialize = function(options) {
            return this.name = options.name;
          };

          MyView.prototype.render = function() {
            return this.renderDOM("Hello, {{name}}{{greetingEnd}}", {
              greetingEnd: '!!!'
            });
          };

          return MyView;

        })(View);
        view = new MyView({
          name: 'World'
        });
        return view.render().then(function() {
          expect(view.$el.text()).to.be.equal('Hello, World!!!');
          return done();
        }).end();
      });
      it('should interpolate strings in HTML template', function(done) {
        var MyView, view;
        MyView = (function(_super) {

          __extends(MyView, _super);

          function MyView() {
            return MyView.__super__.constructor.apply(this, arguments);
          }

          MyView.prototype.initialize = function(options) {
            return this.name = options.name;
          };

          MyView.prototype.render = function() {
            return this.renderDOM("<div>\n  Hello, <span class=\"name\">{{name}}</span>!\n</div>");
          };

          return MyView;

        })(View);
        view = new MyView({
          name: 'World'
        });
        return view.render().then(function() {
          expect(view.$('span.name').text()).to.be.equal('World');
          return done();
        }).end();
      });
      it('should interpolate strings using a function call', function(done) {
        var MyView, view;
        MyView = (function(_super) {

          __extends(MyView, _super);

          function MyView() {
            return MyView.__super__.constructor.apply(this, arguments);
          }

          MyView.prototype.name = function() {
            return this.constructor.name;
          };

          MyView.prototype.render = function() {
            return this.renderDOM("<div>\n  Hello, <span class=\"name\">{{name}}</span>!\n</div>");
          };

          return MyView;

        })(View);
        view = new MyView();
        return view.render().then(function() {
          expect(view.$('span.name').text()).to.be.equal('MyView');
          return done();
        }).end();
      });
      it('should interpolate jQuery objects', function(done) {
        var MyView, view;
        MyView = (function(_super) {

          __extends(MyView, _super);

          function MyView() {
            return MyView.__super__.constructor.apply(this, arguments);
          }

          MyView.prototype.name = function() {
            return $('<span class="inner-name">World</span>');
          };

          MyView.prototype.render = function() {
            return this.renderDOM("<div>\n  Hello, <span class=\"name\">{{name}}</span>!\n</div>");
          };

          return MyView;

        })(View);
        view = new MyView();
        return view.render().then(function() {
          expect(view.$('span.inner-name').text()).to.be.equal('World');
          return done();
        }).end();
      });
      it('should interpolate DOM nodes', function(done) {
        var MyView, view;
        MyView = (function(_super) {

          __extends(MyView, _super);

          function MyView() {
            return MyView.__super__.constructor.apply(this, arguments);
          }

          MyView.prototype.name = function() {
            return $('<span class="inner-name">World</span>')[0];
          };

          MyView.prototype.render = function() {
            return this.renderDOM("<div>\n  Hello, <span class=\"name\">{{name}}</span>!\n</div>");
          };

          return MyView;

        })(View);
        view = new MyView();
        return view.render().then(function() {
          expect(view.$('span.inner-name').text()).to.be.equal('World');
          return done();
        }).end();
      });
      it('should interpolate strings by path', function(done) {
        var MyView, view;
        MyView = (function(_super) {

          __extends(MyView, _super);

          function MyView() {
            return MyView.__super__.constructor.apply(this, arguments);
          }

          MyView.prototype.initialize = function(options) {
            return this.obj = {
              name: 'World'
            };
          };

          MyView.prototype.render = function() {
            return this.renderDOM("Hello, {{obj.name}}!");
          };

          return MyView;

        })(View);
        view = new MyView({
          name: 'World'
        });
        return view.render().then(function() {
          expect(view.$el.text()).to.be.equal('Hello, World!');
          return done();
        }).end();
      });
      return it('should interpolate strings using a function call by path', function(done) {
        var MyClass, MyView, view;
        MyClass = (function() {

          function MyClass() {}

          MyClass.prototype.name = function() {
            return this.constructor.name;
          };

          return MyClass;

        })();
        MyView = (function(_super) {

          __extends(MyView, _super);

          function MyView() {
            return MyView.__super__.constructor.apply(this, arguments);
          }

          MyView.prototype.initialize = function() {
            return this.obj = new MyClass();
          };

          MyView.prototype.render = function() {
            return this.renderDOM("<div>\n  Hello, <span class=\"name\">{{obj.name}}</span>!\n</div>");
          };

          return MyView;

        })(View);
        view = new MyView();
        return view.render().then(function() {
          expect(view.$('span.name').text()).to.be.equal('MyClass');
          return done();
        }).end();
      });
    });
  });
});