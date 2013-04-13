fs = require 'fs'
path = require 'path'

# Anonymous Functions
notebookdir = ->
	# Set up where we're going to store stuff.
	if process.platform is 'darwin'
		path.join(process.env.HOME, "/Library/Application Support/Noted/Notebooks")
	else if process.platform is 'win32'
		path.join(process.env.LOCALAPPDATA, "/Noted/Notebooks")
	else if process.platform is 'linux'
		path.join(process.env.HOME, '/.config/Noted/Notebooks')

generateUid = ->
	s4 = ->
		(((1+Math.random())*0x10000)|0).toString(16).substring(1)
 
	(s4() + s4() + s4() + s4()).toLowerCase()


class db
	constructor: (@notebookdir) ->

	###
	# Finds the filename of a particular note id
	# @param {String} id The note you're searching for
	# @return {String} filename The found filename
	###
	filenameNote: (id) ->
		files = fs.readdirSync @notebookdir

		# Low level loop because perf?
		i = 0
		while i >= 0
			# Finds the filename
			if files[i] is undefined or files[i].match("."+id+".noted")
				return files[i]
			i++

	###
	# Creates a new notebook
	# @param {String} name The notebook name
	# @return {String} id The new notebook id
	###
	createNotebook: (name) ->
		id = generateUid()

		# there's a 16^16 chance of conflicting, but hey
		while fs.existsSync(path.join(@notebookdir, id  + ".json"))
			id = generateUid()

		fs.writeFile path.join(@notebookdir, id + ".json"),
			JSON.stringify {
				id: id
				name: name
			}
		return id

	###
	# Creates a new note
	# @param {String} name The new note name
	# @param {String} notebook The id of the notebook
	# @param {String} content The note content
	# @return {String} id The new note id
	###
	createNote: (name, notebook, content) ->
		id = generateUid()

		while fs.existsSync(path.join(@notebookdir, notebook + "." + id  + ".noted"))
			id = generateUid()

		fs.writeFile path.join(@notebookdir, notebook + "." + id  + ".noted"),
			JSON.stringify {
				id: id
				name: name
				notebook: notebook
				content: content
				date: Math.round(new Date() / 1000)
			}
		return id

	###
	# List notebooks
	# @return {Array} notebooks List of Notebooks
	###
	readNotebooks: ->
		files = fs.readdirSync @notebookdir
		notebooks = []

		files.forEach (file) ->
			notebooks.push file.substr(0,16) if file.substr(16,5) is ".json"

		return notebooks

	###
	# Read a notebook
	# @param {String} id The notebook id
	# @return {Object} notebook Notebook metadata with list of notes
	###
	readNotebook: (id) ->
		notebook = JSON.parse(fs.readFileSync(path.join(@notebookdir, id+".json")))
		notebook.contents = []

		files = fs.readdirSync @notebookdir
		files.forEach (file) ->
			notebook.contents.push file.substr(17, 16) if file.match(id) and file.substr(16,5) isnt ".json"

		return notebook

	###
	# Read a note
	# @param {String} id The note id
	# @return {Object} note Note metadata with content
	###
	readNote: (id) ->
		note = fs.readFileSync(path.join(@notebookdir, @filenameNote(id)))
		JSON.parse note.toString()

	###
	# Deletes a notebook
	# @param {String} id The notebook id
	###
	deleteNotebook: (id) ->
		# Deletes each note
		@readNotebook(id).contents.forEach (file) =>
			fs.unlink path.join(@notebookdir, id+"."+file+".noted")

		# Deletes metadata
		fs.unlink path.join(@notebookdir, id+".json")

	###
	# Deletes a note
	# @param {String} id The note id
	###
	deleteNote: (id) ->
		fs.unlink path.join(@notebookdir, @filenameNote(id))


noteddb = new db(notebookdir())
# notebook = noteddb.createNotebook("Getting Started")
# noteddb.createNote("Awesome", "b67fe9194949bd46", "YOLO SWAGGGG")
# noteddb.deleteNotebook(noteddb.readNotebooks()[0])
