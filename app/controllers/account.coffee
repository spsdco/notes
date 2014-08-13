Spine = require 'spine'

class Account
  constructor: ->

  @signin: (username, password) ->
    # Sign in to the Springseed API. It should return a token. Save it.
    localStorage.login = JSON.stringify {'username': username, 'password': password}
    if not username and not password
      # Try signing in with stored credidentials.
      $.get 'http://api.getspringseed.com/login', JSON.parse(localStorage.login), (data) =>
        if data['status'] is 200
          localStorage.token = data['token']
          return true # Logged in
        else if data['status'] > 400
          return false
    else
      # Try signing in with the credidentials we were given.
      $.get 'http://api.getspringseed.com/login', {'username': username, 'password', password}, (data) =>
        if data['status'] is 200
          localStorage.token = data['token']
          return true # Logged in
        else if data['status'] > 400
          return false

  @isSignedIn: () ->
    return true if localStorage.token
    return false if not localStorage.token

  @enableChecks: () ->
    $.get 'http://api.getspringseed.com/me', {token: localStorage.token}, (data) =>
      if data['status'] is 403
        # Get a new valid token - for the old one has expired.
        localStorage.removeItem 'token'
        @signin()
      else
        console.log data
        localStorage.data = JSON.stringify({'username': data.username, 'first_name': data.first_name, 'last_name': data.last_name, 'pro': data.pro})
    setTimeout(@enableChecks, 300000);

  @get: () ->
    return JSON.parse(localStorage.data)

  @signout: () ->
    localStorage.removeItem 'token'
    localStorage.removeItem 'login'

module.exports = Account
