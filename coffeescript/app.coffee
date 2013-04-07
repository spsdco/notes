global.document		= document
gui = global.gui	= require 'nw.gui'
fs 					= require 'fs'
buffer 				= require 'buffer'
path 				= require 'path'
ncp 				= require('ncp').ncp
util 				= require 'util'
global.jQuery = $	= require 'jQuery'
handlebars			= require 'handlebars'
marked				= require 'marked'
Splitter 			= require './javascript/lib/splitter'
modal 				= require './javascript/lib/modal'
autogrow			= require './javascript/lib/autogrow'
rangyinputs			= require './javascript/lib/rangyinputs'
hotkeys				= require './javascript/lib/hotkeys'

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

	init: ->
		# Make variables. Do checks.
		window.noted.homedir = process.env.HOME
		window.noted.resvchar = [186, 191, 220, 222, 106, 56]
		window.noted.storagedir = window.noted.osdirs()

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
		window.noted.load.notes("All Notes")

		window.noted.editor = new jonoeditor($("#contentwrite"))

		# window.noted.editor.on "change", ->
		# 	$this = $("#contentwrite")
		# 	delay = 2000

		# 	clearTimeout $this.data('timer')
		# 	$this.data 'timer', setTimeout( ->
		# 		$this.removeData('timer')
		# 		window.noted.save()
		# 	, delay)

		# Key bindings
		$(document).bind 'keydown', "Ctrl+n", (e) ->
			window.noted.UIEvents.clickNewNote()
		$(document).bind 'keydown', "Alt+s",(e) ->
			$(".modal.settings").modal()

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

		$('#new').click ->
			window.noted.UIEvents.clickNewNote()

		$('#share').click ->
			window.noted.UIEvents.clickShareNote()

		$('#del').click ->
			window.noted.UIEvents.clickDelNote()

		$(".modal.delete .true").click ->
			window.noted.UIEvents.modalclickDel()

		$(".modal.delete .false").click ->
			$(".modal.delete").modal "hide"

		$(".modal.deleteNotebook .true").click ->
			window.noted.UIEvents.modalclickDelNotebook()

		$(".modal.renameNotebook .true").click ->
			window.noted.UIEvents.modalclickRenameNotebook()

		$(".modal.deleteNotebook .false").click ->
			$(".modal.deleteNotebook").modal "hide"

		$(".modal.renameNotebook .false").click ->
			$(".modal.renameNotebook").modal "hide"

		$('#close').click ->
			window.noted.UIEvents.titlebarClose()

		$('#minimize').click ->
			window.noted.UIEvents.titlebarMinimize()

		$('#maximize').click ->
			window.noted.UIEvents.titlebarMaximize()

		$('body').on "keydown", "#notebooks input", (e) ->
			window.noted.UIEvents.keydownNotebook(e)

		$('body').on "click contextmenu", "#notebooks li", ->
			window.noted.UIEvents.clickNotebook($(@))

		$('body').on "contextmenu", "#notebooks li", (e) ->
			window.noted.UIEvents.contextNotebook(e, $(@))
			false

		$('body').on "click contextmenu", ".popover-mask", ->
			$(@).hide().children().hide()

		$("body").on "keydown", ".headerwrap .left h1", (e) ->
			window.noted.UIEvents.keydownTitle(e, $(@))

		$("body").on "keyup", ".headerwrap .left h1", ->
			window.noted.UIEvents.keyupTitle($(@))

		$('body').on "click", "#notes li", ->
			window.noted.UIEvents.clickNote($(@))

		$('body').on "click", "#deleteNotebook", ->
			window.noted.UIEvents.deleteNotebook($(@))

		$('body').on "click", "#renameNotebook", ->
			window.noted.UIEvents.renameNotebook()

		$("#content .edit").click window.noted.editMode

		$("body").on "click", ".editorbuttons button", ->
			window.noted.editorAction $(@).attr('data-action')

	editorAction: (action) ->
		if action is 'bold'
			$('#contentwrite textarea').surroundSelectedText("**","**")
		else if action is 'italics'
			$('#contentwrite textarea').surroundSelectedText("*","*")

	deselect: ->
		$("#content").addClass("deselected")
		window.noted.currentNote = ""

	editMode: (mode) ->
		el = $("#content .edit")
		if mode is "preview" or window.noted.editor.getReadOnly() is false and mode isnt "editor"

			el.removeClass("save").text "edit"
			$('#content .left h1').attr('contenteditable', 'false')
			$("#content .right time").show()

			$("#contentread").html(marked(window.noted.editor.getValue())).show()
			$("#content .editorbuttons").hide()
			window.noted.editor.hide()
			window.noted.editor.setReadOnly(true)
			window.noted.save()
		else
			el.addClass("save").text "save"
			$('.headerwrap .left h1').attr('contenteditable', 'true')
			$("#content .right time").hide()

			$("#contentread").hide()
			$("#content .editorbuttons").show()
			window.noted.editor.show()
			window.noted.editor.setReadOnly(false)

			# So the autogrow thing works
			$(window).trigger("resize")

	save: ->
		list = $("#notes li[data-id='" + window.noted.currentNote + "']").attr "data-list"
		# Make sure a note is selected
		if window.noted.currentNote isnt ""

			notePath = path.join(
				window.noted.storagedir,
				"Notebooks",
				list,
				window.noted.currentNote + '.txt'
			)

			# Write file
			fs.writeFile(notePath, window.noted.editor.getValue())

			# Reload to reveal new timestamp
			# TODO: window.noted.loadNotes(window.noted.currentList)

	load:
		notebooks: ->
			template = handlebars.compile($("#notebook-template").html())
			htmlstr = template({name: "All Notes", class: "all"})

			fs.readdir path.join(window.noted.storagedir, "Notebooks"), (err, data) ->
				i = 0
				while i < data.length
					if fs.statSync(path.join(window.noted.storagedir, "Notebooks", data[i])).isDirectory()
						htmlstr += template({name: data[i]})
					i++

				# Append the string to the dom (perf matters.)
				$("#notebooks ul").html(htmlstr)
				$("#notebooks [data-id='" + window.noted.currentList + "'], #notebooks ." + window.noted.currentList).trigger("click")

		notes: (list, type, callback) ->
			window.noted.currentList = list

			# Templates :)
			template = handlebars.compile($("#note-template").html())
			htmlstr = ""

			if list is "All Notes"
				# TODO: There will be some proper code in here soon
				htmlstr = "I broke all notes because of the shitty implementation"
			else
				# It's easier doing @ without Async.
				data = fs.readdirSync path.join(window.noted.storagedir, "Notebooks", list)
				order = []
				i = 0

				while i < data.length
					# Makes sure that it is a text file
					if data[i].substr(data[i].length - 4, data[i].length) is ".txt"
						# Removes txt extension
						name = data[i].substr(0, data[i].length - 4)
						time = new Date fs.statSync(path.join(window.noted.storagedir, "Notebooks", list, name + '.txt'))['mtime']

						# Gets an excerpt
						fd = fs.openSync(path.join(window.noted.storagedir, "Notebooks", list, name + '.txt'), 'r')
						buffer = new Buffer(100)
						num = fs.readSync fd, buffer, 0, 100, 0
						info = $(marked(buffer.toString("utf-8", 0, num))).text()
						fs.close(fd)

						# Makes a pretty Excerpt
						if info.length > 90
							lastIndex = info.lastIndexOf(" ")
							info = info.substring(0, lastIndex) + "&hellip;"

						order.push {id: i, time: time, name: name, info: info}
					i++

				# Sorts all the notes by time
				order.sort (a, b) ->
					return new Date(a.time) - new Date(b.time)

				# Appends to DOM
				for note in order
					htmlstr = template({
						name: note.name
						list: list
						year: note.time.getFullYear()
						month: note.time.getMonth() + 1
						day: note.time.getDate()
						excerpt: note.info
						}) + htmlstr

			$("#notes ul").html(htmlstr)
			callback() if callback

		note: (selector) ->
			# Caches Selected Note and List
			window.noted.currentNote = $(selector).find("h2").text()

			# Opens ze note
			fs.readFile path.join(window.noted.storagedir, "Notebooks", $(selector).attr("data-list"), window.noted.currentNote + '.txt'), 'utf-8', (err, data) ->
				throw err if (err)
				$("#content").removeClass("deselected")
				$('.headerwrap .left h1').text(window.noted.currentNote)
				noteTime = fs.statSync(path.join(window.noted.storagedir, "Notebooks", $(selector).attr("data-list"), window.noted.currentNote + '.txt'))['mtime']
				time = new Date(Date.parse(noteTime))
				$('.headerwrap .right time').text(window.noted.util.pad(time.getFullYear())+"/"+(window.noted.util.pad(time.getMonth()+1))+"/"+time.getDate()+" "+window.noted.util.pad(time.getHours())+":"+window.noted.util.pad(time.getMinutes()))
				# BAD CODE: TODO: ^ This code is fucking shit. What were you thinking mh0?
				$("#contentread").html(marked(data)).show()
				window.noted.editor.setValue(data)
				window.noted.editor.setReadOnly(true)
				# Chucks it into the right mode - this was the best I could do.
				if selector.hasClass("edit")
					window.noted.editMode("editor")
					$("#content .left h1").focus()
					selector.removeClass("edit")
				else
					window.noted.editMode("preview")

	osdirs: ->
		# Set up where we're going to store stuff.
		if process.platform is 'darwin'
			path.join(window.noted.homedir, "/Library/Application Support/Noted/")
		else if process.platform is 'win32'
			path.join(process.env.LOCALAPPDATA, "/Noted/")
		else if process.platform is 'linux'
			path.join(window.noted.homedir, '/.config/Noted/')

	UIEvents:
		# To make life simpler, have <action><element> as a fucntion name: example: clickEdit for when you click $('.edit')
		clickNewNote: ->
			name = "Untitled Note"
			if window.noted.currentList isnt "All Notes"
				while fs.existsSync(path.join(window.noted.storagedir, "Notebooks", window.noted.currentList, name+".txt"))
					r = /\(\s*(\d+)\s*\)$/
					if r.exec(name) is null
						name = name+" (1)"
					else
						name = name.replace(" ("+r.exec(name)[1]+")", " ("+(parseInt(r.exec(name)[1])+1)+")")
				# Write to disk.
				fs.writeFile(
					path.join(
						window.noted.storagedir,
						"Notebooks",
						window.noted.currentList, name + '.txt'
					),
					"This is your new blank note\n====\nAdd some content!",
					->
						# FIXME: Function in a Function. Functionception (this is a bad idea).
						window.noted.load.notes window.noted.currentList, "", ->
							$("#notes ul li:first").addClass("edit").trigger "click"
				)

		clickShareNote: ->
			# Moves thing into correct position
			$(".popover-mask").show()
			$(".share-popover").css({left: ($(event.target).offset().left)-3, top: "28px"}).show()

		modalclickDel: ->
			$('.modal.delete').modal "hide"
			if window.noted.currentNote isnt ""
				fs.unlink(
					path.join(
						window.noted.storagedir,
						"Notebooks",
						$("#notes li[data-id='" + window.noted.currentNote + "']").attr("data-list"),
						window.noted.currentNote + '.txt'
					), (err) ->
						throw err if (err)
						window.noted.deselect()
						window.noted.load.notes(window.noted.currentList)
				)

		clickDelNote: ->
			$('.modal.delete').modal()

		titlebarClose: ->
			window.noted.window.close()

		titlebarMinimize: ->
			window.noted.window.minimize()

		titlebarMaximize: ->
			# TODO: Add unmaximizing
			window.noted.window.maximize()

		# Deny the enter key
		keydownNotebook: (e) ->
			name = $('#notebooks input').val()
			if e.keyCode is 13
				e.preventDefault()
				while fs.existsSync(path.join(window.noted.storagedir, "Notebooks", window.noted.currentList, name+'.txt')) is true
					regexp = /\(\s*(\d+)\s*\)$/
					if regexp.exec(name) is null
						name = name+" (1)"
					else
						name = name.replace(" ("+regexp.exec(name)[1]+")", " ("+(parseInt(regexp.exec(name)[1])+1)+")")
				fs.mkdir(path.join(window.noted.storagedir, "Notebooks", name))

				window.noted.load.notebooks()
				$('#notebooks input').val("").blur()

		clickNotebook: (element) ->
			element.parent().find(".selected").removeClass "selected"
			element.addClass "selected"
			window.noted.load.notes(element.text())
			window.noted.deselect()

		contextNotebook: (event, element) ->
			# Moves thing into correct position
			$(".popover-mask").show()
			# Probably very ugly, but add a data attribute of the Notebook that triggered this.
			$(".popover-mask").attr("data-parent", element.text())
			console.log element.text()
			$(".delete-popover").css({left: $(event.target).outerWidth(), top: $(event.target).offset().top}).show()


		keydownTitle: (e, element) ->
			if e.keyCode is 13 and element.text() isnt ""
				e.preventDefault()
				name = element.text()
				while fs.existsSync(path.join(window.noted.storagedir, "Notebooks", window.noted.currentList, name+'.txt'))
					r = /\(\s*(\d+)\s*\)$/
					if r.exec(name) is null
						name = name+" (1)"
					else
						name = name.replace(" ("+r.exec(name)[1]+")", " ("+(parseInt(r.exec(name)[1])+1)+")")

				fs.rename(
					path.join(
						window.noted.storagedir,
						"Notebooks",
						window.noted.currentList,
						window.noted.currentNote + '.txt'
					),
					path.join(
						window.noted.storagedir,
						"Notebooks",
						window.noted.currentList,
						name + '.txt'
					)
				)
				window.noted.currentNote = name;
				window.noted.load.notes(window.noted.currentList)
				element.blur()
			else if e.keyCode in window.noted.resvchar
				e.preventDefault()

		keyupTitle: (element) ->
			# We can't have "".txt
			name = element.text()

			if name isnt ""

				$("#notes [data-id='" + window.noted.currentNote + "']")
					.attr("data-id", name).find("h2").text(element.text())

				path.join(window.noted.storagedir,"Notebooks",window.noted.currentList,window.noted.currentNote + '.txt')
				path.join(window.noted.storagedir,"Notebooks",window.noted.currentList,name + '.txt')

				# Renames the Note
				fs.rename(
					path.join(
						window.noted.storagedir,
						"Notebooks",
						window.noted.currentList,
						window.noted.currentNote + '.txt'
					),
					path.join(
						window.noted.storagedir,
						"Notebooks",
						window.noted.currentList,
						name + '.txt'
					)
				)

				window.noted.currentNote = name

		clickNote: (element) ->
			$("#notes .selected").removeClass("selected")
			element.addClass("selected")

			# Loads Actual Note
			window.noted.load.note(element)

		deleteNotebook: (element) ->
			$('.modal.deleteNotebook').modal()

		renameNotebook: ->
			name = $(".popover-mask").attr("data-parent")
			$('.modal.renameNotebook').modal()
			$('.modal.renameNotebook input').val(name).focus()

		modalclickDelNotebook: ->
			$('.modal.deleteNotebook').modal "hide"
			name = $(".popover-mask").attr("data-parent")
			console.log name
			fs.readdir path.join(window.noted.storagedir, "Notebooks", name), (err, files) ->
				files.forEach (file) ->
					console.log file
					fs.unlink(path.join(window.noted.storagedir, "Notebooks", name, file))
					fs.rmdir path.join(window.noted.storagedir, "Notebooks", name), (err) ->
						window.noted.deselect()
						window.noted.load.notebooks()

		modalclickRenameNotebook: ->
			$('.modal.renameNotebook').modal "hide"
			origname = $(".popover-mask").attr("data-parent")
			name = $('.modal.renameNotebook .delete-container h1').text()
			if name isnt ""
				while fs.existsSync(path.join(window.noted.storagedir, "Notebooks", name)) is true
					regexp = /\(\s*(\d+)\s*\)$/
					if regexp.exec(name) is null
						name = name+" (1)"
					else
						name = name.replace(" ("+regexp.exec(name)[1]+")", " ("+(parseInt(regexp.exec(name)[1])+1)+")")

				fs.rename(path.join(window.noted.storagedir,"Notebooks",origname),path.join(window.noted.storagedir,"Notebooks",name))
				window.noted.load.notebooks()

	util:
		pad: (n) ->
			# pad a single-digit number to a 2-digit number for things such as times or dates.
			(if (n < 10) then ("0" + n) else n)

window.noted.init()
