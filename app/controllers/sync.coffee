Spine = @Spine or require('spine')
io = require 'socket.io-client'
Model = Spine.Model

# Connection states
OFFLINE = 0
IN_PROGRESS = 1
ONLINE = 2

window.Sync =

  oauth: JSON.parse localStorage.oauth or '{"service": "undefined"}'
  queue: JSON.parse localStorage.Queue or '{"Note": {}, "Notebook": {}}'
  syncMeta: {}

  # Hold pending actions
  pending: []

  # Run pending actions
  _clearPending: ->
    for [fn, that, args] in @pending by - 1
      fn.apply(that, args)
      @pending.length--

  # If connection is not ready, then we will wait until it is
  defer: (self, fn, args...) ->
    if @state is ONLINE
      fn.apply(self, args)
    else
      @pending.push [fn, self,  args]

  state: OFFLINE

  auth: (callback) ->

    # Saves data after getting it from the auth server
    onData = (data) ->
      # Calc expiration date
      data.expires = new Date().getTime() + parseInt(data.expires_in)*1000 if data.hasOwnProperty("expires_in")
      Sync.oauth = data
      localStorage.oauth = JSON.stringify(data)

    if Sync.oauth.service is "undefined"
      socket = io.connect("https://springseed-oauth.herokuapp.com:443")
      socket.on "meta", (data) ->
        console.log(data)

      socket.on "authorized", (data) ->
        onData(data)
        socket.disconnect() # Free up server resources

    # If it expires in the next ten minutes, we'll refresh the token
    else if Sync.oauth.service is "skydrive" and new Date().getTime() > (Sync.oauth.expires - 6000000)
      $.ajax(
        Sync.generateRequest
          request: "refresh"
      ).done((data) ->
        onData(data)
        callback() if callback
      )

  preSync: ->
    deferred = new $.Deferred()

    if Sync.oauth.service is "skydrive"
      $.ajax(
        Sync.generateRequest
          request: "findappdir"
      ).done((data) ->
        for item in data.data
          # Break when we find the springseed folder
          if item.name.toLowerCase() is "springseed"
            Sync.syncMeta.folderid = item.id
            break
        $.ajax(
          Sync.generateRequest
            request: "listappdir"
        ).done((data) ->
          Sync.syncMeta.map = {}
          for item in data.data
            Sync.syncMeta.map[item.name] = item.id
          deferred.resolve()
        )
      )
    else
      deferred.resolve()

    return deferred.promise()

  # The main syncing function.
  # It downloads the meta, then updates it to latest version as well as doing various other io.
  # It's magic. Trust me.
  doSync: ->

    console.log("bosh")

    # Downloads a meta file.
    $.ajax(
      Sync.generateRequest
        request: "download"
        filename: "meta"
    ).done((data) ->
      console.log(JSON.parse(Sync.exportData()), data, Sync.queue)
      result = Sync.merger(JSON.parse(Sync.exportData()), data, Sync.queue)

      console.log(result)

      # First, we rename the keys in our current DB
      promises = []
      for item in result[1].Note

        promises.push((->
          deferred = $.Deferred()

          Note.find(item[0]).loadNote (oldcontent) ->
            trans = Sync.db.transaction(["notes"], "readwrite")
            store = trans.objectStore "notes"
            request = store.put(oldcontent, item[1])

            request.onsuccess = (e) =>
              Note.find(item[0]).deleteNote ->
                deferred.resolve()

          return deferred.promise()
        )())

      # All files renamed, doing da internet IO.
      $.when.apply($, promises).then ->

        promises = []
        dbrequests = []
        trans = Sync.db.transaction(["notes"], "readwrite")
        store = trans.objectStore "notes"

        for item in result[2].Note

          promises.push((->
            deferred = $.Deferred()

            switch item[0]
              when "upload"
                itemid = item[1]
                dbrequests[itemid] = store.get(itemid)
                dbrequests[itemid].onsuccess = (e) =>
                  # Upload file to my butt.
                  $.ajax(
                    Sync.generateRequest
                      request: "upload"
                      filename: itemid
                      dataType: "text"
                      data: e.target.result
                  ).done (data) ->
                    deferred.resolve()

              when "download"
                # Download from my butt
                $.ajax(
                  Sync.generateRequest
                    request: "download"
                    filename: item[1]
                    dataType: "text"
                ).done (data) ->
                  # We now have to store the new data in the database.
                  trans = Sync.db.transaction(["notes"], "readwrite")
                  store = trans.objectStore "notes"
                  request = store.put(data, item[1])

                  request.onsuccess = (e) =>
                    deferred.resolve()

              when "destroy"
                dbrequests[item[1]] = store.delete(item[1])
                file = item[1]

                # Delete in the butt
                $.ajax(
                  Sync.generateRequest
                    request: "destroy"
                    filename: file
                    dataType: "text"
                ).done (data) ->
                  deferred.resolve()

            return deferred.promise()
          )())

        # Almost all io done, replace metas now.
        $.when.apply($, promises).then ->

          # Copy into the app
          Sync.importData JSON.stringify(result[0])

          # Send it to my butt yo
          $.ajax(
            Sync.generateRequest
              request: "upload"
              filename: "meta"
              data: JSON.stringify(result[0])
          ).done (data) ->
            console.log("all done! Delete the queue")
            Sync.queue = {"Note": {}, "Notebook": {}}
            Sync.saveQueue()

    ).error (data) ->
      if data.status is 401
        console.log "the bearer token is wrong. deleting token & please reauth"
        localStorage.removeItem "oauth"

      else if data.status is 404
        console.log "meta does not exist. uploading a new meta w/ every single file"

        promises = []
        $(Note.all()).each (i, e) ->
          e.loadNote (data) ->

            # make ajax request based on inputs from current loop element
            promises.push($.ajax(
                Sync.generateRequest
                  request: "upload"
                  filename: e.id
                  dataType: "text"
                  data: data
              )
            )

        # stuff
        $.when(promises).done ->
          console.log 'All files uploaded, uploading the meta file'

          $.ajax(
            Sync.generateRequest
              request: "upload"
              filename: "meta"
              data: Sync.exportData()
          ).done (data) ->
            console.log("all done! Delete the queue")
            Sync.queue = {"Note": {}, "Notebook": {}}
            Sync.saveQueue()

  # It's *slightly* nicer having a function generating requests
  generateRequest: (opts) ->
    if Sync.oauth.service is "dropbox"
      params =
        crossDomain: true
        dataType: opts.dataType || "json"
        beforeSend: (xhr) ->
          xhr.setRequestHeader "Authorization", "Bearer " + Sync.oauth.access_token

      if opts.request is "me"
        params.type = "get"
        params.url = "https://api.dropbox.com/1/account/info"

      else if opts.request is "download"
        params.type = "get"
        params.url = "https://api-content.dropbox.com/1/files/sandbox/" + opts.filename + ".seed"

      else if opts.request is "upload"
        params.type = "put"
        params.contentType = opts.contentType || "application/octet-stream"
        params.url = "https://api-content.dropbox.com/1/files_put/sandbox/" + opts.filename + ".seed"
        params.data = opts.data

      else if opts.request is "destroy"
        params.type = "post"
        params.url = "https://api.dropbox.com/1/fileops/delete"
        params.data = {
          root: "sandbox"
          path: opts.filename + ".seed"
        }

    else if Sync.oauth.service is "skydrive"
      params =
        crossDomain: true
        dataType: opts.dataType || "json"

      if opts.request is "refresh"
        params.type = "get"
        params.url = "https://springseed-oauth.herokuapp.com:443/refresh/skydrive?code=" + Sync.oauth.refresh_token

      else if opts.request is "me"
        params.type = "get"
        params.url = "https://apis.live.net/v5.0/me?access_token=" + Sync.oauth.access_token

      else if opts.request is "root"
        params.type = "get"
        params.url = "https://apis.live.net/v5.0/me/skydrive?access_token=" + Sync.oauth.access_token

      else if opts.request is "makeappdir"
        params.type = "post"
        params.contentType = "application/json"
        params.url = "https://apis.live.net/v5.0/me/skydrive/my_documents?access_token=" + Sync.oauth.access_token
        params.data = '{"name": "Springseed", "description": "Springseed App Data"}'

      else if opts.request is "findappdir"
        params.type = "get"
        params.url = "https://apis.live.net/v5.0/me/skydrive/my_documents/files?access_token=" + Sync.oauth.access_token

      else if opts.request is "listappdir"
        params.type = "get"
        params.url = "https://apis.live.net/v5.0/" + Sync.syncMeta.folderid + "/files?access_token=" + Sync.oauth.access_token

      else if opts.request is "download"
        params.type = "get"
        params.url = "https://apis.live.net/v5.0/" + Sync.syncMeta.map[opts.filename + ".seed"] + "/content?access_token=" + Sync.oauth.access_token

    params # return

  connect: (fn) ->

    # Only run connect once
    if @state isnt OFFLINE and typeof fn is 'function 'then return fn()
    @state = IN_PROGRESS

    request = indexedDB.open("springseed", 1)

    request.onupgradeneeded = (e) =>
      @db = e.target.result

      # We're going to just be storing all the spine stuff in one store,
      # just because I cbf seperating the Keys.
      @db.createObjectStore("meta")

      # We'll make another store to seperate the note s
      @db.createObjectStore("notes")

    request.onsuccess = (e) =>
      Sync.db = e.target.result
      @state = ONLINE
      fn() if typeof fn is 'function'
      @_clearPending()

  # Check an event, and if it is a model update add it to the queue
  addToQueue: (event, args) ->
    if @queue[args.constructor.name][args.id] and @queue[args.constructor.name][args.id][0] is "create"
      # create + destroy = nothing
      if event is "destroy"
        delete @queue[args.constructor.name][args.id]
    else
      # Otherwiswe, add it to the queue
      @queue[args.constructor.name][args.id] = [event, Math.round(new Date()/1000)]
    @saveQueue()

  saveQueue: ->
    # Save queue to localstorage
    localStorage.Queue = JSON.stringify @queue

  exportData: (keys=["Note", "Notebook"]) ->
    # Export local data to JSON
    output = {
      "Note": Note.toJSON()
      "Notebook": Notebook.toJSON()
    }
    JSON.stringify(output)

  importData: (obj) ->
    input = JSON.parse(obj)
    Note.refresh(input.Note, clear: true)
    Notebook.refresh(input.Notebook, clear: true)

  # Merges the client & server, using a queue
  # Spits out the result, id changes & fs changes
  merger: (client, server, queue) ->

    # Creates an array index
    indexer = (db) ->
      result = {}
      for k,v of db
        # Sets Up Index
        result[k] = {}
        result[k].max = 0

        # Indexes Items
        for key, index in db[k]
          result[k][key.id] = index

          # Checks for the highest number
          num = parseInt(key.id.substring(2, key.id.length))
          result[k].max = num if num > result[k].max

      result #return

    clientindex = indexer(client)
    resultant = JSON.parse(JSON.stringify(server))
    resultantindex = indexer(resultant)
    namechanges = {"Notebook": [], "Note": []}
    fschanges = {"Notebook": [], "Note": []}

    # Add Changes from client
    for type of queue
      for key, value of queue[type]
        switch value[0]
          when "create"
            # we copy the change into the resultant
            oldId = key
            newId = "c-" + (resultantindex[type].max += 1)
            client[type][clientindex[type][key]].id = newId
            resultant[type].push(client[type][clientindex[type][key]])

            # update the index
            resultantindex[type][newId] = resultant[type].length

            # add to fschanges
            fschanges[type].push(["upload", newId])

            # add to name changes
            namechanges[type].push([oldId, newId]) if oldId isnt newId

          when "update"
            # If the item update was before the update on the server, create a conflicted copy
            if value[1] < resultant[type][resultantindex[type][key]].date
              # bad case of DRY here

              # we copy the change into the resultant
              oldId = key
              newId = "c-" + (resultantindex[type].max += 1)
              client[type][clientindex[type][key]].id = newId
              client[type][clientindex[type][key]].name += " (Conflicted Copy)"
              resultant[type].push(client[type][clientindex[type][key]])

              # update the index
              resultantindex[type][newId] = resultant[type].length

              # add to fschanges
              fschanges[type].push(["download", resultant[type][resultantindex[type][key]].id])
              fschanges[type].push(["upload", newId])

              # add to name changes
              namechanges[type].push([oldId, newId]) if oldId isnt newId
            else
              # copies the new change in
              resultant[type][resultantindex[type][key]] = client[type][clientindex[type][key]]

              fschanges[type].push(["upload", resultant[type][resultantindex[type][key]].id])
          when "destroy"
            # If the item was after before the delete event, don't do anything
            if value[1] > resultant[type][resultantindex[type][key]].date
              # tell the server to delete it
              fschanges[type].push(["destroy", resultant[type][resultantindex[type][key]].id])

              # destroy the change from the resultant
              resultant[type].splice([clientindex[type][key]], 1)

              # reindex
              resultantindex = indexer(resultant)

    # Er, well if notebook name id changes we have to change note ids
    # @consindo is an idiot. Please send him angry messages.
    # This code is also annoying because it's not a keyvalue pair. That's what happens if you loop try to dry.
    # So, we'll build an index
    notebooknamechangesindex = {}
    for item in namechanges.Notebook
      notebooknamechangesindex[item[0]] = item[1]

    # Simple, right? Now we loop throught the notes and change the ids
    for k, v of resultant.Note
      if notebooknamechangesindex[v.notebook] isnt undefined
        v.notebook = notebooknamechangesindex[v.notebook]
        resultant.Note[k] = v

    # All the changes from the client should be added at this point
    # Now we detect the differences between the server copy and our client.

    # Basically, find timestamps that are newer on the server and stuff
    # that exists on the server but not the client.

    # We start by cloning the resultant
    original = JSON.parse(JSON.stringify(resultant))
    originalindex = indexer(original)

    # Removing all the stuff that is changed
    for type of fschanges
      for item in fschanges[type]
        original[type].splice(originalindex[type][item[1]], 1)
        originalindex = indexer(original)

    for type of original
      for key, value of original[type]
        # We only need to do this for stuff with dates, not anything else
        if value.date
          if client[type][clientindex[type][value.id]]
            if client[type][clientindex[type][value.id]].date < value.date
              # Server is newer than client, download from server
              fschanges[type].push(["download", value.id])
          else
            # Doesn't exist on client, download from server
            fschanges[type].push(["download", value.id])

    return [resultant, namechanges, fschanges]

# Just in case you need any default values
class Base

Model.Sync =

  extended: ->

    console.log '%c> Setting up sync for %s', 'font-weight: bold', this.name

    @fetch ->
      console.log '%c> Calling fetch', 'background: #eee'
      Sync.defer(this, @loadLocal)

    @change (record, event) ->
      Sync.addToQueue(event, record)
      console.log '%c> Calling change: ' + event, 'background: #eee'
      Sync.defer(this, @saveLocal)

    Sync.connect()

  saveLocal: ->
    result = JSON.stringify(@)

    # Save to IndexedDB
    trans = Sync.db.transaction(["meta"], "readwrite")
    store = trans.objectStore "meta"
    request = store.put(result, @className)

  loadLocal: (options = {}) ->

    console.log '%c> Fetching notes', 'color: blue'

    options.clear = true unless options.hasOwnProperty('clear')

    # Load from IndexedDB
    trans = Sync.db.transaction(["meta"], "readwrite")
    store = trans.objectStore "meta"
    request = store.get(@className)

    request.onsuccess = (e) =>
      result = e.target.result
      @refresh(result or [], options)

  saveNote: (content, callback) ->
    trans = Sync.db.transaction(["notes"], "readwrite")
    store = trans.objectStore "notes"
    request = store.put(content, @id)

    request.onsuccess = (e) =>
      callback() if callback

  loadNote: (callback) ->
    trans = Sync.db.transaction(["notes"], "readwrite")
    store = trans.objectStore "notes"
    request = store.get(@id)

    request.onsuccess = (e) =>
      result = e.target.result
      callback(result) if callback

  deleteNote: (callback) ->
    trans = Sync.db.transaction(["notes"], "readwrite")
    store = trans.objectStore "notes"
    request = store.delete(@id)

    request.onsuccess = (e) =>
      callback() if callback

Model.Sync.Methods =
  extended: ->
    @extend Extend
    @include Include

module?.exports = Sync
