$ ->

	# Node Webkit Stuff
	try
		gui = require 'nw.gui'

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
			# Show restore button?
	catch e
		console.log("not running under node webkit")



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
	window.noted.editor.importFile('appnotes/Welcome.mdown', "Loading content...")
	window.noted.editor.preview()

window.noted = {}
