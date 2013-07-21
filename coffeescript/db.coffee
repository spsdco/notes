fs = require 'fs'
path = require 'path'

class noteddb
	constructor: (@notebookdir, @client, @queue, @cursor) ->
		@queue ?= no
		@client ?= no
		@cursor ?= no

		@queueArr = JSON.parse(window.localStorage.getItem(@queue))

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
			if files[i] is undefined or files[i].match("."+id+".note")
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
		while fs.existsSync(path.join(@notebookdir, id  + ".list"))
			id = @generateUid()

		filename = id + ".list"
		data = {
			id: id
			name: name
		}

		# Write to FS & Dropbox
		fs.writeFileSync path.join(@notebookdir, filename), JSON.stringify(data)
		@addToQueue {
			"operation": "create"
			"file": filename
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
		while fs.existsSync(path.join(@notebookdir, notebook + "." + id  + ".note"))
			id = @generateUid()

		filename = notebook + "." + id  + ".note"
		data = {
			id: id
			name: name
			notebook: notebook
			content: content
			date: Math.round(new Date() / 1000)
		}
		fs.writeFileSync path.join(@notebookdir, filename), JSON.stringify(data)
		@addToQueue {
			"operation": "create"
			"file": filename
		}
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
			if file.substr(16,5) is ".list"
				if names
					notebooks.push {
						id: file.substr(0,16)
						name: JSON.parse(fs.readFileSync(path.join(@notebookdir, file))).name
					}
				else
					notebooks.push file.substr(0,16)

		if names
			notebooks.sort (a,b) ->
				return -1 if a.name < b.name
				return 1 if a.name > b.name
				return 0

		return notebooks

	###
	# Read a notebook
	# @param {String} id The notebook id
	# @param {Boolean} [names=false] Whether to return names and excerpts of notes
	# @return {Object} notebook Notebook metadata with list of notes
	###
	readNotebook: (id, names) ->
		if id is "all"
			notebook = {name: "All Notes", id: "all"}
		else
			notebook = JSON.parse(fs.readFileSync(path.join(@notebookdir, id+".list")))
		notebook.contents = []

		files = fs.readdirSync @notebookdir
		files.forEach (file) =>
			if file.match(id) and file.substr(33,5) is ".note" or id is "all" and file.substr(33,5) is ".note"
				filename = file.substr(17, 16)
				if names
					try
						contents = JSON.parse(fs.readFileSync(path.join(@notebookdir, file)))
						notebook.contents.push {
							id: filename
							name: contents.name
							info: contents.content.substring(0,100)
							date: parseInt(contents.date)
						}
					catch e
						# node-webkit/noted fucks itself if there's a parse error.
				else
					notebook.contents.push filename

		if names
			notebook.contents.sort (a,b) ->
				return -1 if a.date < b.date
				return 1 if a.date > b.date
				return 0

		return notebook

	###
	# Read a note
	# @param {String} id The note id
	# @return {Object} note Note metadata with content
	###
	readNote: (id) ->
		note = fs.readFileSync(path.join(@notebookdir, @filenameNote(id)))
		try
			JSON.parse note.toString()
		catch e
			# return nothing
			"error in file."


	###
	# Update Notebook Metadata
	# @param {String} id The notebook id
	# @param {Object} data The new notebook data
	# @return {Object} data The updated notebook data
	###
	updateNotebook: (id, data) ->
		# Ensure that the id does not change
		data.id = id
		filename = id + ".list"

		fs.writeFileSync path.join(@notebookdir, filename),
			JSON.stringify data

		@addToQueue {
			"operation": "update"
			"file": filename
		}

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
		filename = data.notebook+"."+id+".note"

		# If the notebook has changed, we need to rename the note
		if data.notebook != @readNote(id).notebook
			@addToQueue {
				"operation": "remove"
				"file": @filenameNote(id)
			}
			fs.renameSync(
				path.join(@notebookdir, @filenameNote(id)),
				path.join(@notebookdir, data.notebook+"."+id+".note")
			)
			@addToQueue {
				"operation": "create"
				"file": filename
			}
		else
			@addToQueue {
				"operation": "update"
				"file": filename
			}

		fs.writeFileSync path.join(@notebookdir, filename),
			JSON.stringify data


		return data

	###
	# Search Notes
	# @param {String} query The search query
	# @return {Object} results The results of the query
	###
	search: (query) ->
		results = []
		files = fs.readdirSync @notebookdir
		files.forEach (file) =>
			id = file.substr(17, 16)
			if id isnt "list"
				notedata = @readNote(file.substr(17, 16))
				if notedata.name.match(new RegExp(query, 'i')) or notedata.content.match(new RegExp(query, 'i'))
					results.push notedata

		return results

	###
	# Deletes a notebook
	# @param {String} id The notebook id
	###
	deleteNotebook: (id) ->
		# Deletes each note
		@readNotebook(id).contents.forEach (file) =>
			filename = id+"."+file+".note"
			fs.unlink path.join(@notebookdir, filename)
			@addToQueue {
				"operation": "remove"
				"file": filename
			}

		# Deletes metadata
		filename = id+".list"
		fs.unlinkSync path.join(@notebookdir, filename)
		@addToQueue {
			"operation": "remove"
			"file": filename
		}

	###
	# Deletes a note
	# @param {String} id The note id
	###
	deleteNote: (id) ->
		filename = @filenameNote(id)
		fs.unlink path.join(@notebookdir, filename)
		@addToQueue {
			"operation": "remove"
			"file": filename
		}

	# Syncing / Queues
	addToQueue: (obj) ->
		# This is clever. If it's updated or removed etc, the old operation is deleted.
		@queueArr[obj.file] = obj

		# Saves to LocalStorage
		window.localStorage.setItem(@queue, JSON.stringify(@queueArr))

	###
	# Run when user first connects to Dropbox
	###
	firstSync: (callback) ->
		@syncDelta (err) ->
			callback(err) if err && callback

			files = fs.readdirSync @notebookdir
			opcount = 0 - files.length

			# Run callback if nothing is there
			if files.length is 0
				callback() if callback

			files.forEach (file) =>
				data = fs.readFileSync(path.join(@notebookdir, file))
				@client.writeFile file, data.toString(), (err, stat) ->
					console.log stat
					opcount++
					if opcount is 0
						callback() if callback

			# Resets queue to a blank state
			window.localStorage.setItem("queue", "{}")

	###
	# Sync the current queue with Dropbox
	###
	syncQueue: (callback) ->
		@syncDelta (err) ->
			callback(err) if err && callback

			opcount = 0 - Object.keys(@queueArr).length

			# Just define the callback here cause #yolo
			filecallback = (err, stat) =>
				# When ops hit zero, we do a delta
				opcount++
				if opcount is 0
					# Do a delta to get the new cursor
					@client.delta @cursor, (err, data) =>
						@cursor = data.cursorTag
						window.localStorage.setItem("cursor", data.cursorTag)
						window.localStorage.setItem("queue", "{}")
						callback() if callback

				console.warn err if err
				delete @queueArr[file]

			# For each item in the queue
			for file of @queueArr
				# Sync Item
				op = @queueArr[file].operation
				if op is "create" or op is "update"
					# Create / Update the file
					@client.writeFile file, fs.readFileSync(path.join(@notebookdir, file)).toString(), filecallback

				else
					# Delete the File
					@client.delete file, filecallback

			# Runs callback if there is nothing to sync
			if Object.keys(@queueArr).length is 0
				console.log "nothing to sync"
				window.localStorage.setItem("queue", "{}")
				callback() if callback

	syncDelta: (callback) ->
		@callback = callback
		@client.delta @cursor, (err, data) =>
			if err
				return @callback(err)

			console.log(data)
			data.changes.forEach (file) =>
				console.log(file)
				if file.wasRemoved
					# Removes file to stay in sync
					fs.unlink path.join(@notebookdir, file.path)
				else
					# Downloads file from Dropbox
					@client.readFile file.path, null, (err, data) =>
						return console.warn err if err
						fs.writeFile(path.join(@notebookdir, file.path), data)

			# New cursor
			@cursor = data.cursorTag
			window.localStorage.setItem("cursor", data.cursorTag)

			# Run callback... not sure about conflicts, scoping and the async nature.
			@callback() if @callback

module.exports = noteddb
