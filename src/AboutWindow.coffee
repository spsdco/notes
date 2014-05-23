# Springseed. Simply awesome note taking.
# Copyright (c) 2014, Springseed Team
# All Rights Reserved.

app 			= require "app"
BrowserWindow 	= require "browser-window"

class AboutWindow
  constructor: (devtools) ->
    @window = new BrowserWindow
      'width': 400
      'height': 300
      'center': true
      'title': "About Springseed"

    @window.loadUrl "file://"+__dirname+"/../public/about.html"

    @window.on "closed",  ->
      @window = null # Dereference the window.

module.exports = AboutWindow
