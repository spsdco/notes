Spine = require 'spine'
$ = Spine.$
Sync = require './sync.coffee'

# Node-Webkit. IMPORTANT NOTE: USE WINDOW.REQUIRE
shell = window.require('nw.gui').Shell if window.require

class Settings extends Spine.Controller
  elements:
    '#signin': 'signinbtn'
    '#signout': 'signoutbtn'
    '.username': 'username'
    '.about': 'aboutPage'
    '.general': 'generalPage'
    '.signedin': 'signedin'
    '.signedout': 'signedout'

  events:
    'click .tabs li': 'tabs'
    'click #signin': 'signin'
    'click #signout': 'signout'

  state: off

  constructor: ->
    super

    # A really bad hack
    Spine.bind 'sync:authorized', =>
      @hide()
      @signedout.hide()
      @signedin.show()
      $.ajax(
        Sync.generateRequest {request: "me"}
      ).done((data) =>
        @username.text data.email
      )

    Spine.bind 'sync:unauthorized', =>
      @signedout.show()
      @signedin.hide()
      @signinbtn.text 'Sign In'

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
        if event.target.className.indexOf('modal') > -1 then @hide()
    ), 500

  hide: ->
    return unless @state is on
    @state = off
    @el.removeClass("show")
    setTimeout ( => @el.hide(0)), 350
    @el.off("click.modal")

  signin: ->
    @signinbtn.text 'Connecting...'
    Sync.auth (data) =>
      if shell
        shell.openExternal data.url
      else
        window.open data.url

  signout: ->
    Sync.signOut()


settings = null # Temp

module.exports =

  get: ->
    return settings

  init: ->
    settings = new Settings
      el: $('.modal.preferences')
