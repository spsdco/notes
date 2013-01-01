$ ->
	node = false

	# Node Webkit Stuff
	try
		gui = require 'nw.gui'
		fs = require 'fs'
		path = require 'path'

		# Show Window
		win = gui.Window.get()
		win.show()
		win.showDevTools()

		$('#close').click ->
			win.close();
		$('#minimize').click ->
			win.minimize();
		$('#maximize').click ->
			win.maximize()

		node = true
	catch e
		console.log("We're not running under node-webkit.")



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
		fs.readFile '/Users/jono/file.txt', 'utf-8', (err, data) ->
			throw err if (err)
			window.noted.editor.importFile('file', data)
	else
		window.noted.editor.importFile('file', "Not running under node webkit")
	window.noted.editor.preview()

window.noted = {}
