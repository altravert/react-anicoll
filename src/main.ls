/**
 * User: bulgakov
 * Date: 30.05.15
 * Time: 20:29
 */

if require?
  React = require('react')
else
  React = @React

Array::map = (f) -> (for x in @ then f x)
Array::map_ = (f) !-> for x in @ then f x

debugStylesMoving = 'box-shadow': '0 0 0 1px #f00'
releaseStylesMoving = {}

debugStylesRemoving = 'box-shadow': '0 0 0 1px #f0f'
releaseStylesRemovig = {}

Clone = React.createClass do
  componentDidMount: ->
    node = $ @getDOMNode!
    @props.d.willIn node.height()
    node
    .css ({ position:'absolute', opacity: 0 } <<< @props.d.stylesMoving <<< @props.transite)
    .velocity {opacity:1}, @props.d.config.duration, @props.d.config.easing
  componentWillUnmount: ->
    self = $ @getDOMNode!
    @props.d.willOut self.height()
    node = self.clone!
    .css @props.d.stylesRemoving
    .velocity {opacity:0}, @props.d.config.duration, @props.d.config.easing, -> $ @ .remove!
    $ @props.d.portal .append node

  componentWillReceiveProps: (nextProps) ->
    $ @getDOMNode! .css nextProps.prev if nextProps.prev
  componentDidUpdate: ->
    @props.d.animStart!
    $ @getDOMNode! .velocity @props.transite, @props.d.config.duration, @props.d.config.easing, ~> @props.d.animEnd!
  render: ->
    React.DOM.div {}, @props.children

Clones = React.createClass do
  componentDidMount: ->
  render: ->
    React.createElement 'div', className:"anicoll-floatings",
      ((Array::slice.apply @props.children).sort (a, b) -> (a.key < b.key) && -1 || ((a.key > b.key) && 1 || 0)).map (child) ~>
        React.createElement Clone,
          key:child.key, ref:child.key,
          transite: @props.positions[child.key], prev:@props.prevPositions[child.key],
          d:@props.d,
          React.cloneElement child, key:'c'

BlgList = React.createClass do
  getInitialState: ->
    defaultClone = (node) -> @ node .clone!

    @config = {
      easing: (x, t, b, c, d) -> -c * (t /= d) * (t - 2) + b #jQuery.swing
      duration: 350
      debug: false
    }

# makeClone ? defaultClone,
      # nodeDidRemoved

    animating: false

  componentDidMount: ->
    $ @getDOMNode! .css opacity:1

    (@portalNode = document.createElement 'div')
    .style <<< {left:0,top:0,opacity:0,position:'absolute'}
    document.body.appendChild @portalNode

    @renderClones positions:@getPositions!, children:@props.children
  componentWillUnmount: -> document.body.removeChild @portalNode

  componentWillReceiveProps: (nextProps) ->
    if nextProps.config
      ['duration', 'easing', 'debug'].map_ (field) !~> @config[field] = nextProps.config[field] if nextProps.config[field]?
    @prepareAnimation!
  componentDidUpdate: (prevProps) ->
    @startAnimation!

  showClones: (visible) ->
    $ @getDOMNode! .css opacity:(!visible && 1.0 || 0.0)
    $ @portalNode  .css opacity: (visible && 1.0 || 0.0), 'z-index': (visible && 10 || -10)

  prepareAnimation: ->
    # return if @state.animating
    @prev = @getPositions!
  startAnimation: ->
    # return if @state.animating

    @startedAnims = 0
    @renderClones {positions:@getPositions!, prevPositions:@prev, children:@props.children}, ~> @showClones true

    if @heightDiff != 0
      node = $ @getDOMNode!
      th = node.height()
      if @heightDiff < 0
        node.css 'min-height':th
        .velocity 'min-height':th+@heightDiff, @config.duration, @config.easing, -> $ @ .css 'min-height':''
      else
        node.css 'max-height':th
        .velocity 'max-height':th+@heightDiff, @config.duration, @config.easing, -> $ @ .css 'max-height':''
  finishAnimation: ->
    # return if not @state.animating
    @showClones false

  getPositions: ->
    positions = {}
    for {key:ref} in @props.children
      node = @refs[ref].getDOMNode!
      rect = node.getBoundingClientRect()
      computedStyle = getComputedStyle(node)
      positions[ref] =
        top:  rect.top  - parseInt computedStyle.marginTop,  10
        left: rect.left - parseInt computedStyle.marginLeft, 10
        width: rect.width, height: rect.height
    positions
  animEnd: -> @finishAnimation! if --@startedAnims == 0
  renderClones: (props, cb) ->
    @startedAnims = 1
    @heightDiff = 0

    React.render (React.createElement Clones, (do
      key:'clones'
      d:
        animStart: (!~> ++@startedAnims)
        animEnd: (!~> @animEnd!)
        portal: @portalNode
        willIn: (x) !~> @heightDiff += x
        willOut: (x) !~> @heightDiff -= x
        config: @config
        stylesMoving: @config.debug && debugStylesMoving || releaseStylesMoving
        stylesRemoving: @config.debug && debugStylesRemoving || releaseStylesRemovig
    <<< props <<< @props)), @portalNode, !~>
      cb?!
      @animEnd!
      # console.log @heightDiff
  render: ->
    React.DOM.div {}, @props.children.map (child) -> React.createElement 'div', { key:child.key, ref:child.key }, child


if exports?
  exports = module.exports = BlgList if module?.exports
  exports.Anicoll = BlgList
else
  @Anicoll = BlgList

if typeof define === 'function' && define.amd
  define 'Anicoll', [], -> BlgList
