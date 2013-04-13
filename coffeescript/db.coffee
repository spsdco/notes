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
	# Creates a new notebook
	# @param {String} name The notebook name
	# @return {String} id The new notebook id
	###
	createNotebook: (name) ->
		id = generateUid()

		# there's a 16^16 chance of conflicting, but hey
		while fs.existsSync(path.join(@notebookdir, id))
			id = generateUid()

		fs.mkdirSync(path.join(@notebookdir, id))
		fs.writeFile path.join(@notebookdir, id, "meta.json"),
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

		while fs.existsSync(path.join(@notebookdir, notebook, id  + ".noted"))
			id = generateUid()

		fs.writeFile path.join(@notebookdir, notebook, id  + ".noted"),
			JSON.stringify {
				id: id
				name: name
				notebook: notebook
				content: content
			}
		return id


noteddb = new db(notebookdir())
notebook = noteddb.createNotebook("Getting Started")
noteddb.createNote("Awesome", notebook, "YOLO SWAGGGG")
