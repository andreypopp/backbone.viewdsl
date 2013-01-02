define (require) ->

  {View} = require 'backbone.viewdsl'

  class window.SomeView extends View

  describe 'View', ->

    describe 'basic DOM rendering', ->

      it 'should construct a view from DOM template', (done) ->

        promise = View.from """
          <div class="some-class">Hello</div>
          """
        promise.then (view) ->
          expect(view.el.tagName).to.be.equal 'DIV'
          expect(view.$el.text()).to.be.equal 'Hello'
          expect(view.$el.hasClass('some-class')).to.be.ok
          done()

      it 'should throw an error if constructing view from multiple elements', ->
        expect(-> View.from('<div></div><div></div>')).to.throw(Error)

      it 'should render DOM into view', (done) ->

        class MyView extends View

          render: ->
            this.renderDOM """
              <div class="some-class">Hello</div>
              """

        view = new MyView()
        view.render().then ->
          expect(view.$el.length).to.be.equal 1
          el = $(view.$el.children()[0])
          expect(el[0].tagName).to.be.equal 'DIV'
          expect(el.text()).to.be.equal 'Hello'
          expect(el.hasClass('some-class')).to.be.ok
          done()

    describe 'view instantiation', ->

      it 'should instantiate views by global spec', (done) ->

        promise = View.from """
          <div class="some-class">
            <div view="SomeView">Some View</div>
          </div>
          """
        promise.then (view) ->
          expect(view.views.length).to.be.equal 1
          expect(view instanceof View).to.be.ok

          subview = view.views[0]
          expect(subview.el.tagName).to.be.equal 'DIV'
          expect(subview.$el.text()).to.be.equal 'Some View'
          expect(subview instanceof SomeView).to.be.ok

          done()

      it 'should instantiate view by global spec inside other view', (done) ->

        class MyView extends View

          render: ->
            this.renderDOM """
              <div class="some-class">
                <div view="SomeView">Some View</div>
              </div>
              """

        view = new MyView()
        view.render().then ->
          expect(view.views.length).to.be.equal 1
          expect(view instanceof View).to.be.ok

          subview = view.views[0]
          expect(subview.el.tagName).to.be.equal 'DIV'
          expect(subview.$el.text()).to.be.equal 'Some View'
          expect(subview instanceof SomeView).to.be.ok

          done()

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
        view.render().then ->
          expect(view.$('.show1').length).to.be.equal 1
          expect(view.$('.show2').length).to.be.equal 0
          done()

      it 'should conditionally render by view function', (done) ->

        class MyView extends View

          show1: -> true
          show2: -> false

          render: ->
            this.renderDOM """
              <div>
                <div if="show1" class="show1"></div>
                <div if="show2" class="show2"></div>
              </div>
              """

        view = new MyView()
        view.render().then ->
          expect(view.$('.show1').length).to.be.equal 1
          expect(view.$('.show2').length).to.be.equal 0
          done()
