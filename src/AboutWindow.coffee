# Springseed. Simply awesome note taking.
# Copyright (c) 2014, Springseed Team
# All Rights Reserved.

electron = require "electron"
app = electron.app
BrowserWindow = electron.BrowserWindow

class AboutWindow
  constructor: (devtools) ->
    @window = new BrowserWindow
      'width': 400
      'height': 300
      'center': true
      'resizable': false
      'title': "About Springseed"

    @window.loadURL "file://#{__dirname}/../public/about.html"

    @window.on "closed",  ->
      @window = null # Dereference the window.

module.exports = AboutWindow
