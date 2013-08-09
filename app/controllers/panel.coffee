Spine = require 'spine'

# Node-Webkit. IMPORTANT NOTE: USE WINDOW.REQUIRE
win = window.require('nw.gui').Window.get() if window.require

class Panel extends Spine.Controller
  events:
    "click #decor img": "windowcontrol"

  constructor: ->
    super

  windowcontrol: (e) ->
    switch e.currentTarget.className
      when "close"
        win.close()
      when "minimize"
        win.minimize()
      when "maximize"
        win.maximize()

module.exports = Panel
