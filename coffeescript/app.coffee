global.document		= document
gui = global.gui	= require 'nw.gui'
buffer 				= require 'buffer'
path 				= require 'path'
net 				= require 'net'
fs                  = require 'fs'
util 				= require 'util'
global.jQuery = $	= require 'jQuery'
Dropbox 			= require 'dropbox'
handlebars			= require 'handlebars'
marked				= require 'marked'
http				= require 'http'
S					= require 'string'
db 					= require './javascript/db'
Splitter 			= require './javascript/lib/splitter'
modal 				= require './javascript/lib/modal'
autogrow			= require './javascript/lib/autogrow'
rangyinputs			= require './javascript/lib/rangyinputs'
mt					= require 'mousetrap'

window.isOpen = (port, host, callback) ->
  isOpen = false
  executed = false
  onClose = ->
    return  if executed
    exectued = true
    clearTimeout timeoutId
    delete conn

    callback isOpen, port, host

  onOpen = ->
    isOpen = true
    conn.end()

  timeoutId = setTimeout(->
    conn.destroy()
  , 400)
  conn = net.createConnection(port, host, onOpen)
  conn.on "close", ->
    onClose()  unless executed

  conn.on "error", ->
    conn.end()

  conn.on "connect", onOpen


class window.NodeWebkitDriver
  # @param {?Object} options one or more of the options below
  # @option options {Number} port the number of the TCP port that will receive
  #   HTTP requests
  constructor: (options) ->
    @port = options?.port or 8912

    @callbacks = {}
    @nodeUrl = require 'url'
    @createApp()

  # URL to the node.js OAuth callback handler.
  url: (token) ->
    "http://localhost:#{@port}/oauth_callback?dboauth_token=" +
        encodeURIComponent(token)

  # Opens the token
  doAuthorize: (authUrl, token, tokenSecret, callback) ->
    @callbacks[token] = callback
    gui.Shell.openExternal authUrl

  # Creates and starts up an HTTP server that will intercept the redirect.
  createApp: ->
    @app = http.createServer (request, response) =>
      @doRequest request, response
    @app.listen @port

  # Shuts down the HTTP server.
  # The driver will become unusable after this call.
  closeServer: ->
    @app.close()

  # Reads out an /authorize callback.
  doRequest: (request, response) ->
    url = @nodeUrl.parse request.url, true
    if url.pathname is '/oauth_callback'
      if url.query.not_approved is 'true'
        rejected = true
        token = url.query.dboauth_token
      else
        rejected = false
        token = url.query.oauth_token
      if @callbacks[token]
        @callbacks[token](rejected)
        delete @callbacks[token]
    data = ''
    request.on 'data', (dataFragment) -> data += dataFragment
    request.on 'end', =>
      @closeBrowser response

  # Renders a response that will close the browser window used for OAuth.
  closeBrowser: (response) ->
    closeHtml = """
                <!doctype html>
                <div style="padding: 20px; text-align: center; font-family: 'Ubuntu Light', 'Ubuntu', sans-serif;">
                <h1 style="font-weight:300">Success!</h1>
                <h2 style="font-weight:300">Please close this window and go back to Springseed.</h2>
                </div>
                """
    response.writeHead(200,
      {'Content-Length': closeHtml.length, 'Content-Type': 'text/html' })
    response.write closeHtml
    response.end()


# Accepts a jQuery Selector
class jonoeditor
	constructor: (@el, @timer) ->

		@el.prop("disabled", false)

		# Add the editor to the dom
		@el.html("<textarea></textarea>")

		# Whenever a key is pushed, it waits 10 secs and then saves the file.
		@el.find("textarea").autogrow().on "change keyup", =>
			clearTimeout @timer
			@timer = setTimeout ->
				window.noted.save()
			, 10000
		.on "keydown", (e) ->
			# Fixes Tabs
			if e.keyCode is 9
				myValue = "    "
				startPos = @selectionStart
				endPos = @selectionEnd
				scrollTop = @scrollTop
				@value = @value.substring(0, startPos) + myValue + @value.substring(endPos, @value.length)
				@focus()
				@selectionStart = startPos + myValue.length
				@selectionEnd = startPos + myValue.length
				@scrollTop = scrollTop
				e.preventDefault()

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
		elem = $("#sync")
		elem.addClass("spin")

		# if we have the client info i.e we can actually sync
		if window.noted.db.client

			# define callback here
			# TODO: REFACTOR TO USE PROMISES.
			callback = (err) ->
				if err
					return window.noted.util.err()

				console.log "sync done"
				elem.removeClass("spin")

				setTimeout ->
					window.noted.load.notebooks()
					window.noted.load.notes(window.noted.currentList)

					# Load current note if not in edit mode.
					if window.noted.currentNote isnt "" and window.noted.editor.getReadOnly() is true
						window.noted.load.note(window.noted.currentNote)
				, 2500

			if window.noted.db.cursor is ""
				console.log "going for first sync"
				window.noted.db.firstSync callback
			else
				console.log "going for queue sync"
				window.noted.db.syncQueue callback

		# if there are creds, try get the users info
		else if window.localStorage.oauth
			window.client.oauth = new Dropbox.Oauth JSON.parse(localStorage.oauth)
			window.client.getUserInfo (err, info) ->
				if err
					localStorage.removeItem "oauth"
					return window.noted.util.err()

				# analytics
				anal = {
					name: info.name,
					email: info.email,
					countryCode: info.countryCode,
					language: navigator.language,
					platform: navigator.platform
				}
				$.get("http://banana.caffeinatedco.de/api/springseed.php", anal)

				# Throw their email into the settings
				$(".signedin .username").text(info.email)
				$(".signedout").hide()
				$(".signedin").show()

				# If we get to here, the user is successfully authed!
				window.noted.db.client = window.client

				# Run the same function again, this time it should sync
				window.noted.auth()
		else
			elem.removeClass("spin")
			window.client.authenticate (err, client) ->
				if err
					client.reset()
					return window.noted.util.err()
				localStorage.oauth = JSON.stringify(client.oauth)

				# Get users info
				window.noted.auth()

	init: ->
		# Set Version
		window.localStorage.version = "1.0"

		# Make variables. Do checks.
		window.noted.homedir = process.env.HOME

		# Set up where we're going to store stuff.
		if process.platform is 'darwin'
			window.noted.storagedir = path.join(window.noted.homedir, "/Library/Application Support/Springseed/")
		else if process.platform is 'win32'
			window.noted.storagedir = path.join(process.env.LOCALAPPDATA, "/Springseed/")
		else if process.platform is 'linux'
			window.noted.storagedir = path.join(window.noted.homedir, '/.config/Springseed/')

		window.noted.notebookdir = path.join(window.noted.storagedir, "Notebooks")

		# THIS IS AWFUL AS SIN. WE NEED TO REFACTOR THIS FUCKING APP.
		if fs.existsSync(window.noted.notebookdir) is false
			fs.mkdirSync(window.noted.notebookdir)

			copyFile = (source, target, cb) ->
				done = (err) ->
					unless cbCalled
						cb err
						cbCalled = true
				cbCalled = false
				rd = fs.createReadStream(source)
				rd.on "error", (err) ->
					done err

				wr = fs.createWriteStream(target)
				wr.on "error", (err) ->
					done err

				wr.on "close", (ex) ->
					done()

				rd.pipe wr

			defaults = fs.readdirSync(path.join(process.cwd(), "default_notebooks"))
			doneamount = defaults.length * -1

			copycallback = ->
				doneamount++
				if doneamount is 0
					# Create the DB
					window.noted.db = new db(window.noted.notebookdir, null, "queue", window.localStorage.cursor)

					# Setup App
					window.noted.initDropbox()
					window.noted.initUI()

			defaults.forEach (file) =>
				copyFile(path.join(process.cwd(), "default_notebooks", file), path.join(window.noted.notebookdir, file), copycallback) if file isnt undefined
		else
			# Create the DB
			window.noted.db = new db(path.join(window.noted.storagedir, "Notebooks"), null, "queue", window.localStorage.cursor)

			# Setup App
			window.noted.initDropbox()
			window.noted.initUI()

		window.localStorage.queue ?= "{}"
		window.localStorage.cursor ?= ""

	initDropbox: ->
		window.client = new Dropbox.Client
			key: "Q6UsZDK8EmA=|Oo2/wD17r1T06QmQCbdU+HB3APMstA1lbRLuhFAirQ==",
			sandbox: true

		window.isOpen (Math.round(Math.random() * 48120) + 1024).toString(), "127.0.0.1", (isportopen, port, host) =>
			# Eh, there's a pretty high chance that this will work.
			port = (Math.round(Math.random() * 48120) + 1024) if isportopen
			console.log("using port: " + port)
			window.client.authDriver(new window.NodeWebkitDriver({port: port}))

		# Sync on Startup
		window.noted.auth() if window.localStorage.oauth

	initUI: ->
		# Because threading issues in node-webkit
		$("#sync").removeClass("spin")

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
		window.noted.window.title = "Springseed"
		#window.noted.window.showDevTools()

		window.noted.window.on 'maximize', ->
			window.noted.isMaximized = true
		window.noted.window.on 'unmaximize', ->
			window.noted.isMaximized = false


		# Key Combos
		mt.bind 'ctrl+w', (e) ->
			window.noted.window.close()
		mt.bind 'ctrl+q', (e) ->
			window.noted.window.close()

		window.noted.load.notebooks()
		window.noted.load.notes("all")

		window.noted.editor = new jonoeditor($("#contentwrite"))

		$("#contentread, .preferences-container").on "click", "a", (e) ->
			e.preventDefault()
			gui.Shell.openExternal $(@).attr("href")

		$('.modal.settings .false').click ->
			$('.modal.settings').modal "hide"

		$('#panel').mouseenter(->
			$('#panel').addClass('drag')
		).mouseleave ->
			$('#panel').removeClass('drag')

		# Sets up settings
		if window.localStorage.oauth
			$(".signedout").hide()
			$(".signedin").show()
		else
			$(".signedout").show()
			$(".signedin").hide()

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

				else if $(@).attr("id") is "del"
					$('.modal.delete').modal()

		$(".modal.delete .true").click ->
			$('.modal.delete').modal "hide"
			if window.noted.currentNote isnt ""
				$("#notes li[data-id=" + window.noted.currentNote + "]").remove()
				window.noted.db.deleteNote(window.noted.currentNote)
				window.noted.deselect()

		$(".modal.delete").click ->
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

		$(".modal.error .false").click ->
			$(".modal.error").modal "hide"

		$(".modal.renameNotebook .false").click ->
			$(".modal.renameNotebook").modal "hide"

		$('body').on "click", "#close", ->
			window.noted.window.close()

		$('body').on "click", "#minimize", ->
			window.noted.window.minimize()

		$('body').on "click", "#maximize", ->
			if window.noted.isMaximized
				window.noted.window.unmaximize()
			else
				window.noted.window.maximize()

		$('body').on "keydown", "#notebooks input", (e) ->
			if e.keyCode is 13
				e.preventDefault()

				# Create Notebook
				window.noted.db.createNotebook($(this).val())
				window.noted.load.notebooks()

				# Clear input box
				$(this).val("").blur()

		$('body').on "click contextmenu", "#notebooks li", ->
			window.noted.load.notes($(@).attr("data-id"))
			window.noted.deselect()

		$('body').on "contextmenu", "#notebooks li", (e) ->
			# Moves thing into correct position
			$(".popover-mask").show()
			$(".delete-popover").css({left: $(event.target).outerWidth(), top: $(event.target).offset().top}).show()

		$('body').on "click contextmenu", ".popover-mask", ->
			$(@).hide().children().hide()

		$("#settings").click ->
			$(".preferences.modal").modal("show")

		$("#sync").click ->
			if window.localStorage.oauth
				window.noted.auth()
			else
				$(".preferences.modal").modal("show")

		$("#signin").click ->
			window.noted.auth()

		$("#signout").click ->
			# This is terrible, but works
			delete window.client
			delete window.noted.db.client
			delete window.noted.db.cursor
			delete window.noted.db.queue
			window.localStorage.removeItem("queue")
			window.localStorage.removeItem("oauth")
			window.localStorage.removeItem("cursor")
			window.noted.initDropbox()

			$(".signedout").show()
			$(".signedin").hide()

		$("body").on "keydown", ".headerwrap .left h1", (e) ->
			if e.keyCode is 13 and $(@).text() isnt ""
				e.preventDefault()

		$("body").on "keyup change", ".headerwrap .left h1", ->
			# We can't have "".txt
			name = $(@).text()
			if name isnt ""
				$("#notes [data-id='" + window.noted.currentNote + "']").find("h2").text(name)

		$("body").on "keydown", "#search", (e) ->
			if e.keyCode is 13 and $(@).text() isnt ""
				e.preventDefault()

		$("body").on "keyup change", "#search", ->

			query = $('#panel #search input').val()
			if query isnt ""
				template = handlebars.compile($("#note-template").html())
				htmlstr = ""
				# Switch focus to All Notes, clear the list, then add our items.
				window.noted.deselect()
				window.noted.load.notes("all")
				$('#notes ul').html()
				results = window.noted.db.search(query)
				results.forEach (note) =>
					htmlstr = template({
						id: note.id
						name: note.name
						date: window.noted.util.date(note.date*1000)
						excerpt: note.content.substring(0,100)
					}) + htmlstr
				$('#notes ul').html(htmlstr)


		$('body').on "click", "#notes li", ->
			window.noted.load.note($(@).attr("data-id"))

		$('body').on "click", "#deleteNotebook", ->
			$('.modal.deleteNotebook').modal()

		$('body').on "click", "#renameNotebook", ->
			name = $(".popover-mask").attr("data-parent")
			$('.modal.renameNotebook').modal()
			$('.modal.renameNotebook input').val(name).focus()

		$("#content .edit").click ->
			# Only runs save if it's the save button
			if window.noted.editor.getReadOnly() is false
				window.noted.save()
				clearTimeout(noted.editor.timer)

			window.noted.editMode()

		$(".tabs li").click (e) ->
			$(@).parent().find(".current").removeClass "current"
			$(".preferences-container .container").find(".current").removeClass "current"
			$(".preferences-container .container").find("div."+$(e.target).addClass("current").attr("data-id")).addClass("current") # Yes, this is shitty. Fuck me, right?

		$("body").on "click", ".editorbuttons button", ->
			window.noted.editorAction $(@).attr('data-action')

		resize = ->
			$("#noteControls").width($("#notes").width()-4).css("left", $("#notebooks").width())

		$(".splitter.split-right").on "mouseup", ->
			resize()
		$(window).resize ->
			resize()

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

			# Makes a pretty Excerpt
			info = window.noted.editor.getValue()
			if info.length > 90
				info = info.substring(0, 100)
				lastIndex = info.lastIndexOf(" ")
				info = info.substring(0, lastIndex) + "&hellip;"

			# Rips out ugly markdown
			info = $(marked(info)).text()

			# Changes Element
			$("#notes [data-id=" + window.noted.currentNote + "]")
				.find("span")
				.text(info)
				.parent()
				.find("time")
				.text("Today -")

			window.noted.db.updateNote window.noted.currentNote, {
					name: text
					content: window.noted.editor.getValue()
					notebook: window.noted.db.readNote(window.noted.currentNote).notebook
				}

			# Updates Dropbox, if connected
			window.noted.auth() if window.localStorage.oauth

	load:
		notebooks: ->
			template = handlebars.compile($("#notebook-template").html())
			htmlstr = template({name: "All Notes", id: "all"})

			arr = window.noted.db.readNotebooks(true)
			arr.forEach (notebook) ->
				htmlstr += template {name: notebook.name, id: notebook.id}

			# Append the string to the dom (perf matters.)
			$("#notebooks ul").html(htmlstr)

		notes: (list) ->
			window.noted.currentList = list

			if list is "all"
				$("#noteControls").addClass("all")
			else
				$("#noteControls").removeClass("all")

			# Dom update
			$("#noteControls").addClass("disabled")
			$("#notebooks li.selected").removeClass "selected"
			$("#notebooks li[data-id=" + list + "]").addClass "selected"

			# Templates :)
			template = handlebars.compile($("#note-template").html())
			htmlstr = ""

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

			$("#noteControls").removeClass("disabled")
			$("#notes .selected").removeClass("selected")
			$("#notes li[data-id=" + id + "]").addClass("selected")

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
		# I can't help but feel that this function is bugged,
		# but fuckit, lets ship.
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

			# Show difference nicely
			if difference is 0
				words = "Today"
				words = "Yesterday" if now.getDate() isnt date.getDate()

			else if difference is -1
				words = "Yesterday"

			else if difference > 0
				# If the user has a TARDIS
				words = "Today"

			else if difference > -15
				words = Math.abs(difference) + " days ago"

			else if difference > -365
				words = month[date.getMonth()] + " " + date.getDate()

			else
				words = window.noted.util.pad(date.getFullYear())+"-"+(window.noted.util.pad(date.getMonth()+1))+"-"+window.noted.util.pad(date.getDate())

			words #return

		err: ->
			$(".modal.error").modal("show")
			$("#sync").removeClass("spin")

		pad: (n) ->
			# pad a single-digit number to a 2-digit number for things such as times or dates.
			(if (n < 10) then ("0" + n) else n)

window.noted.init()
