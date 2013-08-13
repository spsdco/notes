Spine = @Spine or require('spine')
Model = Spine.Model

Sync =
  models: {}

Model.Sync =
  extended: ->
    @change @saveLocal
    @fetch @loadLocal

    @connect()

  connect: ->
    request = indexedDB.open("springseed", 1)

    request.onupgradeneeded = (e) ->
      Sync.db = e.target.result

      # We're going to just be storing all the spine stuff in one store,
      # just because I cbf seperating the Keys.
      Sync.db.createObjectStore("meta")

      # We'll make another store to seperate the note s
      Sync.db.createObjectStore("notes")

    request.onsuccess = (e) ->
      Sync.db = e.target.result

  saveLocal: ->
    result = JSON.stringify(@)

    # Save to IndexedDB
    trans = Sync.db.transaction(["meta"], "readwrite")
    store = trans.objectStore("meta")
    request = store.put(result, @className)

  loadLocal: (options = {}) ->
    options.clear = true unless options.hasOwnProperty('clear')

    # Load from IndexedDB
    trans = Sync.db.transaction(["meta"], "readwrite");
    store = trans.objectStore("meta");
    request = store.get(@className)

    request.onsuccess = (e) =>
      result = e.target.result
      @refresh(result or [], options)


Model.Sync.Methods =
  extended: ->
    @extend Extend
    @include Include

Spine.Sync = Sync
module?.exports = Sync
