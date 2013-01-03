$ ->
	node = false

	# Node Webkit Stuff
	try
		gui = require 'nw.gui'
		fs = require 'fs'
		path = require 'path'
		ncp = require('ncp').ncp

		# Show Window
		win = gui.Window.get()
		win.show()
		win.showDevTools()

		# Panel Controls
		$('#close').click ->
			win.close()
		$('#minimize').click ->
			win.minimize()
		$('#maximize').click ->
			win.maximize()

		# Panel Dragging
		$('#panel').mouseenter ->
			$('#panel').addClass('drag')
		$('#panel #decor img, #panel #noteControls img, #panel #search').mouseenter ->
			$('#panel').removeClass('drag')
		$('#panel #decor img, #panel #noteControls img, #panel #search').mouseleave ->
			$('#panel').addClass('drag')
		$('#panel').mouseleave ->
			$('#panel').removeClass('drag')

		# OS Detection
		OSName = "Unknown OS"
		OSName = "Windows"  unless navigator.appVersion.indexOf("Win") is -1
		OSName = "Mac"  unless navigator.appVersion.indexOf("Mac") is -1
		OSName = "UNIX"  unless navigator.appVersion.indexOf("X11") is -1
		OSName = "Linux"  unless navigator.appVersion.indexOf("Linux") is -1

		node = true
		home_dir = process.env.HOME

		# Set Up Storage Stuffs
		if OSName is "Mac"
			storage_dir = path.join(home_dir, "/Library/Application Support/Noted/")
		if OSName is "Windows"
			#Microsoft y u so inconsistant? - Don't assume /AppData - XP uses /Application Data - Use ENV variable
			storage_dir = path.join(process.env.LOCALAPPDATA, "/Noted")
		if OSName is "Linux"
			storage_dir = path.join(home_dir, "/.config/Noted/")

	catch e
		console.log("We're not running under node-webkit.")

	console.log(storage_dir)

	# Event Handlers
	$("#content header .edit").click ->

		# There should be a better way to do this
		if $(this).text() is "save"
			$(this).text "edit"
			window.noted.editor.preview()
		else
			$(this).text "save"
			window.noted.editor.edit()

	# Create Markdown Editor
	window.noted.editor = new EpicEditor
		container: 'contentbody'
		theme:
    		base:'/themes/base/epiceditor.css'
    		preview:'/themes/preview/style.css'
		    editor:'/themes/editor/style.css'

	window.noted.editor.load()

	if node

		# If the notebooks file isn't made, we'll make some sample notes
		fs.readdir path.join(storage_dir, "/Notebooks/"), (err, data) ->
			if err.code is "ENOENT"
				fs.mkdir path.join(storage_dir, "/Notebooks/"), ->
					# Copy over the default notes
		      		ncp path.join(window.location.pathname, "../default_notebooks"), path.join(storage_dir, "/Notebooks/"), (err) ->
						console.log 'done'


	# 	fs.readFile path.join(storage_dir, 'file.txt'), 'utf-8', (err, data) ->
	# 		throw err if (err)
	# 		window.noted.editor.importFile('file', data)
	# 		window.noted.editor.preview()
	# else
	# 	window.noted.editor.importFile('file', "Not running under node webkit")
	# 	window.noted.editor.preview()

window.noted = {}
