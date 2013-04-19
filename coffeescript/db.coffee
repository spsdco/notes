fs = require 'fs'
path = require 'path'

class noteddb
	constructor: (@notebookdir, @client) ->
		@client ?= no

	generateUid: ->
		s4 = ->
			(((1+Math.random())*0x10000)|0).toString(16).substring(1)
 
		(s4() + s4() + s4() + s4()).toLowerCase()

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
		id = @generateUid()

		# there's a 16^16 chance of conflicting, but hey
		while fs.existsSync(path.join(@notebookdir, id  + ".json"))
			id = @generateUid()

		fs.writeFileSync path.join(@notebookdir, id + ".json"),
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
		id = @generateUid()

		# Generates a new id if already exists
		while fs.existsSync(path.join(@notebookdir, notebook + "." + id  + ".noted"))
			id = @generateUid()

		filename = notebook + "." + id  + ".noted"
		data = JSON.stringify {
				id: id
				name: name
				notebook: notebook
				content: content
				date: Math.round(new Date() / 1000)
			}
		fs.writeFileSync path.join(@notebookdir, filename), data
		@syncWrite filename, data
		return id

	###
	# List notebooks
	# @param {Boolean} [names=false] Whether to return names of notebook
	# @return {Array} notebooks List of Notebooks
	###
	readNotebooks: (names) ->
		files = fs.readdirSync @notebookdir
		notebooks = []

		files.forEach (file) =>
			if file.substr(16,5) is ".json"
				if names
					notebooks.push {
						id: file.substr(0,16)
						name: JSON.parse(fs.readFileSync(path.join(@notebookdir, file))).name
					}
				else
					notebooks.push file.substr(0,16)

		return notebooks

	###
	# Read a notebook
	# @param {String} id The notebook id
	# @param {Boolean} [names=false] Whether to return names and excerpts of notes
	# @return {Object} notebook Notebook metadata with list of notes
	###
	readNotebook: (id, names) ->
		notebook = JSON.parse(fs.readFileSync(path.join(@notebookdir, id+".json")))
		notebook.contents = []

		files = fs.readdirSync @notebookdir
		files.forEach (file) =>
			if file.match(id) and file.substr(16,5) isnt ".json"
				filename = file.substr(17, 16)
				if names
					contents = JSON.parse(fs.readFileSync(path.join(@notebookdir, id+"."+filename+".noted")))
					notebook.contents.push {
						id: filename
						name: contents.name
						info: contents.content.substring(0,100)
						date: parseInt(contents.date)
					}
				else
					notebook.contents.push filename

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
	# Update Notebook Metadata
	# @param {String} id The notebook id
	# @param {Object} data The new notebook data
	# @return {Object} data The updated notebook data
	###
	updateNotebook: (id, data) ->
		# Ensure that the id does not change
		data.id = id

		fs.writeFileSync path.join(@notebookdir, id + ".json"),
			JSON.stringify data

		return data

	###
	# Update Note Data
	# @param {String} id The note id
	# @param {Object} data The new note data
	# @return {Object} data The updated note data
	###
	updateNote: (id, data) ->
		# This stuff cannot be set by the user
		data.id = id
		data.date = Math.round(new Date() / 1000)

		# If the notebook has changed, we need to rename the note
		if data.notebook != @readNote(id).notebook
			fs.renameSync(
				path.join(@notebookdir, @filenameNote(id)),
				path.join(@notebookdir, data.notebook+"."+id+".noted")
			)

		fs.writeFileSync path.join(@notebookdir, data.notebook+"."+id+".noted"),
			JSON.stringify data

		return data

	###
	# Deletes a notebook
	# @param {String} id The notebook id
	###
	deleteNotebook: (id) ->
		# Deletes each note
		@readNotebook(id).contents.forEach (file) =>
			fs.unlink path.join(@notebookdir, id+"."+file+".noted")

		# Deletes metadata
		fs.unlinkSync path.join(@notebookdir, id+".json")

	###
	# Deletes a note
	# @param {String} id The note id
	###
	deleteNote: (id) ->
		fs.unlink path.join(@notebookdir, @filenameNote(id))

	# Syncing
	syncWrite: (file, content) ->
		if @client
			@client.writeFile file, content, (err, stat) ->
				console.log err if err
				console.log stat

module.exports = noteddb
