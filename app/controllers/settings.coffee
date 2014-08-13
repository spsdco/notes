Spine = require 'spine'
$ = Spine.$

shell = window.require('shell') if window.require

Sync = require './sync.coffee'
Account = require '../controllers/account.coffee'

class Settings extends Spine.Controller
  elements:
    '.sync #signin': 'signinbtn'
    '.sync #signout': 'signoutbtn'
    '.account #signin': 'signinacc'
    '.sync .username': 'username'
    '.account .name': 'accusername'
    '.about': 'aboutPage'
    '.general': 'generalPage'
    '.sync .signedin': 'signedin'
    '.sync .signedout': 'signedout'
    '.account .signedin': 'accsignedin'
    '.account .signedout': 'accsignedout'
    '#accusername': 'usernameinput'
    '#accpassword': 'passwordinput'
    '.account .signedin #pro': 'pro'
    '.account .signedin #alreadypro': 'alreadypro'

  events:
    'click .tabs li': 'tabs'
    'click .sync #signin': 'signin'
    'click .sync #signout': 'signout'
    'click .account #signin': 'accountSignin'
    'click .account #signout': 'accountSignout'

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

    setInterval () =>
      if Account.isSignedIn()
        @accsignedout.hide()
        @accsignedin.show()
        @accusername.text(Account.get().first_name + " " + Account.get().last_name)
        if Account.get().pro
          @pro.hide()
          @alreadypro.show()
      else
        @accsignedin.hide()
        @accsignedout.show()
        @pro.show()
        @alreadypro.hide()
    ,100

  accountSignin: ->
    if Account.signin(@usernameinput.val(), @passwordinput.val())
      if Account.isSignedIn()
        @hide()
        Account.enableChecks()
    else
      @signinacc.text "Wrong Username/Password"
      setTimeout () =>
        @signinacc.text "Sign in"
      , 5000


  accountSignout: ->
    Account.signout()

  tabs: (e) ->
    # This is ugly. Shoot me later. Could not think of a better implementation.
    @el.find('.current').removeClass 'current'
    @el.find('div.'+$(e.target).addClass('current').attr('data-id')).addClass 'current'

  show: (tab) ->
    return unless @state is off
    @state = on
    @el.show(0).addClass("show")
    setTimeout ( =>
      @el.on "click.modal", (event) =>
        if event.target.className.indexOf('modal') > -1 then @hide()
    ), 500

    if Account.isSignedIn()
      @accsignedin.show()
      @accsignedout.hide()
    else
      @accsignedout.show()
      @accsignedin.hide()

    if tab is not null
      $('.tabs ul li[data-id="'+tab+'"]').click()

  hide: ->
    return unless @state is on
    @state = off
    @el.removeClass("show")
    setTimeout ( => @el.hide(0)), 350
    @el.off("click.modal")

  signin: ->
    @signinbtn.text 'Connecting...'
    Sync.auth (data) =>
        shell.openExternal(data.url)

  signout: ->
    Sync.signOut()


settings = null # Temp

module.exports =

  get: ->
    return settings

  init: ->
    settings = new Settings
      el: $('.modal.preferences')
