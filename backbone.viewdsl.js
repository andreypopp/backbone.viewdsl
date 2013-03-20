// Generated by CoffeeScript 1.6.2
/*

  Backbone.ViewDSL

  2013 (c) Andrey Popp <8mayday@gmail.com>
*/

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

(function(root, factory) {
  var Backbone, _;

  if (typeof exports === 'object') {
    _ = require('underscore');
    Backbone = require('backbone');
    return module.exports = factory(_, Backbone, require);
  } else if (typeof define === 'function' && define.amd) {
    return define(function(require) {
      _ = require('underscore');
      Backbone = require('backbone');
      return root.Backbone.ViewDSL = factory(_, Backbone, require);
    });
  } else {
    return root.Backbone.ViewDSL = factory(root._, root.Backbone);
  }
})(this, function(_, Backbone, require) {
  var $fromArray, $isEmpty, $nodify, $parseHTML, CollectionView, Compiler, Directives, Template, View, contains, delegateEventSplitter, domProperties, every, extend, hypensToCamelCase, isBoolean, isEqual, isString, knownAttrs, knownTags, resolvePath, resolveSpec, some, textNodeSplitRe, toArray;

  some = _.some, every = _.every, extend = _.extend, toArray = _.toArray, isEqual = _.isEqual, isBoolean = _.isBoolean, isString = _.isString, contains = _.contains;
  resolvePath = function(o, p) {
    var n, _i, _len, _ref;

    p = p.trim();
    if (p.trim().length === 0) {
      return o;
    }
    _ref = p.split('.');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      n = _ref[_i];
      o = o[n];
      if (o === void 0) {
        break;
      }
    }
    return o;
  };
  resolveSpec = function(spec, ctx) {
    var mod, name, _ref;

    if (/:/.test(spec)) {
      if (require == null) {
        throw new Error('not a CommonJS environment');
      }
      _ref = spec.split(':', 2), mod = _ref[0], name = _ref[1];
      return resolvePath(require(mod), name);
    } else if (/^this\./.test(spec)) {
      return resolvePath(ctx, spec.substring(5));
    } else if (/^@/.test(spec)) {
      return resolvePath(ctx, spec.substring(1));
    } else {
      return resolvePath(window, spec);
    }
  };
  hypensToCamelCase = function(o) {
    return o.replace(/-([a-z])/g, function(g) {
      return g[1].toUpperCase();
    });
  };
  knownTags = /^(DIV|SPAN|BODY|HTML|HEAD|SECTION|HEADER|H1|H2|H3|H4|H5|H6|EM|TR|TD|THEAD|TBODY|TABLE|INPUT|TEXTAREA|EMBED|FONT|DD|DT|DL|FORM|A|B|BIG|BR|HR|I|UL|LI|OL|META|OPTION|SELECT|SMALL|STRONG|TITLE|TT|U)$/;
  knownAttrs = /^(class|enabled|id)$/;
  textNodeSplitRe = /({{)|(}})/;
  $fromArray = function(nodes) {
    var node, o, _i, _len;

    if (nodes === null) {
      nodes = [$(document.createTextNode(''))];
    }
    o = $(document.createDocumentFragment());
    for (_i = 0, _len = nodes.length; _i < _len; _i++) {
      node = nodes[_i];
      o.append(node);
    }
    return o.contents();
  };
  $parseHTML = function(nodes) {
    if (isString(nodes)) {
      return $fromArray($.parseHTML(nodes));
    } else {
      return nodes;
    }
  };
  $nodify = function(o) {
    if (isString(o)) {
      return $parseHTML(o);
    } else if (o.jquery != null) {
      return o;
    } else if (o.nodeType != null) {
      return $(o);
    } else {
      return $(document.createTextNode(String(o)));
    }
  };
  $isEmpty = function(n) {
    if (n == null) {
      return true;
    }
    if (isString(n)) {
      return n.trim() === '';
    } else if (n.jquery != null) {
      return n.size() === 0 || every(n, function(n) {
        return n.nodeType === Node.TEXT_NODE && n.data.trim() === '';
      });
    } else if (n.nodeType != null) {
      return false;
    }
  };
  /*
    HTML compiler
  */

  Compiler = (function() {
    function Compiler(directives) {
      if (directives == null) {
        directives = {};
      }
      this.directives = directives;
    }

    Compiler.prototype.compile = function($node) {
      var $wrap;

      $wrap = $(document.createElement('div'));
      $wrap.append($node);
      this.compileImpl($wrap);
      return new Template($wrap);
    };

    Compiler.prototype.directiveFor = function(name) {
      var directive;

      if (name.slice(0, 5) === 'attr-') {
        name = 'attr';
      }
      if (name.slice(0, 6) === 'class-') {
        name = 'class';
      }
      directive = this.directives[hypensToCamelCase("compile-" + name)];
      return directive != null ? directive.bind(this.directives) : void 0;
    };

    Compiler.prototype.compileImpl = function($node) {
      var node;

      node = $node[0];
      if (node.nodeType === Node.TEXT_NODE) {
        return this.compileTextNode($node);
      } else {
        return this.compileNode($node);
      }
    };

    Compiler.prototype.compileTextNode = function($node) {
      var $part, action, data, nodes, part, parts, path;

      data = $node.text();
      if (!textNodeSplitRe.test(data)) {
        return false;
      }
      data = data.replace(/{{/g, '{{\uF001');
      parts = data.split(textNodeSplitRe);
      parts = parts.filter(function(e) {
        return e && e !== '{{' && e !== '}}';
      });
      nodes = (function() {
        var _i, _len, _results;

        _results = [];
        for (_i = 0, _len = parts.length; _i < _len; _i++) {
          part = parts[_i];
          if (part[0] === '\uF001') {
            path = part.slice(1).trim();
            $part = $(document.createElement('span'));
            action = this.directives.compileInterpolation($part, path);
            $part.data('hasActions', true);
            $part.data('actions', [action]);
            _results.push($part);
          } else {
            _results.push($(document.createTextNode(part)));
          }
        }
        return _results;
      }).call(this);
      $node.replaceWith($fromArray(nodes));
      return true;
    };

    Compiler.prototype.compileNode = function($node) {
      var actions, attr, attrActions, child, directive, hasActions, hasChildActions, node;

      node = $node[0];
      if (!knownTags.test(node.tagName)) {
        directive = this.directiveFor(node.tagName.toLowerCase());
      } else {
        directive = void 0;
      }
      actions = directive ? [directive($node)] : [];
      attrActions = (function() {
        var _i, _len, _ref, _results;

        _ref = toArray(node.attributes);
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          attr = _ref[_i];
          if (knownAttrs.test(attr.name)) {
            continue;
          }
          directive = this.directiveFor(attr.name);
          if (!directive) {
            continue;
          }
          _results.push(directive($node, attr.name, attr.value));
        }
        return _results;
      }).call(this);
      actions = actions.concat(attrActions);
      hasChildActions = node.childNodes.length > 0 && some((function() {
        var _i, _len, _ref, _results;

        _ref = toArray(node.childNodes);
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          child = _ref[_i];
          _results.push(this.compileImpl($(child)));
        }
        return _results;
      }).call(this));
      hasActions = actions.length > 0 || hasChildActions;
      if (actions.length > 0) {
        $node.data('actions', actions);
      }
      $node.data('hasActions', hasActions);
      return hasActions;
    };

    return Compiler;

  })();
  /*
    Template object
  */

  Template = (function() {
    function Template($node) {
      this.$node = $node;
    }

    Template.prototype.render = function(scope) {
      var $rendered;

      if (scope == null) {
        scope = {};
      }
      $rendered = this.$node.clone(true, true);
      this.renderImpl(scope, $rendered);
      return $rendered.contents();
    };

    Template.prototype.renderImpl = function(scope, $node) {
      var action, actions, child, _i, _j, _len, _len1, _ref;

      if (!$node.data('hasActions')) {
        return $node;
      }
      actions = $node.data('actions');
      if (actions) {
        for (_i = 0, _len = actions.length; _i < _len; _i++) {
          action = actions[_i];
          action(scope, $node);
        }
      }
      _ref = toArray($node[0].childNodes);
      for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
        child = _ref[_j];
        this.renderImpl(scope, $(child));
      }
      return $node;
    };

    return Template;

  })();
  domProperties = ['value', 'disabled', 'selected'];
  Directives = {
    compileInterpolation: function($node, value) {
      var observe;

      observe = false;
      if (value.substring(0, 5) === 'bind:') {
        value = value.substring(5);
        observe = true;
      }
      return function(scope, $node) {
        var $point;

        $point = $node;
        return scope.reactOn(value, {
          observe: observe,
          react: function(got) {
            got = $nodify(got !== void 0 ? got : '');
            $point.first().replaceWith(got);
            $point.detach();
            return $point = got;
          }
        });
      };
    },
    compileElementId: function($node, name, value) {
      $node.removeAttr(name);
      return function(scope, $node) {
        return scope[value] = $node;
      };
    },
    compileAttr: function($node, name, value) {
      var attr, attrName, isProp, observe, removeAttr, _ref;

      observe = false;
      if (value.substring(0, 5) === 'bind:') {
        value = value.substring(5);
        observe = true;
      }
      attrName = name.substring(5);
      $node.removeAttr(name);
      isProp = contains(domProperties, attrName);
      _ref = isProp ? {
        attr: 'prop',
        removeAttr: 'removeProp'
      } : {
        attr: 'attr',
        removeAttr: 'removeAttr'
      }, attr = _ref.attr, removeAttr = _ref.removeAttr;
      return function(scope, $node) {
        return scope.reactOn(value, {
          observe: observe,
          react: function(got) {
            if (isBoolean(got)) {
              if (got) {
                return $node[attr](attrName, '');
              } else {
                if (isProp) {
                  if (contains(['disabled', 'selected'], attrName)) {
                    return $node.prop(attrName, false);
                  } else if (attrName === 'value') {
                    return $node.prop(attrName, '');
                  } else {
                    return $node[removeAttr](attrName);
                  }
                } else {
                  return $node[removeAttr](attrName);
                }
              }
            } else {
              return $node[attr](attrName, got);
            }
          }
        });
      };
    },
    compileClass: function($node, name, value) {
      var className, observe;

      observe = false;
      if (value.substring(0, 5) === 'bind:') {
        value = value.substring(5);
        observe = true;
      }
      className = name.slice(6);
      $node.removeAttr(name);
      return function(scope, $node) {
        return scope.reactOn(value, {
          observe: observe,
          react: function(got) {
            if (got) {
              return $node.addClass(className);
            } else {
              return $node.removeClass(className);
            }
          }
        });
      };
    },
    compileShowIf: function($node, name, value) {
      var observe;

      observe = false;
      if (value.substring(0, 5) === 'bind:') {
        value = value.substring(5);
        observe = true;
      }
      $node.removeAttr(name);
      return function(scope, $node) {
        return scope.reactOn(value, {
          observe: observe,
          react: function(got) {
            if (got) {
              return $node.show();
            } else {
              return $node.hide();
            }
          }
        });
      };
    },
    compileForeach: function($node, name, value) {
      return this.viewDirective(CollectionView, $node, name, value);
    },
    compileView: function($node, name, value) {
      var spec, viewClass;

      viewClass = (function() {
        if (name == null) {
          spec = $node.attr('name');
          $node.removeAttr('name');
          if (!spec) {
            throw new Error("provide view attr");
          }
          return resolveSpec(spec, this);
        } else {
          $node.removeAttr(name);
          return resolveSpec(value, this);
        }
      }).call(this);
      return this.viewDirective(viewClass, $node, name, value);
    },
    viewDirective: function(viewClass, $node, name, value) {
      var className, element, node, template, viewId, viewIdAttr;

      node = $node[0];
      element = name == null;
      viewIdAttr = element ? 'id' : 'view-id';
      viewId = $node.attr(viewIdAttr);
      $node.removeAttr(viewIdAttr);
      template = element || viewClass.parameterizable ? $node.contents().detach() : void 0;
      className = element && $node.attr('class') ? $node.attr('class') : void 0;
      return function(scope, $node) {
        var a, attrName, attrValue, view, viewParams, _i, _len, _ref;

        viewParams = {};
        _ref = toArray(node.attributes);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          a = _ref[_i];
          if (!element && a.name.slice(0, 5) !== 'view-') {
            continue;
          }
          attrName = element ? a.name : a.name.slice(5);
          attrName = hypensToCamelCase(attrName);
          attrValue = scope.get(a.value);
          viewParams[attrName] = attrValue !== void 0 ? attrValue : a.value;
          if (!element) {
            $node.removeAttr(a.name);
          }
        }
        viewParams.parent = scope;
        if (!element) {
          viewParams.el = $node;
        }
        view = new viewClass(viewParams);
        view.render(template);
        if (className) {
          view.$el.addClass(className);
        }
        if (element) {
          $node.replaceWith(view.$el);
        }
        return scope.addView(view, viewId);
      };
    }
  };
  View = (function(_super) {
    __extends(View, _super);

    View.extend = function() {
      var mixins;

      mixins = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return extend.apply(null, [this].concat(__slice.call(mixins)));
    };

    View.include = function() {
      var mixins;

      mixins = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return extend.apply(null, [this.prototype].concat(__slice.call(mixins)));
    };

    View.extend(Directives);

    View.parameterizable = false;

    View.prototype.template = void 0;

    function View(options) {
      if (options == null) {
        options = {};
      }
      if (options.template != null) {
        this.template = options.template;
      }
      this.parent = options.parent;
      this.views = [];
      this.compiler = new Compiler(this.constructor);
      if (options.model != null) {
        this.listenTo(options.model, 'change');
      }
      if (options.collection != null) {
        this.listenTo(options.collection, 'change add remove reset sort');
      }
      this.digestScheduled = false;
      this.observe = {};
      View.__super__.constructor.apply(this, arguments);
    }

    View.prototype.renderTemplate = function(template) {
      if (!(template instanceof Template)) {
        template = this.compiler.compile($parseHTML(template));
      }
      return template.render(this);
    };

    View.prototype.render = function() {
      if (!this.template) {
        throw new Error("undefined template");
      }
      if (!(this.template instanceof Template)) {
        this.template = this.compiler.compile($parseHTML(this.template));
      }
      return this.$el.append(this.template.render(this));
    };

    View.prototype.remove = function() {
      View.__super__.remove.apply(this, arguments);
      this.removeViews();
      this.parent = void 0;
      this.observe = void 0;
      return this.views = [];
    };

    View.prototype.removeViews = function() {
      var view, _i, _len, _ref, _results;

      _ref = this.views;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        view = _ref[_i];
        _results.push(view.remove());
      }
      return _results;
    };

    View.prototype.addView = function(view, id) {
      this.views.push(view);
      if (id) {
        return this[id] = view;
      }
    };

    View.prototype.get = function(p, options) {
      var own, _ref;

      own = this.getOwn(p, options);
      if (own !== void 0) {
        return own;
      }
      return (_ref = this.parent) != null ? _ref.get(p, options) : void 0;
    };

    View.prototype.getOwn = function(p, options) {
      var ctx, n, o, _i, _len, _ref;

      p = p.trim();
      o = this;
      if (p.trim().length === 0) {
        return o;
      }
      _ref = p.split('.');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        n = _ref[_i];
        ctx = o;
        o = ctx instanceof Backbone.Model ? (o = ctx.get(n), o === void 0 ? o = ctx[n] : void 0, o) : ctx[n];
        if (o === void 0) {
          break;
        }
        if (jQuery.isFunction(o)) {
          o = o.call(ctx);
        }
      }
      return o;
    };

    View.prototype.reactOn = function(p, options) {
      var value;

      value = this.get(p);
      if (options != null ? options.observe : void 0) {
        this.observe[p] = value;
      }
      if (options != null ? options.react : void 0) {
        options.react(value);
        if (options.observe) {
          return this.listenTo(this, "change:" + p, options.react);
        }
      }
    };

    View.prototype.listenTo = function(obj, name, cb) {
      var k, v;

      if (typeof name === 'object') {
        for (k in name) {
          v = name[k];
          name[k] = this.mutating(v);
        }
        return View.__super__.listenTo.call(this, obj, name);
      } else {
        return View.__super__.listenTo.call(this, obj, name, this.mutating(cb || function() {}));
      }
    };

    View.prototype.digest = function() {
      if (!this.digestScheduled) {
        this.startDigest();
        return this.completeDigest();
      }
    };

    View.prototype.startDigest = function() {
      return this.digestScheduled = true;
    };

    View.prototype.completeDigest = function() {
      var newValue, path, updates, value, _ref, _results;

      try {
        updates = {};
        _ref = this.observe;
        for (path in _ref) {
          value = _ref[path];
          newValue = this.get(path);
          if (!isEqual(newValue, value)) {
            updates[path] = newValue;
          }
        }
        extend(this.observe, updates);
        _results = [];
        for (path in updates) {
          value = updates[path];
          _results.push(this.trigger("change:" + path, value));
        }
        return _results;
      } finally {
        this.digestScheduled = false;
      }
    };

    View.mutating = function(f) {
      return function() {
        if (!this.digestScheduled) {
          this.startDigest();
          try {
            return f.apply(this, arguments);
          } finally {
            this.completeDigest();
          }
        } else {
          return f.apply(this, arguments);
        }
      };
    };

    View.prototype.mutating = function(f) {
      var _this = this;

      return function() {
        if (!_this.digestScheduled) {
          _this.startDigest();
          try {
            return f.apply(_this, arguments);
          } finally {
            _this.completeDigest();
          }
        } else {
          return f.apply(_this, arguments);
        }
      };
    };

    return View;

  })(Backbone.View);
  delegateEventSplitter = /^(\S+)\s*(.*)$/;
  CollectionView = (function(_super) {
    __extends(CollectionView, _super);

    CollectionView.parameterizable = true;

    CollectionView.prototype.template = void 0;

    CollectionView.prototype.itemView = void 0;

    CollectionView.prototype.makeItemView = void 0;

    function CollectionView() {
      CollectionView.__super__.constructor.apply(this, arguments);
      this.listenTo(this.collection, {
        reset: this.onReset,
        sort: this.onSort,
        add: this.onAdd,
        remove: this.onRemove
      });
    }

    CollectionView.prototype.render = function(template) {
      this.setupItemView(template);
      this.onReset();
      return this;
    };

    CollectionView.prototype.setupItemView = function(maybeTemplate) {
      if (!$isEmpty(maybeTemplate)) {
        this.template = maybeTemplate;
      }
      if (this.template != null) {
        this.template = $nodify(this.template);
      }
      if (this.options.itemView != null) {
        this.itemView = this.options.itemView;
      }
      if ((this.itemView != null) && isString(this.itemView)) {
        this.itemView = resolveSpec(this.itemView, this);
      }
      return this.makeItemView = (function() {
        var _this = this;

        if (this.itemView != null) {
          return function(model, index) {
            var view;

            view = new _this.itemView({
              model: model,
              index: index,
              parent: _this
            });
            view.render();
            return view;
          };
        } else if (this.template) {
          return function(model, index) {
            var view;

            view = new View({
              template: _this.template.clone(true, true),
              parent: _this,
              model: model,
              index: index
            });
            view.render();
            return view;
          };
        } else {
          throw new Error("provide either 'template' or 'itemView' attr");
        }
      }).call(this);
    };

    CollectionView.prototype.viewByModel = function(model) {
      var idx, view, _i, _len, _ref;

      _ref = this.views;
      for (idx = _i = 0, _len = _ref.length; _i < _len; idx = ++_i) {
        view = _ref[idx];
        if (view.model.cid === model.cid) {
          return {
            view: view,
            idx: idx
          };
        }
      }
      return {
        view: void 0,
        idx: void 0
      };
    };

    CollectionView.prototype.onReset = function() {
      var _this = this;

      this.removeViews();
      return this.collection.forEach(function(model) {
        var view;

        view = _this.makeItemView(model, function() {
          return _this.collection.indexOf(model);
        });
        _this.$el.append(view.$el);
        return _this.views.push(view);
      });
    };

    CollectionView.prototype.onSort = function() {
      var $cur,
        _this = this;

      $cur = void 0;
      return this.collection.forEach(function(model, newIdx) {
        var idx, view, _ref;

        _ref = _this.viewByModel(model), view = _ref.view, idx = _ref.idx;
        _this.views.splice(idx, 1)[0];
        _this.views.splice(newIdx, view);
        view.options.index = newIdx;
        view.$el.detach();
        view.digest();
        if (!$cur) {
          return _this.$el.append(view.$el);
        } else {
          view.$el.after($cur);
          return $cur = view.$el;
        }
      });
    };

    CollectionView.prototype.onAdd = function(model) {
      var idx, view, _i, _len, _ref, _results,
        _this = this;

      idx = this.collection.indexOf(model);
      view = this.makeItemView(model, function() {
        return _this.collection.indexOf(model);
      });
      if (idx >= this.$el.children().size()) {
        this.$el.append(view.$el);
        return this.views.push(view);
      } else {
        this.$el.children().eq(idx).before(view.$el);
        this.views.splice(idx, 0, view);
        _ref = this.views.slice(idx);
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          view = _ref[_i];
          if ((view != null ? view.digest : void 0) != null) {
            _results.push(view.digest());
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      }
    };

    CollectionView.prototype.onRemove = function(model) {
      var idx, view, _i, _len, _ref, _ref1, _results;

      _ref = this.viewByModel(model), view = _ref.view, idx = _ref.idx;
      if (view) {
        view.remove();
        this.views.splice(idx, 1);
        _ref1 = this.views.slice(idx);
        _results = [];
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          view = _ref1[_i];
          if ((view != null ? view.digest : void 0) != null) {
            _results.push(view.digest());
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      }
    };

    return CollectionView;

  })(View);
  return {
    Compiler: Compiler,
    Template: Template,
    View: View,
    CollectionView: CollectionView,
    $parseHTML: $parseHTML
  };
});
