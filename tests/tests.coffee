define (require) ->

  {View} = require 'backbone.viewdsl'

  class window.SomeView extends View

  describe 'View', ->

    describe 'basic DOM rendering', ->

      it 'should construct a view from a text only template', (done) ->

        promise = View.from 'Hello'
        promise
          .then (view) ->
            expect(view.el.tagName).to.be.equal undefined
            expect(view.$el.text()).to.be.equal 'Hello'
            done()
          .end()

      it 'should construct a view from a DOM template', (done) ->

        promise = View.from """
          <div class="some-class">Hello</div>
          """
        promise
          .then (view) ->
            expect(view.el.tagName).to.be.equal 'DIV'
            expect(view.$el.text()).to.be.equal 'Hello'
            expect(view.$el.hasClass('some-class')).to.be.ok
            done()
          .end()

      it 'should construct a view from a DOM element', (done) ->

        promise = View.from document.createElement('div')
        promise
          .then (view) ->
            expect(view.el.tagName).to.be.equal 'DIV'
            expect(view.$el.text()).to.be.equal ''
            done()
          .end()

      it 'should construct a view from a jQuery element', (done) ->

        promise = View.from $ '<div>Hello</div>'
        promise
          .then (view) ->
            expect(view.el.tagName).to.be.equal 'DIV'
            expect(view.$el.text()).to.be.equal 'Hello'
            done()
          .end()

      it 'should render text into view from a template', (done) ->

        class MyView extends View

          render: ->
            this.renderDOM 'Hello'

        view = new MyView()
        view.render()
          .then ->
            expect(view.$el.text()).to.be.equal 'Hello'
            done()
          .end()

      it 'should render DOM into view from a template', (done) ->

        class MyView extends View

          render: ->
            this.renderDOM """
              <div class="some-class">Hello</div>
              """

        view = new MyView()
        view.render()
          .then ->
            expect(view.$el.children().length).to.be.equal 1
            el = $(view.$el.children()[0])
            expect(el[0].tagName).to.be.equal 'DIV'
            expect(el.text()).to.be.equal 'Hello'
            expect(el.hasClass('some-class')).to.be.ok
            done()
          .end()

      it 'should render multiple DOM elements into view from a template', (done) ->

        class MyView extends View

          render: ->
            this.renderDOM """
              <div class="some-class">Hello</div>
              <div class="another-class">Hello2</div>
              """

        view = new MyView()
        view.render()
          .then ->
            expect(view.$el.children().length).to.be.equal 2
            expect(view.$('.some-class').length).to.be.equal 1
            expect(view.$('.another-class').length).to.be.equal 1
            expect(view.$('.some-class').text()).to.be.equal 'Hello'
            expect(view.$('.another-class').text()).to.be.equal 'Hello2'
            done()
          .end()

      it 'should render into view from a DOM element', (done) ->

        class MyView extends View

          render: ->
            this.renderDOM document.createElement('div')

        view = new MyView()
        view.render()
          .then ->
            expect(view.$el.children().length).to.be.equal 1
            expect(view.$el.text()).to.be.equal ''
            done()
          .end()

      it 'should render into view from a jQuery element', (done) ->

        class MyView extends View

          render: ->
            this.renderDOM $ '<div>Hello</div>'

        view = new MyView()
        view.render()
          .then ->
            expect(view.$el.children().length).to.be.equal 1
            expect(view.$el.text()).to.be.equal 'Hello'
            done()
          .end()

      it 'should throw an error if constructing view from multiple elements', ->
        expect(-> View.from('<div></div><div></div>')).to.throw(Error)

      it 'should provide default render method', (done) ->

        class MyView extends View
          template: """
            <div>Hello</div>
            """

        view = new MyView()
        expect(view.templateCached).to.be.equal undefined
        view.render()
          .then ->
            expect(view.$el.children().length).to.be.equal 1
            expect(view.$el.text()).to.be.equal 'Hello'
            expect(view.templateCached).to.not.be.equal undefined
            done()
          .end()

    describe 'view instantiation via view attribute', ->

      it 'should instantiate views by a global spec', (done) ->

        promise = View.from """
          <div class="some-class">
            <div view="SomeView">Some View</div>
          </div>
          """
        promise
          .then (view) ->
            expect(view.views.length).to.be.equal 1
            expect(view instanceof View).to.be.ok
            subview = view.views[0]
            expect(subview.el.tagName).to.be.equal 'DIV'
            expect(subview.$el.text()).to.be.equal 'Some View'
            expect(subview instanceof SomeView).to.be.ok
            done()
          .end()

      it 'should instantiate views by AMD spec', (done) ->

        {LoadedView} = require 'views'

        promise = View.from """
          <div class="some-class">
            <div view="views:LoadedView"></div>
          </div>
          """
        promise
          .then (view) ->
            expect(view.views.length).to.be.equal 1
            expect(view instanceof View).to.be.ok
            subview = view.views[0]
            expect(subview.el.tagName).to.be.equal 'DIV'
            expect(subview.$el.text()).to.be.equal 'HI'
            expect(subview instanceof LoadedView).to.be.ok
            done()
          .end()

      it 'should instantiate view by global spec inside other view', (done) ->

        class MyView extends View

          initialize: ->
            this.propParam = 'prop!'

          methodParam: ->
            this.constructor.name

          render: ->
            this.renderDOM """
              <div class="some-class">
                <div
                  view="SomeView"
                  view-id="someView"
                  view-some-param="methodParam"
                  view-another-param="propParam"
                  view-absent-param="some string"
                  >Some View</div>
              </div>
              """

        view = new MyView()
        view.render()
          .then ->
            expect(view.views.length).to.be.equal 1
            expect(view instanceof View).to.be.ok
            subview = view.views[0]
            expect(view.someView).to.be.equal subview
            expect(subview.el.tagName).to.be.equal 'DIV'
            expect(subview.$el.text()).to.be.equal 'Some View'
            expect(subview instanceof SomeView).to.be.ok
            expect(subview.options.someParam).to.be.equal 'MyView'
            expect(subview.options.anotherParam).to.be.equal 'prop!'
            expect(subview.options.absentParam).to.be.equal 'some string'
            done()
          .end()
          
      it 'should instantiate views by a context-bound spec', (done) ->

        class MyView extends View

          viewClass: window.SomeView

          render: ->
            this.renderDOM """
              <div class="some-class">
                <div
                  view="@viewClass"
                  view-id="someView"
                  >Some View</div>
              </div>
              """

        view = new MyView()
        view.render()
          .then ->
            expect(view.views.length).to.be.equal 1
            expect(view instanceof View).to.be.ok
            subview = view.views[0]
            expect(view.someView).to.be.equal subview
            expect(subview.el.tagName).to.be.equal 'DIV'
            expect(subview.$el.text()).to.be.equal 'Some View'
            expect(subview instanceof SomeView).to.be.ok
            done()
          .end()

    describe 'view instantiation via <view> element', ->

      it 'should instantiate views by global spec', (done) ->

        promise = View.from """
          <div class="some-class">
            <view name="SomeView">Some View</view>
          </div>
          """
        promise
          .then (view) ->
            expect(view.views.length).to.be.equal 1
            expect(view instanceof View).to.be.ok
            subview = view.views[0]
            expect(subview.el.tagName).to.be.equal 'DIV'
            expect(subview instanceof SomeView).to.be.ok
            done()
          .end()

      it 'should instantiate views by AMD spec', (done) ->

        {LoadedView} = require 'views'

        promise = View.from """
          <div class="some-class">
            <view name="views:LoadedView" />
          </div>
          """
        promise
          .then (view) ->
            expect(view.views.length).to.be.equal 1
            expect(view instanceof View).to.be.ok
            subview = view.views[0]
            expect(subview.el.tagName).to.be.equal 'DIV'
            expect(subview instanceof LoadedView).to.be.ok
            done()
          .end()

      it 'should instantiate view by global spec inside other view', (done) ->

        class MyView extends View

          initialize: ->
            this.propParam = 'prop!'

          methodParam: ->
            this.constructor.name

          render: ->
            this.renderDOM """
              <div class="some-class">
                <view
                  name="SomeView"
                  id="someView"
                  some-param="methodParam"
                  another-param="propParam"
                  absent-param="some string"
                  />
              </div>
              """

        view = new MyView()
        view.render()
          .then ->
            expect(view.views.length).to.be.equal 1
            expect(view instanceof View).to.be.ok
            subview = view.views[0]
            expect(view.someView).to.be.equal subview
            expect(subview.el.tagName).to.be.equal 'DIV'
            expect(subview instanceof SomeView).to.be.ok
            expect(subview.options.someParam).to.be.equal 'MyView'
            expect(subview.options.anotherParam).to.be.equal 'prop!'
            expect(subview.options.absentParam).to.be.equal 'some string'
            done()
          .end()

    describe 'conditional blocks', ->

      it 'should conditionally render by view property', (done) ->

        class MyView extends View

          initialize: (options) ->
            this.show1 = options.show1
            this.show2 = options.show2

          render: ->
            this.renderDOM """
              <div>
                <div if="show1" class="show1"></div>
                <div if="show2" class="show2"></div>
              </div>
              """

        view = new MyView(show1: true, show2: false)
        view.render()
          .then ->
            expect(view.$('.show1').length).to.be.equal 1
            expect(view.$('.show2').length).to.be.equal 0
            done()
          .end()

      it 'should conditionally render by view property by path', (done) ->

        class MyView extends View

          initialize: (options) ->
            this.obj = {show1: options.show1, show2: options.show2}

          render: ->
            this.renderDOM """
              <div>
                <div if="obj.show1" class="show1"></div>
                <div if="obj.show2" class="show2"></div>
              </div>
              """

        view = new MyView(show1: true, show2: false)
        view.render()
          .then ->
            expect(view.$('.show1').length).to.be.equal 1
            expect(view.$('.show2').length).to.be.equal 0
            done()
          .end()

      it 'should conditionally render by view function', (done) ->

        class MyView extends View

          initialize: (options) ->
            this._show1 = options.show1
            this._show2 = options.show2

          show1: -> this._show1
          show2: -> this._show2

          render: ->
            this.renderDOM """
              <div>
                <div if="show1" class="show1"></div>
                <div if="show2" class="show2"></div>
              </div>
              """

        view = new MyView(show1: true, show2: false)
        view.render()
          .then ->
            expect(view.$('.show1').length).to.be.equal 1
            expect(view.$('.show2').length).to.be.equal 0
            done()
          .end()

      it 'should conditionally render by view function by path', (done) ->

        class MyClass
          show1: -> this._show1
          show2: -> this._show2

        class MyView extends View

          initialize: (options) ->
            this.obj = new MyClass
            this.obj.show1 = options.show1
            this.obj.show2 = options.show2

          render: ->
            this.renderDOM """
              <div>
                <div if="obj.show1" class="show1"></div>
                <div if="obj.show2" class="show2"></div>
              </div>
              """

        view = new MyView(show1: true, show2: false)
        view.render()
          .then ->
            expect(view.$('.show1').length).to.be.equal 1
            expect(view.$('.show2').length).to.be.equal 0
            done()
          .end()

    describe 'text node interpolation', ->

      it 'should interpolate strings in basic text template', (done) ->

        class MyView extends View

          initialize: (options) ->
            this.name = options.name

          render: ->
            this.renderDOM """
              Hello, {{name}}!
              """

        view = new MyView(name: 'World')
        view.render()
          .then ->
            expect(view.$el.text()).to.be.equal 'Hello, World!'
            done()
          .end()

      it 'should interpolate missing values to empty string', (done) ->

        class MyView extends View

          render: ->
            this.renderDOM """
              Hello, {{name}}!
              """

        view = new MyView(name: 'World')
        view.render()
          .then ->
            expect(view.$el.text()).to.be.equal 'Hello, !'
            done()
          .end()

      it 'should interpolate values from local context', (done) ->

        class MyView extends View

          initialize: (options) ->
            this.name = options.name

          render: ->
            this.renderDOM """
              Hello, {{name}}{{greetingEnd}}
              """, {greetingEnd: '!!!'}

        view = new MyView(name: 'World')
        view.render()
          .then ->
            expect(view.$el.text()).to.be.equal 'Hello, World!!!'
            done()
          .end()

      it 'should interpolate strings in HTML template', (done) ->

        class MyView extends View

          initialize: (options) ->
            this.name = options.name

          render: ->
            this.renderDOM """
              <div>
                Hello, <span class="name">{{name}}</span>!
              </div>
              """

        view = new MyView(name: 'World')
        view.render()
          .then ->
            expect(view.$('span.name').text()).to.be.equal 'World'
            done()
          .end()

      it 'should interpolate strings using a function call', (done) ->

        class MyView extends View

          name: ->
            this.constructor.name

          render: ->
            this.renderDOM """
              <div>
                Hello, <span class="name">{{name}}</span>!
              </div>
              """

        view = new MyView()
        view.render()
          .then ->
            expect(view.$('span.name').text()).to.be.equal 'MyView'
            done()
          .end()

      it 'should interpolate jQuery objects', (done) ->

        class MyView extends View

          name: ->
            $('<span class="inner-name">World</span>')

          render: ->
            this.renderDOM """
              <div>
                Hello, <span class="name">{{name}}</span>!
              </div>
              """

        view = new MyView()
        view.render()
          .then ->
            expect(view.$('span.inner-name').text()).to.be.equal 'World'
            done()
          .end()

      it 'should interpolate DOM nodes', (done) ->

        class MyView extends View

          name: ->
            $('<span class="inner-name">World</span>')[0]

          render: ->
            this.renderDOM """
              <div>
                Hello, <span class="name">{{name}}</span>!
              </div>
              """

        view = new MyView()
        view.render()
          .then ->
            expect(view.$('span.inner-name').text()).to.be.equal 'World'
            done()
          .end()

      it 'should interpolate strings by path', (done) ->

        class MyView extends View

          initialize: (options) ->
            this.obj = {name: 'World'}

          render: ->
            this.renderDOM """
              Hello, {{obj.name}}!
              """

        view = new MyView(name: 'World')
        view.render()
          .then ->
            expect(view.$el.text()).to.be.equal 'Hello, World!'
            done()
          .end()

      it 'should interpolate strings using a function call by path', (done) ->

        class MyClass
          name: ->
            this.constructor.name

        class MyView extends View

          initialize: ->
            this.obj = new MyClass()

          render: ->
            this.renderDOM """
              <div>
                Hello, <span class="name">{{obj.name}}</span>!
              </div>
              """

        view = new MyView()
        view.render()
          .then ->
            expect(view.$('span.name').text()).to.be.equal 'MyClass'
            done()
          .end()
