# Node Webkit Stuff
try
	gui = require 'nw.gui'
	fs = require 'fs'
	path = require 'path'
	ncp = require('ncp').ncp
	util = require 'util'

	node = true
	home_dir = process.env.HOME

	# Set Up Storage - are there env variables for these?
	if process.platform is "darwin"
		storage_dir = path.join(home_dir, "/Library/Application Support/Noted/")
	else if process.platform is "win32"
		storage_dir = path.join(process.env.LOCALAPPDATA, "/Noted")
	else if process.platform is "linux"
		storage_dir = path.join(home_dir, "/.config/Noted/")


# Proper Functions
window.noted =

	selectedList: "all"
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
			window.noted.deselectNote()

		$('body').on "keydown", "#notebooks input", (e) ->
			# Deny the enter key
			if e.keyCode is 13
				e.preventDefault()
				fs.mkdir(path.join(storage_dir, "Notebooks", $('#notebooks input').val()))
				# Reload Notebooks.
				# TODO: window.noted.listNotebooks()
				$('#notebooks input').val("")

				setTimeout ( ->
					$('#notebooks input').blur()
				), 50

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
				# Reload to reveal new timestamp
				# TODO: window.noted.loadNotes(window.noted.selectedList)

		# Add note modal dialogue.
		$('#new').click ->
			if window.noted.selectedList isnt "All Notes"
				$("#notes ul").append "<li data-id='Untitled Note' data-list='" + window.noted.selectedList + "'><h2>Untitled Note</h2><time></time></li>"
				defaultcontent = "Add some content!"
				fs.writeFile(path.join(storage_dir, "Notebooks", window.noted.selectedList, 'Untitled Note.txt'), defaultcontent)

		$('#del').click ->
			window.noted.editor.remove('file')
			fs.unlink path.join(storage_dir, "Notebooks", $("#notes li[data-id='" + window.noted.selectedNote + "']").attr("data-list"), window.noted.selectedNote + '.txt'), (err) ->
				throw err if (err)
				window.noted.deselectNote()
				window.noted.loadNotes(window.noted.selectedList)

	render: ->

		# Lists the New Notebooks & Shows Selected
		window.noted.listNotebooks()



	listNotebooks: ->
		console.log "NoteBooks Called"
		# Clear & Add All Notes
		$("#notebooks ul").html("").append "<li class='all'>All Notes</li>"
		fs.readdir path.join(storage_dir, "Notebooks"), (err, data) ->
			i = 0
			while i < data.length
				if fs.statSync(path.join(storage_dir, "Notebooks", data[i])).isDirectory()
					$("#notebooks ul").append "<li data-id='" + data[i] + "'>" + data[i] + "</li>"
				i++

			# Add Selected Class to the Right Notebook
			if window.noted.selectedList is "all"
				$("#notebooks .all").trigger("click")
			else
				$("#notebooks [data-id='" + window.noted.selectedList + "']").addClass("selected").trigger("click")
		# window.noted.listTags()

	loadNotes: (name, type) ->
		console.log "Notes Called"
		if name is "All Notes"
			window.noted.selectedList = name
			$("#notes ul").html("")
			fs.readdir path.join(storage_dir, "Notebooks"), (err, data) ->
				i = 0
				while i < data.length
					if fs.statSync(path.join(storage_dir, "Notebooks", data[i])).isDirectory()
						window.noted.loadNotes(data[i], "all")
					i++
		else
			# Clear list while we load.
			if type isnt "all"
				window.noted.selectedList = name
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
						noteTime = fs.statSync(path.join(storage_dir,"Notebooks",name,noteName+'.txt'))['ctime']
						time = new Date(Date.parse(noteTime))
						$("#notes ul").append "<li data-id='" + noteName + "' data-list='" + name + "'><h2>" + noteName + "</h2><time>"+time.getDate()+"/"+(time.getMonth()+1)+"/"+time.getFullYear()+"</time></li>"
					i++

	loadNote: (selector) ->
		console.log "Notes Called"
		# Caches Selected Note and List
		window.noted.selectedNote = $(selector).find("h2").text()

		# Opens ze note
		fs.readFile path.join(storage_dir, "Notebooks", $(selector).attr("data-list"), window.noted.selectedNote + '.txt'), 'utf-8', (err, data) ->
			throw err if (err)
			$("#content").removeClass("deselected")
			$('.headerwrap .left h1').text(window.noted.selectedNote)
			noteTime = fs.statSync(path.join(storage_dir, "Notebooks", $(selector).attr("data-list"), window.noted.selectedNote + '.txt'))['ctime']
			time = new Date(Date.parse(noteTime))
			$('.headerwrap .left time').text(window.noted.timeControls.pad(time.getDate())+"/"+(window.noted.timeControls.pad(time.getMonth()+1))+"/"+time.getFullYear()+" "+window.noted.timeControls.pad(time.getHours())+":"+window.noted.timeControls.pad(time.getMinutes()))
			window.noted.editor.importFile('file', data)
			window.noted.editor.preview()

	deselectNote: ->
		$("#content").addClass("deselected")
		$("#content .left h1, #content .left time").text("")
		window.noted.selectedNote = ""
		window.noted.editor.importFile('file', "")
		window.noted.editor.preview()

window.noted.timeControls =
	pad: (n) ->
		(if (n < 10) then ("0" + n) else n)

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
