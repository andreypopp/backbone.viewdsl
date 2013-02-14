// Generated by CoffeeScript 1.4.0
/*

  Backbone.ViewDSL2

  2013 (c) Andrey Popp <8mayday@gmail.com>
*/

/*
  Minimal promise implementation

  Promise.resolve() and Promise.reject() methods execute callbacks
  immediatelly if a result is already available. This is done mostly because
  of performance reasons and to minimize possible UI flicks.

  To prevent uncatched and unlogged exception it is always useful to call
  Promise.done() method at the end of the chain.
*/

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

define(function(require) {
  var Backbone, Compiler, Promise, Template, View, extend, hypensToCamelCase, isBoolean, isPromise, join, promise, promiseRequire, some, standardCompiler, toArray, _ref;
  _ref = require('underscore'), some = _ref.some, extend = _ref.extend, toArray = _ref.toArray, isBoolean = _ref.isBoolean;
  Backbone = require('backbone');
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
  hypensToCamelCase = function(o) {
    return o.replace(/-([a-z])/g, function(g) {
      return g[1].toUpperCase();
    });
  };
  /*
      HTML compiler
  */

  Compiler = (function() {

    function Compiler() {}

    Compiler.prototype.compile = function($node) {
      this.compileImpl($node);
      return new Template($node);
    };

    Compiler.prototype.attr = function($node, name, value) {
      var attrName;
      attrName = name.substring(5);
      $node.removeAttr(name);
      return function(scope, $node) {
        var got;
        got = scope[value];
        if (isBoolean(got)) {
          if (got) {
            return $node.attr(attrName, '');
          }
        } else {
          return $node.attr(attrName, got);
        }
      };
    };

    Compiler.prototype["class"] = function($node, name, value) {
      var className;
      className = name.slice(6);
      $node.removeAttr(name);
      return function(scope, $node) {
        var got;
        got = scope[value];
        if (got) {
          return $node.addClass(className);
        } else {
          return $node.removeClass(className);
        }
      };
    };

    Compiler.prototype.directiveFor = function(name) {
      if (name.slice(0, 5) === 'attr-') {
        name = 'attr';
      }
      if (name.slice(0, 6) === 'class-') {
        name = 'class';
      }
      return this[hypensToCamelCase(name)];
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
      $node;
      return false;
    };

    Compiler.prototype.compileNode = function($node) {
      var actions, attr, attrActions, child, directive, hasActions, hasChildActions, node;
      node = $node[0];
      directive = this.directiveFor(node.tagName.toLowerCase());
      actions = directive ? [directive($node)] : [];
      attrActions = (function() {
        var _i, _len, _ref1, _results;
        _ref1 = toArray(node.attributes);
        _results = [];
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          attr = _ref1[_i];
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
        var _i, _len, _ref1, _results;
        _ref1 = node.childNodes;
        _results = [];
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          child = _ref1[_i];
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
      return this.renderImpl(scope, $rendered);
    };

    Template.prototype.renderImpl = function(scope, $node) {
      var action, actions, child, stop, _i, _j, _len, _len1, _ref1;
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
      _ref1 = toArray($node[0].childNodes);
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        child = _ref1[_j];
        this.renderImpl(scope, $(child));
      }
      return $node;
    };

    return Template;

  })();
  standardCompiler = new Compiler();
  View = (function(_super) {

    __extends(View, _super);

    function View() {
      return View.__super__.constructor.apply(this, arguments);
    }

    View.prototype.template = void 0;

    View.prototype.compiler = standardCompiler;

    View.prototype.renderTemplate = function(template) {
      if (!(template instanceof Template)) {
        template = this.compiler.compile(template);
      }
      return template.render(this);
    };

    View.prototype.render = function() {
      if (!this.template) {
        throw new Error('undefined template');
      }
      if (!(this.template instanceof Template)) {
        this.template = this.compiler.compile(template);
      }
      return this.$el.append(this.template.render(this));
    };

    return View;

  })(Backbone.View);
  return {
    Compiler: Compiler,
    Template: Template,
    View: View
  };
});
