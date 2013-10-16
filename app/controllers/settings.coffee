Spine = require 'spine'
$ = Spine.$

class Settings extends Spine.Controller
  elements: 
    '#signin': 'signin'
    '#signout': 'signout'
    '.username': 'username'
    '.about': 'aboutPage'
    '.general': 'generalPage'

  events:
    'click .tabs li': 'tabs'

  state: off

  tabs: (e) ->
    # This is ugly. Shoot me later. Could not think of a better implementation.
    @el.find('.current').removeClass 'current'
    @el.find('div.'+$(e.target).addClass('current').attr('data-id')).addClass 'current'

  show: ->
    return unless @state is off
    @state = on
    @el.show(0).addClass("show")
    setTimeout ( =>
    @el.on "click.modal", (event) =>
      if event.target.className.indexOf("modal") >= 0 then @hide()
    ), 500

  hide: ->
    return unless @state is on
    @state = off
    @el.removeClass("show")
    setTimeout ( => @el.hide(0)), 350
    @el.off("click.modal")

settings = null # Temp

module.exports =

  get: ->
    return settings

  init: ->
    settings = new Settings
      el: $('.modal.preferences')