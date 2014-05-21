# Springseed. Simply awesome note taking.
# Copyright (c) 2014, Springseed Team
# All Rights Reserved.

app 			= require "app"
BrowserWindow 	= require "browser-window"

class SpringseedWindow
	constructor: (devtools) ->
		@window = new BrowserWindow
			width: 1024
			height: 600
			min-width: 500
			min-height: 300
			center: true
			title: "Springseed"
			frame: false