# Springseed. Simply awesome note taking.
# Copyright (c) 2014, Springseed Team
# All Rights Reserved.
electron = require "electron"
app = electron.app
SpringseedWindow = require './Springseed'

app.on 'ready', ->
  window = new SpringseedWindow()

app.on 'window-all-closed', ->
  app.quit()

app.on 'activate-with-no-open-windows', ->
  window = new SpringseedWindow()
