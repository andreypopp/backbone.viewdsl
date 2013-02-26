// Generated by CoffeeScript 1.5.0
/*

  Backbone.ViewDSL

  2013 (c) Andrey Popp <8mayday@gmail.com>
*/

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

(function(root, factory) {
  if (typeof exports === 'object') {
    return module.exports = factory(require('underscore'), require('backbone'));
  } else if (typeof define === 'function' && define.amd) {
    return define(['underscore', 'backbone'], function(_, Backbone) {
      return root.Backbone.ViewDSL = factory(_, Backbone);
    });
  } else {
    return root.Backbone.ViewDSL = factory(root._, root.Backbone);
  }
})(this, function(_, Backbone) {
  var $fromArray, $parseHTML, ActiveView, Compiler, Template, View, extend, hypensToCamelCase, isBoolean, isEqual, isString, knownAttrs, knownTags, resolvePath, resolveSpec, some, textNodeSplitRe, toArray;
  some = _.some, extend = _.extend, toArray = _.toArray, isEqual = _.isEqual, isBoolean = _.isBoolean, isString = _.isString;
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
  resolveSpec = function(spec) {
    var mod, name, _ref;
    if (/:/.test(spec)) {
      _ref = spec.split(':', 2), mod = _ref[0], name = _ref[1];
      return resolvePath(require(mod), name);
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
    o = $();
    for (_i = 0, _len = nodes.length; _i < _len; _i++) {
      node = nodes[_i];
      o = o.add(node);
    }
    return o;
  };
  $parseHTML = function(nodes) {
    if (isString(nodes)) {
      return $fromArray($.parseHTML(nodes));
    } else {
      return nodes;
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
      if (name.slice(0, 5) === 'attr-') {
        name = 'attr';
      }
      if (name.slice(0, 6) === 'class-') {
        name = 'class';
      }
      return this.directives[hypensToCamelCase("compile-" + name)];
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
        _ref = node.childNodes;
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
      var action, actions, child, stop, _i, _j, _len, _len1, _ref;
      if (!$node.data('hasActions')) {
        return $node;
      }
      actions = $node.data('actions');
      if (actions) {
        for (_i = 0, _len = actions.length; _i < _len; _i++) {
          action = actions[_i];
          stop = (action(scope, $node) || {}).stop;
          if (stop) {
            break;
          }
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
  View = (function(_super) {

    __extends(View, _super);

    View.parameterizable = false;

    View.prototype.template = void 0;

    View.prototype.compilerClass = Compiler;

    function View(options) {
      View.__super__.constructor.apply(this, arguments);
      this.parent = options != null ? options.parent : void 0;
      this.views = [];
      this.compiler = new this.compilerClass(this);
    }

    View.prototype.renderTemplate = function(template) {
      if (!(template instanceof Template)) {
        template = this.compiler.compile($(template));
      }
      return template.render(this);
    };

    View.prototype.render = function() {
      if (!this.template) {
        throw new Error("undefined template");
      }
      if (!(this.template instanceof Template)) {
        this.template = this.compiler.compile($(this.template));
      }
      return this.$el.append(this.template.render(this));
    };

    View.prototype.remove = function() {
      var view, _i, _len, _ref;
      View.__super__.remove.apply(this, arguments);
      _ref = this.views;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        view = _ref[_i];
        view.remove();
      }
      return this.parent = void 0;
    };

    View.prototype.addView = function(view, id) {
      this.views.push(view);
      if (id) {
        return this[id] = view;
      }
    };

    View.prototype.get = function(p, options) {
      var _ref;
      return this.getOwn(p, options) || ((_ref = this.parent) != null ? _ref.get(p, options) : void 0);
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
        o = ctx instanceof Backbone.Model ? ctx.get(n) || ctx[n] : ctx[n];
        if (o === void 0) {
          break;
        }
        if (jQuery.isFunction(o)) {
          o = o.call(ctx);
        }
      }
      return o;
    };

    View.prototype.compileInterpolation = function($node, path) {
      return function(scope, $node) {
        var got;
        got = scope.get(path);
        if (isString(got)) {
          got = document.createTextNode(got);
        }
        return $node.replaceWith(got);
      };
    };

    View.prototype.compileAttr = function($node, name, value) {
      var attrName;
      attrName = name.substring(5);
      $node.removeAttr(name);
      return function(scope, $node) {
        var got;
        got = scope.get(value);
        if (isBoolean(got)) {
          if (got) {
            return $node.attr(attrName, '');
          }
        } else {
          return $node.attr(attrName, got);
        }
      };
    };

    View.prototype.compileClass = function($node, name, value) {
      var className;
      className = name.slice(6);
      $node.removeAttr(name);
      return function(scope, $node) {
        var got;
        got = scope.get(value);
        if (got) {
          return $node.addClass(className);
        } else {
          return $node.removeClass(className);
        }
      };
    };

    View.prototype.compileShowIf = function($node, name, value) {
      $node.removeAttr(name);
      return function(scope, $node) {
        var got;
        got = scope.get(value);
        if (got) {
          return $node.show();
        } else {
          return $node.hide();
        }
      };
    };

    View.prototype.compileView = function($node, name, value) {
      var element, node, spec, template, viewClass, viewId, viewIdAttr;
      node = $node[0];
      element = name == null;
      viewClass = (function() {
        if (element) {
          spec = $node.attr('name');
          if (!spec) {
            throw new Error("provide view attr");
          }
          return resolveSpec(spec);
        } else {
          $node.removeAttr(name);
          return resolveSpec(value);
        }
      })();
      viewIdAttr = element ? 'id' : 'view-id';
      viewId = $node.attr(viewIdAttr);
      $node.removeAttr(viewIdAttr);
      template = element || viewClass.parameterizable ? $node.contents().detach() : void 0;
      return function(scope, $node) {
        var a, attrName, view, viewParams, _i, _len, _ref;
        viewParams = {};
        _ref = toArray(node.attributes);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          a = _ref[_i];
          if (!element && a.name.slice(0, 5) !== 'view-') {
            continue;
          }
          attrName = element ? a.name : a.name.slice(5);
          attrName = hypensToCamelCase(attrName);
          viewParams[attrName] = scope.get(a.value) || a.value;
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
        if (element) {
          $node.replaceWith(view.$el);
        }
        return scope.addView(view, viewId);
      };
    };

    return View;

  })(Backbone.View);
  ActiveView = (function(_super) {

    __extends(ActiveView, _super);

    function ActiveView() {
      var _this = this;
      ActiveView.__super__.constructor.apply(this, arguments);
      if (this.model) {
        this.listenTo(this.model, 'change', function() {
          return _this.digest();
        });
      }
      if (this.collection) {
        this.listenTo(this.collection, 'change add remove reset sort', function() {
          return _this.digest();
        });
      }
      this.observe = {};
    }

    ActiveView.prototype.digest = function() {
      var newValue, path, updates, value, _ref, _results;
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
    };

    ActiveView.prototype.reactOn = function(p, options) {
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

    ActiveView.prototype.remove = function() {
      ActiveView.__super__.remove.apply(this, arguments);
      return this.observe = void 0;
    };

    ActiveView.prototype.compileInterpolation = function($node, value) {
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
            if (isString(got)) {
              got = $(document.createTextNode(got));
            }
            $point.replaceWith(got);
            return $point = got;
          }
        });
      };
    };

    ActiveView.prototype.compileAttr = function($node, name, value) {
      var attrName, observe;
      observe = false;
      if (value.substring(0, 5) === 'bind:') {
        value = value.substring(5);
        observe = true;
      }
      attrName = name.substring(5);
      $node.removeAttr(name);
      return function(scope, $node) {
        return scope.reactOn(value, {
          observe: observe,
          react: function(got) {
            if (isBoolean(got)) {
              if (got) {
                return $node.attr(attrName, '');
              }
            } else {
              return $node.attr(attrName, got);
            }
          }
        });
      };
    };

    ActiveView.prototype.compileClass = function($node, name, value) {
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
    };

    ActiveView.prototype.compileShowIf = function($node, name, value) {
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
    };

    return ActiveView;

  })(View);
  return {
    Compiler: Compiler,
    Template: Template,
    View: View,
    ActiveView: ActiveView,
    $parseHTML: $parseHTML
  };
});
