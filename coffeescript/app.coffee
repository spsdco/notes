global.document		= document
gui = global.gui	= require 'nw.gui'
buffer 				= require 'buffer'
path 				= require 'path'
ncp 				= require('ncp').ncp
util 				= require 'util'
global.jQuery = $	= require 'jQuery'
Dropbox 			= require 'dropbox'
handlebars			= require 'handlebars'
marked				= require 'marked'
S					= require 'string'
db 					= require './javascript/db'
Splitter 			= require './javascript/lib/splitter'
modal 				= require './javascript/lib/modal'
autogrow			= require './javascript/lib/autogrow'
rangyinputs			= require './javascript/lib/rangyinputs'

# Accepts a jQuery Selector
class jonoeditor
	constructor: (@el) ->
		@el.prop("disabled", false)

		# Add the editor to the dom
		@el.html("<textarea></textarea>")
		@el.find("textarea").autogrow()

	getReadOnly: ->
		@el.prop("disabled")

	setReadOnly: (bool) ->
		@el.prop("disabled", bool)

	getValue: ->
		@el.find("textarea").val()

	setValue: (value) ->
		@el.find("textarea").val(value)

	hide: ->
		@el.hide()

	show: ->
		@el.show()

window.noted =

	currentList: "all"
	currentNote: ""

	auth: ->
		# if there are creds, try get the users info
		if window.localStorage.oauth
			window.client.oauth = new Dropbox.Oauth JSON.parse(localStorage.oauth)
			window.client.getUserInfo (err, info) ->
				if err
					localStorage.removeItem "oauth"
					return console.warn(error)
				# If we get to here, the user is successfully authed!
				window.noted.db.client = window.client
				console.log info
		else
			window.client.authenticate (error, client) ->
				return console.warn(error) if error
				localStorage.oauth = JSON.stringify(client.oauth)
				window.noted.auth()

	init: ->
		# Make variables. Do checks.
		window.noted.homedir = process.env.HOME

		# Set up where we're going to store stuff.
		if process.platform is 'darwin'
			window.noted.storagedir = path.join(window.noted.homedir, "/Library/Application Support/Noted/")
		else if process.platform is 'win32'
			window.noted.storagedir = path.join(process.env.LOCALAPPDATA, "/Noted/")
		else if process.platform is 'linux'
			window.noted.storagedir = path.join(window.noted.homedir, '/.config/Noted/')

		window.localStorage.queue ?= "{}"
		window.localStorage.cursor ?= ""

		# Create the DB
		window.noted.db = new db(path.join(window.noted.storagedir, "Notebooks"), null, "queue", window.localStorage.cursor)

		# Setup Dropbox
		window.client = new Dropbox.Client {
			key: "GCLhKiJJwJA=|5dgkjE/gvYMv09OgvUpzN1UoNir+CfgY36WwMeNnmQ==",
			sandbox: true
		}
		window.client.authDriver(new Dropbox.Drivers.NodeServer(8191))

		# Pass control onto the initUI function.
		window.noted.initUI()

	initUI: ->
		Splitter.init
			parent: $('#parent')[0],
			panels:
				left:
					el: $("#notebooks")[0]
					min: 150
					width: 200
					max: 450
				center:
					el: $("#notes")[0]
					min: 250
					width: 300
					max: 850
				right:
					el: $("#content")[0]
					min: 450
					width: 550
					max: Infinity

		window.noted.window = gui.Window.get()
		window.noted.window.show()
		window.noted.window.showDevTools()
		window.noted.load.notebooks()

		window.noted.editor = new jonoeditor($("#contentwrite"))

		$('.modal.settings .false').click ->
			$('.modal.settings').modal "hide"

		$('#panel').mouseenter(->
			$('#panel').addClass('drag')
		).mouseleave ->
			$('#panel').removeClass('drag')

		# # Disallows Dragging on Buttons
		$('#panel #decor img, #panel #noteControls img, #panel #search').mouseenter(->
			$('#panel').removeClass('drag')
		).mouseleave ->
			$('#panel').addClass('drag')

		$('#noteControls img').click ->
			if $(@).attr("id") is "new" and window.noted.currentList isnt "all"

				window.noted.db.createNote("Untitled Note", window.noted.currentList, "# This is your new blank note\n\nAdd some content!")
				window.noted.load.notes(window.noted.currentList)

				$("#notes ul li:first").addClass("edit").trigger "click"

			else if !$("#noteControls").hasClass("disabled")
				if $(@).attr("id") is "share"
					# Moves thing into correct position
					$(".popover-mask").show()
					$(".share-popover").css({left: ($(event.target).offset().left)-3, top: "28px"}).show()
					mailto = "mailto:?subject=" + encodeURI(window.noted.currentNote) + "&body=" + encodeURI(window.noted.editor.getValue())
					$("#emailNote").parent().attr("href", mailto)

				else if $(@).attr("id") is "del"
					$('.modal.delete').modal()

		$(".modal.delete .true").click ->
			$('.modal.delete').modal "hide"
			if window.noted.currentNote isnt ""
				$("#notes li[data-id=" + window.noted.currentNote + "]").remove()
				window.noted.db.deleteNote(window.noted.currentNote)
				window.noted.deselect()

		$(".modal.delete .false").click ->
			$(".modal.delete").modal "hide"

		$(".modal.deleteNotebook .true").click ->
			$('.modal.deleteNotebook').modal "hide"
			window.noted.db.deleteNotebook(window.noted.currentList)
			$("#notebooks li[data-id=" + window.noted.currentList + "]").remove()
			$("#notebooks li").first().trigger("click")

		$(".modal.renameNotebook .true").click ->
			$('.modal.renameNotebook').modal "hide"
			name = $('.modal.renameNotebook input').val()
			if name isnt ""
				window.noted.db.updateNotebook(window.noted.currentList, {name: name})
				$("#notebooks li[data-id=" + window.noted.currentList + "]").text(name)

		$(".modal.deleteNotebook .false").click ->
			$(".modal.deleteNotebook").modal "hide"

		$(".modal.renameNotebook .false").click ->
			$(".modal.renameNotebook").modal "hide"

		$('body').on "click", "#close", ->
			window.noted.window.close()

		$('body').on "click", "#minimize", ->
			window.noted.window.minimize()

		$('body').on "click", "#maximize", ->
			window.noted.window.maximize()

		$('body').on "keydown", "#notebooks input", (e) ->
			if e.keyCode is 13
				e.preventDefault()

				# Create Notebook
				window.noted.db.createNotebook(name)
				window.noted.load.notebooks()

				# Clear input box
				$(this).val("").blur()

		$('body').on "click contextmenu", "#notebooks li", ->
			$("#noteControls").addClass("disabled")
			$(@).parent().find(".selected").removeClass "selected"
			$(@).addClass "selected"
			window.noted.load.notes($(@).attr("data-id"))
			window.noted.deselect()

		$('body').on "contextmenu", "#notebooks li", (e) ->
			# Moves thing into correct position
			$(".popover-mask").show()
			$(".delete-popover").css({left: $(event.target).outerWidth(), top: $(event.target).offset().top}).show()

		$('body').on "click contextmenu", ".popover-mask", ->
			$(@).hide().children().hide()

		$("#sync").click ->
			window.noted.auth()

		$("body").on "keydown", ".headerwrap .left h1", (e) ->
			if e.keyCode is 13 and $(@).text() isnt ""
				e.preventDefault()

		$("body").on "keyup change", ".headerwrap .left h1", ->
			# We can't have "".txt
			name = $(@).text()
			if name isnt ""
				$("#notes [data-id='" + window.noted.currentNote + "']").find("h2").text(name)

		$('body').on "click", "#notes li", ->
			$("#noteControls").removeClass("disabled")
			$("#notes .selected").removeClass("selected")
			$(@).addClass("selected")

			# Loads Actual Note
			window.noted.load.note($(@).attr("data-id"))

		$('body').on "click", "#deleteNotebook", ->
			$('.modal.deleteNotebook').modal()

		$('body').on "click", "#renameNotebook", ->
			name = $(".popover-mask").attr("data-parent")
			$('.modal.renameNotebook').modal()
			$('.modal.renameNotebook input').val(name).focus()

		$("#content .edit").click window.noted.editMode

		$("body").on "click", ".editorbuttons button", ->
			window.noted.editorAction $(@).attr('data-action')

	editorAction: (action) ->
		# I'm sure that mh0 doesn't know how to code.
		# Cache Selector
		$area = $('#contentwrite textarea')
		sel = $area.getSelection()

		if action is 'bold'
			$area.setSelection(sel.start - 2, sel.end + 2) # Surround the "**".
			newsel = $area.getSelection()
			if S(newsel.text).endsWith("**") and S(newsel.text).startsWith("**")
				$area.deleteText(newsel.start, newsel.start+2)
				$area.deleteText(newsel.end-4, newsel.end-2)
				$area.setSelection(sel.start-2, sel.end-2)
			else
				$area.setSelection(sel.start, sel.end)
				$area.surroundSelectedText("**","**")

		else if action is 'italics'
			$area.setSelection(sel.start - 1, sel.end + 1) # Surround the "**".
			newsel = $area.getSelection()
			if S(newsel.text).endsWith("*") and S(newsel.text).startsWith("*")
				$area.deleteText(newsel.start, newsel.start+1)
				$area.deleteText(newsel.end-2, newsel.end-1)
				$area.setSelection(sel.start-1, sel.end-1)
			else
				$area.setSelection(sel.start, sel.end)
				$area.surroundSelectedText("*","*")

		else if action is 'hyperlink'
			url = prompt("Enter the URL of the hyperlink","")
			$area.surroundSelectedText("[","]("+url+")")

		else if action is 'heading'
			$area.setSelection(sel.start - 2, sel.end) # Surround the "**".
			newsel1 = $area.getSelection()
			$area.setSelection(sel.start - 3, sel.end) # Surround the "**".
			newsel2 = $area.getSelection()
			$area.setSelection(sel.start - 4, sel.end) # Surround the "**".
			newsel3 = $area.getSelection()

			if S(newsel3.text).startsWith("### ")
				$area.deleteText(newsel3.start, newsel3.start+4)
				$area.setSelection(sel.start-4, sel.end-4)

			else if S(newsel2.text).startsWith("## ")
				$area.deleteText(newsel2.start, newsel2.start+3)
				$area.setSelection(sel.start-3, sel.end-3)
				$area.surroundSelectedText("### ","")

			else if S(newsel1.text).startsWith("# ")
				$area.deleteText(newsel1.start, newsel1.start+2)
				$area.setSelection(sel.start-2, sel.end-2)
				$area.surroundSelectedText("## ","")

			else
				$area.setSelection(sel.start, sel.end)
				$area.surroundSelectedText("# ","")

		else if action is 'img'
			url = prompt("Enter the URL of the image","")
			$area.surroundSelectedText("![","]("+url+")")

	deselect: ->
		$("#content").addClass("deselected")
		window.noted.currentNote = ""

	editMode: (mode) ->
		el = $("#content .edit")
		$("#content").removeClass("deselected")

		if mode is "preview" or window.noted.editor.getReadOnly() is false and mode isnt "editor"

			el.removeClass("save").text "edit"
			$('#content .left h1').attr('contenteditable', 'false')
			$("#content .right time").show()

			$("#contentread").html(marked(window.noted.editor.getValue())).show()
			$("#content .editorbuttons").removeClass("show")
			window.noted.editor.hide()
			window.noted.editor.setReadOnly(true)
			window.noted.save()
		else
			el.addClass("save").text "save"
			$('.headerwrap .left h1').attr('contenteditable', 'true')
			$("#content .right time").hide()

			$("#contentread").hide()
			$("#content .editorbuttons").addClass("show")
			window.noted.editor.show()
			window.noted.editor.setReadOnly(false)

			# So the autogrow thing works
			$(window).trigger("resize")

	save: ->
		# Make sure a note is selected
		if window.noted.currentNote isnt ""
			text = $('.headerwrap .left h1').text()
			text = "Untitled Note" if text is ""

			window.noted.db.updateNote window.noted.currentNote, {
					name: text
					content: window.noted.editor.getValue()
					notebook: window.noted.currentList
				}

	load:
		notebooks: ->
			template = handlebars.compile($("#notebook-template").html())
			htmlstr = template({name: "All Notes", id: "all"})

			arr = window.noted.db.readNotebooks(true)
			arr.forEach (notebook) ->
				htmlstr += template {name: notebook.name, id: notebook.id}

			# Append the string to the dom (perf matters.)
			$("#notebooks ul").html(htmlstr)

		notes: (list, type) ->
			window.noted.currentList = list

			# Templates :)
			template = handlebars.compile($("#note-template").html())
			htmlstr = ""

			if list is "all"
				# TODO: There will be some proper code in here soon
				htmlstr = "I broke all notes because of the shitty implementation"
			else
				data = window.noted.db.readNotebook(list, true)
				order = []

				data.contents.forEach (file) ->
					# Makes a pretty Excerpt
					if file.info.length > 90
						lastIndex = file.info.lastIndexOf(" ")
						file.info = file.info.substring(0, lastIndex) + "&hellip;"

					# Rips out ugly markdown
					file.info = $(marked(file.info)).text()

					order.push {
						id: file.id,
						date: file.date * 1000
						name: file.name
						info: file.info
					}

				# Sorts all the notes by time
				order.sort (a, b) ->
					return new Date(a.time) - new Date(b.time)

				# Appends to DOM
				for note in order
					htmlstr = template({
						id: note.id
						name: note.name
						list: list
						date: window.noted.util.date(note.date)
						excerpt: note.info
						}) + htmlstr

			$("#notes ul").html(htmlstr)

		note: (id) ->
			window.noted.currentNote = id
			data = window.noted.db.readNote(id)

			$('.headerwrap .left h1').text(data.name)
			$("#contentread").html(marked(data.content)).show()
			window.noted.editor.setValue(data.content)
			window.noted.editor.setReadOnly(true)

			time = new Date(data.date * 1000)
			$('.headerwrap .right time').text(
				window.noted.util.date(time)+" "+
				window.noted.util.pad(time.getHours())+":"+
				window.noted.util.pad(time.getMinutes())
			)

			window.noted.editMode("preview")

	util:
		date: (date) ->
			date = new Date(date)

			month = [
				"Jan"
				"Feb"
				"Mar"
				"Apr"
				"May"
				"Jun"
				"Jul"
				"Aug"
				"Sep"
				"Oct"
				"Nov"
				"Dec"
			]

			now = new Date()
			difference = 0
			oneDay = 86400000; # 1000*60*60*24 - one day in milliseconds
			words = ''

			# Find difference between days
			difference = Math.ceil((date.getTime() - now.getTime()) / oneDay)
			console.log difference

			# Show difference nicely
			if difference is 0
				words = "Today"

			else if difference is -1
				words = "Yesterday"

			else if difference > 0
				# If the user has a TARDIS
				words = "In " + difference + " days"

			else if difference > -15
				words = Math.abs(difference) + " days ago"

			else if difference > -365
				words = month[date.getMonth()] + " " + date.getDate()

			else
				words = window.noted.util.pad(date.getFullYear())+"-"+(window.noted.util.pad(date.getMonth()+1))+"-"+window.noted.util.pad(date.getDate())

			words #return

		pad: (n) ->
			# pad a single-digit number to a 2-digit number for things such as times or dates.
			(if (n < 10) then ("0" + n) else n)

window.noted.init()
