// Generated by CoffeeScript 1.4.0
var __slice = [].slice,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

(function(root, factory) {
  if (typeof define === 'function' && define.amd) {
    return define(['jquery', 'backbone', 'underscore'], function(jQuery, Backbone, _) {
      return root.Backbone.ViewDSL = factory(jQuery, Backbone, _);
    });
  } else {
    return root.Backbone.ViewDSL = factory(root.jQuery, root.Backbone, root._);
  }
})(this, function(jQuery, Backbone, _) {
  var ActiveView, BindingInterpreter, Interpreter, ObservableScope, ParameterizableView, Promise, Scope, View, asNode, extend, getByPath, getBySpec, hypensToCamelCase, insertBefore, isArray, isBoolean, isEqual, isPromise, isString, join, promise, promiseRequire, replaceChild, toArray, wrapInFragment;
  isString = _.isString, isArray = _.isArray, isBoolean = _.isBoolean, isEqual = _.isEqual, extend = _.extend, toArray = _.toArray;
  /*
      Minimal promise implementation
  
      Promise.resolve() and Promise.reject() methods execute callbacks
      immediatelly if a result is already available. This is done mostly because
      of performance reasons and to minimize possible UI flicks.
  
      To prevent uncatched and unlogged exception it is always useful to call
      Promise.done() method at the end of the chain.
  */

  Promise = (function() {
    var invokeCallback, noop, reject, resolve;

    extend(Promise.prototype, Backbone.Events);

    noop = function() {};

    resolve = function(promise, value) {
      promise.trigger('promise:resolved', {
        detail: value
      });
      promise.isResolved = true;
      return promise.resolvedValue = value;
    };

    reject = function(promise, value) {
      promise.trigger('promise:failed', {
        detail: value
      });
      promise.isRejected = true;
      return promise.rejectedValue = value;
    };

    invokeCallback = function(type, promise, callback, event) {
      var error, failed, hasCallback, succeeded, value;
      hasCallback = typeof callback === 'function';
      if (hasCallback) {
        try {
          value = callback(event.detail);
          succeeded = true;
        } catch (e) {
          if (promise.isDone) {
            throw e;
          }
          failed = true;
          error = e;
        }
      } else {
        value = event.detail;
        succeeded = true;
      }
      if (value && typeof value.then === 'function') {
        return value.then((function(value) {
          return promise.resolve(value);
        }), (function(value) {
          return promise.reject(value);
        }));
      } else if (hasCallback && succeeded) {
        return promise.resolve(value);
      } else if (failed) {
        return promise.reject(error);
      } else {
        return promise[type](value);
      }
    };

    function Promise() {
      this.isDone = false;
    }

    Promise.prototype.then = function(done, fail) {
      var thenPromise;
      thenPromise = new Promise();
      if (this.isResolved) {
        invokeCallback('resolve', thenPromise, done, {
          detail: this.resolvedValue
        });
      }
      if (this.isRejected) {
        invokeCallback('reject', thenPromise, fail, {
          detail: this.rejectedValue
        });
      }
      this.on('promise:resolved', function(event) {
        return invokeCallback('resolve', thenPromise, done, event);
      });
      this.on('promise:failed', function(event) {
        return invokeCallback('reject', thenPromise, fail, event);
      });
      return thenPromise;
    };

    Promise.prototype.resolve = function(value) {
      resolve(this, value);
      this.resolve = noop;
      return this.reject = noop;
    };

    Promise.prototype.reject = function(value) {
      reject(this, value);
      this.resolve = noop;
      return this.reject = noop;
    };

    Promise.prototype.done = function() {
      this.isDone = true;
      if (this.rejectedValue) {
        throw this.rejectedValue;
      }
    };

    Promise.prototype.appendTo = function(target) {
      return this.then(function(node) {
        return $(node).appendTo(target);
      });
    };

    Promise.prototype.prependTo = function(target) {
      return this.then(function(node) {
        return $(node).prependTo(target);
      });
    };

    return Promise;

  })();
  isPromise = function(o) {
    return typeof o.then === 'function';
  };
  promise = function(value) {
    var p;
    if (typeof (value != null ? value.then : void 0) === 'function') {
      return value;
    }
    p = new Promise();
    p.resolve(value);
    return p;
  };
  /*
      Join several `promises` into one which resolves only when all `promises` are
      resolved or fail fast.
  */

  join = function(promises) {
    var idx, p, pr, results, resultsToGo, _fn, _i, _len,
      _this = this;
    p = new Promise();
    results = [];
    if (promises.length > 0) {
      resultsToGo = promises.length;
      _fn = function(pr, idx) {
        var fail, success;
        if (!isPromise(pr)) {
          pr = promise(pr);
        }
        success = function(result) {
          results[idx] = result;
          resultsToGo = resultsToGo - 1;
          if (resultsToGo === 0) {
            return p.resolve(results);
          }
        };
        fail = function(reason) {
          return p.reject(reason);
        };
        return pr.then(success, fail);
      };
      for (idx = _i = 0, _len = promises.length; _i < _len; idx = ++_i) {
        pr = promises[idx];
        _fn(pr, idx);
      }
    } else {
      p.resolve(results);
    }
    return p;
  };
  /*
      Promise-based version of AMD require() call.
  */

  promiseRequire = function(moduleName) {
    var p;
    p = new Promise();
    require([moduleName], function(module) {
      return p.resolve(module);
    });
    return p;
  };
  /*
      Get attribute from `o` object by dotted path `p`
  
      If `callIfMethod` argument is true and path points to a function then call
      it preserving right scope and use returned value as a result
  */

  getByPath = function(o, p, callIfMethod) {
    var ctx, n, _i, _len, _ref;
    if (callIfMethod == null) {
      callIfMethod = false;
    }
    p = p.trim();
    if (p.trim().length === 0) {
      return o;
    }
    _ref = p.split('.');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      n = _ref[_i];
      ctx = o;
      o = ctx[n];
      if (o === void 0) {
        break;
      }
      if (callIfMethod && jQuery.isFunction(o)) {
        o = o.call(ctx);
      }
    }
    return o;
  };
  /*
      Resolve spec
  
      Specs can be:
      * `some/module:some.obj` resolves `some.obj` against `some/module` module
      * `some.obj` resolves `some.obj` against `window`
      * `@some.obj` resolves `some.obj` against `scope` argument
  */

  getBySpec = function(spec, scope) {
    var module, path, _ref;
    if (/:/.test(spec)) {
      _ref = spec.split(':', 2), module = _ref[0], path = _ref[1];
      return promiseRequire(module).then(function(module) {
        return getByPath(module, path);
      });
    } else if (spec && spec[0] === '@') {
      return promise(scope.get(spec.slice(1)));
    } else {
      return promise(getByPath(window, spec));
    }
  };
  hypensToCamelCase = function(o) {
    return o.replace(/-([a-z])/g, function(g) {
      return g[1].toUpperCase();
    });
  };
  insertBefore = function(o, n) {
    var m, p, _i, _j, _len, _len1, _results, _results1;
    p = o.parentNode;
    if (typeof n.cloneNode === 'function') {
      return p.insertBefore(n, o);
    } else if (typeof n.item === 'function' && n.length || n.jquery) {
      _results = [];
      for (_i = 0, _len = n.length; _i < _len; _i++) {
        m = n[_i];
        _results.push(p.insertBefore(m, o));
      }
      return _results;
    } else if (isArray(n)) {
      _results1 = [];
      for (_j = 0, _len1 = n.length; _j < _len1; _j++) {
        m = n[_j];
        _results1.push(insertBefore(o, m));
      }
      return _results1;
    } else {
      return p.insertBefore(document.createTextNode(String(n)), o);
    }
  };
  /*
      Replace `o` DOM node with a list `ns` of DOM nodes
  */

  replaceChild = function() {
    var n, ns, o, _i, _len;
    o = arguments[0], ns = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    if (!o.parentNode) {
      if (ns.length === 1) {
        return ns[0];
      } else {
        return wrapInFragment(ns);
      }
    }
    for (_i = 0, _len = ns.length; _i < _len; _i++) {
      n = ns[_i];
      insertBefore(o, n);
    }
    o.parentNode.removeChild(o);
    return ns;
  };
  /*
      Prepare `template` to be processed
  
      Argument `template` can be a DOM node, a jQuery element or just a string
      with HTML markup. If `requireSingleNode` is true then it's required from
      `template` to represent just a single DOM node.
  */

  asNode = function(node, requireSingleNode, clone) {
    var nodes;
    if (requireSingleNode == null) {
      requireSingleNode = false;
    }
    if (clone == null) {
      clone = true;
    }
    nodes = node.jquery ? clone ? node.clone() : node : typeof node.cloneNode === 'function' ? [clone ? node.cloneNode(true) : node] : jQuery.parseHTML(node.toString());
    if (requireSingleNode && nodes.length !== 1) {
      throw new Error('templates only of single element are allowed');
    }
    if (nodes.length > 1 || nodes[0].nodeType === Node.TEXT_NODE) {
      return wrapInFragment(nodes);
    } else {
      return nodes[0];
    }
  };
  wrapInFragment = function(nodes) {
    var fragment, node, _i, _len;
    fragment = document.createDocumentFragment();
    for (_i = 0, _len = nodes.length; _i < _len; _i++) {
      node = nodes[_i];
      fragment.appendChild(node);
    }
    return fragment;
  };
  /*
      Scope
  */

  Scope = (function() {

    function Scope(ctx, locals, parent) {
      this.ctx = ctx;
      this.locals = locals;
      this.parent = parent;
    }

    Scope.prototype.get = function(path, callIfMethod) {
      var result;
      if (callIfMethod == null) {
        callIfMethod = false;
      }
      if (this.locals != null) {
        result = getByPath(this.locals, path, callIfMethod);
      }
      if (result != null) {
        return result;
      }
      result = getByPath(this.ctx, path, callIfMethod);
      if (result != null) {
        return result;
      }
      if (this.parent != null) {
        result = this.parent.get(path, callIfMethod);
      }
      if (result != null) {
        return result;
      }
    };

    return Scope;

  })();
  /*
      Interpreter which interprets markup constructs and perform actions.
  */

  Interpreter = (function() {

    Interpreter.scope = Scope;

    Interpreter.prototype.textNodeSplitRe = /({{)|(}})/;

    Interpreter.prototype.processAttrRe = /^attr-/;

    function Interpreter(scope) {
      this.scope = scope;
    }

    Interpreter.prototype.render = function(node, clone) {
      if (clone == null) {
        clone = true;
      }
      if (!(typeof node.cloneNode === 'function')) {
        node = asNode(node);
      } else if (clone) {
        node = node.cloneNode(true);
      }
      return this.process(node);
    };

    Interpreter.prototype.process = function(node) {
      var _this = this;
      if (node.seen) {
        return promise(node);
      }
      node.seen = true;
      return this.processAttributes(node).then(function(pragmas) {
        if (pragmas.skip) {
          return promise();
        } else if (pragmas.remove) {
          node.parentNode.removeChild(node);
          return promise();
        } else {
          return _this.processNode(node);
        }
      });
    };

    Interpreter.prototype.processNode = function(node) {
      var n, spec,
        _this = this;
      if (node.nodeType === Node.TEXT_NODE) {
        return this.processTextNode(node).then(function(nodes) {
          if (nodes) {
            node = replaceChild.apply(null, [node].concat(__slice.call(nodes)));
          }
          return node;
        });
      } else if (node.tagName === 'VIEW') {
        if (!node.attributes.name) {
          throw new Error('<view> element should have a name attribute');
        }
        spec = node.attributes.name.value;
        node.removeAttribute('name');
        return this.instantiateView({
          spec: spec,
          node: node,
          useNode: false
        }).then(function(view) {
          var nodes, p;
          p = node.parentNode;
          nodes = replaceChild(node, view.el);
          return nodes;
        });
      } else {
        return join((function() {
          var _i, _len, _ref, _results;
          _ref = toArray(node.childNodes);
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            n = _ref[_i];
            _results.push(this.process(n));
          }
          return _results;
        }).call(this)).then(function() {
          return node;
        });
      }
    };

    Interpreter.prototype.processTextNode = function(node) {
      var data, nodes, part, parts, path;
      if (!this.textNodeSplitRe.test(node.data)) {
        return promise();
      }
      data = node.data;
      data = data.replace(/{{/g, '{{\uF001');
      parts = data.split(this.textNodeSplitRe);
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
            node = this.processInterpolation(path);
            if (node == null) {
              continue;
            }
            _results.push(node);
          } else {
            _results.push(part);
          }
        }
        return _results;
      }).call(this);
      return join(nodes);
    };

    Interpreter.prototype.processInterpolation = function(path) {
      var node;
      node = this.scope.get(path, true);
      if (!(node != null) || node === '') {
        return;
      }
      return promise(node).then(function(node) {
        return asNode(node);
      });
    };

    Interpreter.prototype.processAttributes = function(node) {
      var attr, name, show, spec, value, _i, _len, _ref, _ref1, _ref2, _ref3, _ref4;
      if (node.nodeType !== Node.ELEMENT_NODE) {
        return promise({});
      }
      if ((_ref = node.attributes) != null ? _ref["if"] : void 0) {
        show = this.scope.get(node.attributes["if"].value, true);
        node.removeAttribute('if');
        if (!show) {
          return promise({
            remove: true
          });
        }
      }
      if ((_ref1 = node.attributes) != null ? _ref1['element-id'] : void 0) {
        if (this.scope.ctx != null) {
          this.scope.ctx[(_ref2 = node.attributes) != null ? _ref2['element-id'].value : void 0] = $(node);
        }
        node.removeAttribute('element-id');
      }
      _ref3 = node.attributes;
      for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
        attr = _ref3[_i];
        if (!((attr != null) && this.processAttrRe.test(attr.name))) {
          continue;
        }
        name = attr.name.substring(5);
        value = this.scope.get(attr.value, true);
        if (isBoolean(value)) {
          $(node).prop(name, value);
        } else {
          $(node).attr(name, value);
        }
        node.removeAttribute(attr.name);
      }
      if ((_ref4 = node.attributes) != null ? _ref4.view : void 0) {
        spec = node.attributes.view.value;
        node.removeAttribute('view');
        return this.instantiateView({
          spec: spec,
          node: node,
          useNode: true
        }).then(function(view) {
          if (view.parameterizable) {
            return {
              skip: true
            };
          } else {
            return {};
          }
        });
      } else {
        return promise({});
      }
    };

    Interpreter.prototype.instantiateView = function(options) {
      var _this = this;
      return getBySpec(options.spec, this.scope).then(function(viewCls) {
        var c, fromViewTag, p, partial, prefix, view, viewId, viewParams, _ref, _ref1;
        if (viewCls === void 0) {
          throw new Error("can't find a view by '" + options.spec + "' spec");
        }
        fromViewTag = options.node.tagName === 'VIEW';
        prefix = fromViewTag ? void 0 : 'view-';
        _ref = _this.consumeViewParams(options.node, prefix), viewParams = _ref.viewParams, viewId = _ref.viewId;
        view = jQuery.isFunction(viewCls) ? (options.useNode ? viewParams.el = options.node : void 0, new viewCls(viewParams)) : (options.useNode ? viewCls.setElement(options.node) : void 0, viewCls);
        if (fromViewTag && options.node.attributes['class']) {
          view.$el.addClass(options.node.attributes['class'].value);
        }
        view.parentScope = _this.scope;
        if (((_ref1 = _this.scope.ctx) != null ? _ref1.addView : void 0) != null) {
          _this.scope.ctx.addView(view, viewId);
        }
        p = view.parameterizable ? (partial = $((function() {
          var _i, _len, _ref2, _results;
          _ref2 = toArray(options.node.childNodes);
          _results = [];
          for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
            c = _ref2[_i];
            _results.push(options.node.removeChild(c));
          }
          return _results;
        })()), partial = asNode(partial), promise(view.render(partial))) : promise(view.render());
        return p.then(function() {
          return view;
        });
      });
    };

    Interpreter.prototype.consumeViewParams = function(node, prefix) {
      var a, attrName, viewId, viewParams, _i, _len, _ref;
      viewParams = {};
      viewId = void 0;
      _ref = toArray(node.attributes);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        a = _ref[_i];
        if (!(prefix && a.name.slice(0, prefix.length) === prefix || !prefix)) {
          continue;
        }
        attrName = prefix ? a.name.slice(prefix.length) : a.name;
        attrName = hypensToCamelCase(attrName);
        if (attrName === 'id') {
          viewId = a.value;
          node.removeAttribute(a.name);
          continue;
        }
        viewParams[attrName] = this.scope.get(a.value, true) || a.value;
      }
      return {
        viewParams: viewParams,
        viewId: viewId
      };
    };

    return Interpreter;

  })();
  /*
      View which can render process DSL.
  */

  View = (function(_super) {

    __extends(View, _super);

    View.interpreter = Interpreter;

    View.prototype.template = void 0;

    View.prototype.parameterizable = false;

    View.prototype.parentScope = void 0;

    View.from = function(node, locals) {
      var interpreter, scope, view;
      node = asNode(node, true);
      view = new this({
        el: node
      });
      scope = new this.interpreter.scope(view, locals);
      interpreter = new this.interpreter(scope);
      return interpreter.render(node, false).then(function() {
        view.render();
        return view;
      });
    };

    function View() {
      View.__super__.constructor.apply(this, arguments);
      this.views = [];
    }

    View.prototype.addView = function(view, viewId) {
      this.views.push(view);
      if (viewId) {
        return this[viewId] = view;
      }
    };

    View.prototype.renderTemplate = function(template, locals) {
      var interpreter, scope;
      scope = new this.constructor.interpreter.scope(this, locals, this.parentScope);
      interpreter = new this.constructor.interpreter(scope);
      return interpreter.render(template);
    };

    View.prototype.render = function(locals) {
      var _this = this;
      if (this.template == null) {
        return promise(this);
      }
      return this.renderTemplate(this.template, locals).appendTo(this.$el).then(function() {
        return _this;
      });
    };

    View.prototype.remove = function() {
      var view, _i, _len, _ref, _results;
      View.__super__.remove.apply(this, arguments);
      _ref = this.views;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        view = _ref[_i];
        _results.push(view.remove());
      }
      return _results;
    };

    return View;

  })(Backbone.View);
  /*
      View parametrized with some template.
  */

  ParameterizableView = (function(_super) {

    __extends(ParameterizableView, _super);

    function ParameterizableView() {
      return ParameterizableView.__super__.constructor.apply(this, arguments);
    }

    ParameterizableView.prototype.parameterizable = true;

    ParameterizableView.prototype.render = function(partial, locals) {
      if (this.template) {
        locals = extend({}, locals, {
          partial: this.renderTemplate(partial)
        });
        return ParameterizableView.__super__.render.call(this, locals);
      } else {
        return this.renderTemplate(partial).appendTo(this.$el);
      }
    };

    return ParameterizableView;

  })(View);
  ObservableScope = (function(_super) {

    __extends(ObservableScope, _super);

    extend(ObservableScope.prototype, Backbone.Events);

    function ObservableScope() {
      ObservableScope.__super__.constructor.apply(this, arguments);
      this.observe = {};
    }

    ObservableScope.prototype.get = function(path, callIfMethod) {
      var result;
      if (callIfMethod == null) {
        callIfMethod = false;
      }
      result = ObservableScope.__super__.get.apply(this, arguments);
      this.observe[path] = result;
      return result;
    };

    ObservableScope.prototype.digest = function() {
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

    return ObservableScope;

  })(Scope);
  BindingInterpreter = (function(_super) {

    __extends(BindingInterpreter, _super);

    function BindingInterpreter() {
      return BindingInterpreter.__super__.constructor.apply(this, arguments);
    }

    BindingInterpreter.scope = ObservableScope;

    BindingInterpreter.prototype.processInterpolation = function(path) {
      return BindingInterpreter.__super__.processInterpolation.apply(this, arguments).then(function(node) {
        this.scope.on("change:" + path, function(value) {
          return node.replaceWith(asNode(value));
        });
        return node;
      });
    };

    return BindingInterpreter;

  })(Interpreter);
  ActiveView = (function(_super) {

    __extends(ActiveView, _super);

    function ActiveView() {
      return ActiveView.__super__.constructor.apply(this, arguments);
    }

    ActiveView.interpreter = BindingInterpreter;

    return ActiveView;

  })(View);
  return {
    View: View,
    ParameterizableView: ParameterizableView,
    ActiveView: ActiveView
  };
});
