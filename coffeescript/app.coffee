# Node Webkit Stuff
try
	gui = require 'nw.gui'
	fs = require 'fs'
	path = require 'path'
	ncp = require('ncp').ncp

	# OS Detection
	OSName = "Unknown OS"
	OSName = "Windows"  unless navigator.appVersion.indexOf("Win") is -1
	OSName = "Mac"  unless navigator.appVersion.indexOf("Mac") is -1
	OSName = "UNIX"  unless navigator.appVersion.indexOf("X11") is -1
	OSName = "Linux"  unless navigator.appVersion.indexOf("Linux") is -1

	node = true
	home_dir = process.env.HOME

	# Set Up Storage - are there env variables for these?
	if OSName is "Mac"
		storage_dir = path.join(home_dir, "/Library/Application Support/Noted/")
	if OSName is "Windows"
		storage_dir = path.join(process.env.LOCALAPPDATA, "/Noted")
	if OSName is "Linux"
		storage_dir = path.join(home_dir, "/.config/Noted/")


# Proper Functions
window.noted =

	selectedList: "Getting Started"
	selectedNote: ""

	setupPanel: ->
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
		$('#panel').mouseenter(->
			$('#panel').addClass('drag')
		).mouseleave ->
			$('#panel').removeClass('drag')

		# Disallows Dragging on Buttons
		$('#panel #decor img, #panel #noteControls img, #panel #search').mouseenter(->
			$('#panel').removeClass('drag')
		).mouseleave ->
			$('#panel').addClass('drag')

	setupUI: ->
		# Event Handlers
		$("#content header .edit").click ->

			# There should be a better way to do this
			if $(this).text() is "save"

				$(this).text "edit"
				$('.headerwrap .left h1').attr('contenteditable', 'false')
				window.noted.editor.save()

				# Reload Notes.
				window.noted.loadNotes(window.noted.selectedList)
				window.noted.editor.preview()
			else
				$(this).text "save"
				$('.headerwrap .left h1').attr('contenteditable', 'true')
				window.noted.editor.edit()

		# Notebooks Click
		$("body").on "click", "#notebooks li", ->
			$(this).parent().find(".selected").removeClass "selected"
			$(this).addClass "selected"
			window.noted.loadNotes($(this).text())

		# Notes Click
		$("body").on "click", "#notes li", ->
			# UI
			$("#notes .selected").removeClass("selected")
			$(this).addClass("selected")

			# Loads Actual Note
			window.noted.loadNote($(this))

		# Because we can't prevent default on keyup
		$("body").on "keydown", ".headerwrap .left h1", (e) ->
			# Deny the enter key
			if e.keyCode is 13
				e.preventDefault()
				$(this).blur()

		$("body").on "keyup", ".headerwrap .left h1", (e) ->
			# We can't have "".txt
			if $(this).text() isnt ""
				$("#notes [data-id='" + window.noted.selectedNote + "']")
					.attr("data-id", $(this).text()).find("h2").text($(this).text())

				# Renames the Note
				fs.rename(
					path.join(
						storage_dir,
						"Notebooks",
						window.noted.selectedList,
						window.noted.selectedNote + '.txt'
					),
					path.join(
						storage_dir,
						"Notebooks",
						window.noted.selectedList,
						$(this).text() + '.txt'
					)
				)

				window.noted.selectedNote = $(this).text()

		# Create Markdown Editor
		window.noted.editor = new EpicEditor
			container: 'contentbody'
			file:
				name: 'epiceditor',
				defaultContent: '',
				autoSave: 2500
			theme:
				base:'/themes/base/epiceditor.css'
				preview:'/themes/preview/style.css'
				editor:'/themes/editor/style.css'

		window.noted.editor.load()

		window.noted.editor.on "save", (e) ->
			list = $("#notes li[data-id='" + window.noted.selectedNote + "']").attr "data-list"
			# Make sure a note is selected
			if window.noted.selectedNote isnt ""
				fs.writeFile(path.join(
					storage_dir,
					"Notebooks",
					list,
					window.noted.selectedNote + '.txt'
				), e.content)

		# Add note modal dialogue.
		$('#new').click ->
			if window.noted.selectedList isnt "All Notes"
				$("#notes ul").append "<li data-id='Untitled Note' data-list='" + window.noted.selectedList + "'><h2>Untitled Note</h2><time></time></li>"
				defaultcontent = "Add some content!"
				fs.writeFile(path.join(storage_dir, "Notebooks", window.noted.selectedList, 'Untitled Note.txt'), defaultcontent)

		$('#del').click ->
			window.noted.editor.remove('file')
			$('.headerwrap .left h1').html("No note selected")
			fs.unlink path.join(storage_dir, "Notebooks", window.noted.selectedList, window.noted.selectedNote + '.txt'), (err) ->
				throw err if (err)
				window.noted.loadNotes(window.noted.selectedList)

	render: ->

		# Lists the New Notebooks & Shows Selected
		window.noted.listNotebooks()



	listNotebooks: ->
		# Clear & Add All Notes
		$("#notebooks ul").html("").append "<li class='all'>All Notes</li>"
		fs.readdir path.join(storage_dir, "Notebooks"), (err, data) ->
			i = 0
			while i < data.length
				if fs.statSync(path.join(storage_dir, "Notebooks", data[i])).isDirectory()
					$("#notebooks ul").append "<li data-id='" + data[i] + "'>" + data[i] + "</li>"
				i++

			# Add Selected Class to the Right Notebook
			$("#notebooks [data-id='" + window.noted.selectedList + "']").addClass("selected").trigger("click")

	loadNotes: (name, type) ->
		if name is "All Notes"
			fs.readdir path.join(storage_dir, "Notebooks"), (err, data) ->
				i = 0
				while i < data.length
					if fs.statSync(path.join(storage_dir, "Notebooks", data[i])).isDirectory()
						window.noted.loadNotes(data[i], "all")
					i++
		else
			window.noted.selectedList = name
			# Clear list while we load.
			if type isnt "all"
				$("#notes header h1").html(name)
				$("#notes ul").html("")
			else
				$("#notes header h1").html("All Notes")

			fs.readdir path.join(storage_dir, "Notebooks", name), (err, data) ->
				i = 0
				while i < data.length
					# Makes sure that it is a text file
					if data[i].substr(data[i].length - 4, data[i].length) is ".txt"

						# Removes txt extension
						noteName = data[i].substr(0, data[i].length - 4)
						$("#notes ul").append "<li data-id='" + noteName + "' data-list='" + name + "'><h2>" + noteName + "</h2><time></time></li>"
					i++

	loadNote: (selector) ->
		# Caches Selected Note and List
		window.noted.selectedNote = $(selector).find("h2").text()

		# Opens ze note
		fs.readFile path.join(storage_dir, "Notebooks", $(selector).attr("data-list"), window.noted.selectedNote + '.txt'), 'utf-8', (err, data) ->
			throw err if (err)
			$('.headerwrap .left h1').text(window.noted.selectedNote)
			window.noted.editor.importFile('file', data)
			window.noted.editor.preview()

# Document Ready Guff
$ ->
	window.noted.setupUI()

	if node
		window.noted.setupPanel()

		# If the notebooks file isn't made, we'll make some sample notes
		fs.readdir path.join(storage_dir, "/Notebooks/"), (err, data) ->
			if err
				if err.code is "ENOENT"
					fs.mkdir path.join(storage_dir, "/Notebooks/"), ->
						# Copy over the default notes & render
						ncp path.join(window.location.pathname, "../default_notebooks"), path.join(storage_dir, "/Notebooks/"), (err) ->
							window.noted.render()
			else
				window.noted.render()
