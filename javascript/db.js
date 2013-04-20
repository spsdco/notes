(function() {
  var fs, noteddb, path;

  fs = require('fs');

  path = require('path');

  noteddb = (function() {

    function noteddb(notebookdir, client, queue) {
      this.notebookdir = notebookdir;
      this.client = client;
      this.queue = queue;
      if (this.queue == null) this.queue = false;
      if (this.client == null) this.client = false;
      this.queueArr = JSON.parse(window.localStorage.getItem(this.queue));
    }

    noteddb.prototype.generateUid = function() {
      var s4;
      s4 = function() {
        return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
      };
      return (s4() + s4() + s4() + s4()).toLowerCase();
    };

    /*
    	# Finds the filename of a particular note id
    	# @param {String} id The note you're searching for
    	# @return {String} filename The found filename
    */

    noteddb.prototype.filenameNote = function(id) {
      var files, i;
      files = fs.readdirSync(this.notebookdir);
      i = 0;
      while (i >= 0) {
        if (files[i] === void 0 || files[i].match("." + id + ".noted")) {
          return files[i];
        }
        i++;
      }
    };

    /*
    	# Creates a new notebook
    	# @param {String} name The notebook name
    	# @return {String} id The new notebook id
    */

    noteddb.prototype.createNotebook = function(name) {
      var data, filename, id;
      id = this.generateUid();
      while (fs.existsSync(path.join(this.notebookdir, id + ".json"))) {
        id = this.generateUid();
      }
      filename = id + ".json";
      data = {
        id: id,
        name: name
      };
      fs.writeFileSync(path.join(this.notebookdir, filename), JSON.stringify(data));
      this.addToQueue({
        "operation": "create",
        "file": filename,
        "data": data
      });
      return id;
    };

    /*
    	# Creates a new note
    	# @param {String} name The new note name
    	# @param {String} notebook The id of the notebook
    	# @param {String} content The note content
    	# @return {String} id The new note id
    */

    noteddb.prototype.createNote = function(name, notebook, content) {
      var data, filename, id;
      id = this.generateUid();
      while (fs.existsSync(path.join(this.notebookdir, notebook + "." + id + ".noted"))) {
        id = this.generateUid();
      }
      filename = notebook + "." + id + ".noted";
      data = {
        id: id,
        name: name,
        notebook: notebook,
        content: content,
        date: Math.round(new Date() / 1000)
      };
      fs.writeFileSync(path.join(this.notebookdir, filename), JSON.stringify(data));
      this.addToQueue({
        "operation": "create",
        "file": filename,
        "data": data
      });
      return id;
    };

    /*
    	# List notebooks
    	# @param {Boolean} [names=false] Whether to return names of notebook
    	# @return {Array} notebooks List of Notebooks
    */

    noteddb.prototype.readNotebooks = function(names) {
      var files, notebooks,
        _this = this;
      files = fs.readdirSync(this.notebookdir);
      notebooks = [];
      files.forEach(function(file) {
        if (file.substr(16, 5) === ".json") {
          if (names) {
            return notebooks.push({
              id: file.substr(0, 16),
              name: JSON.parse(fs.readFileSync(path.join(_this.notebookdir, file))).name
            });
          } else {
            return notebooks.push(file.substr(0, 16));
          }
        }
      });
      return notebooks;
    };

    /*
    	# Read a notebook
    	# @param {String} id The notebook id
    	# @param {Boolean} [names=false] Whether to return names and excerpts of notes
    	# @return {Object} notebook Notebook metadata with list of notes
    */

    noteddb.prototype.readNotebook = function(id, names) {
      var files, notebook,
        _this = this;
      notebook = JSON.parse(fs.readFileSync(path.join(this.notebookdir, id + ".json")));
      notebook.contents = [];
      files = fs.readdirSync(this.notebookdir);
      files.forEach(function(file) {
        var contents, filename;
        if (file.match(id) && file.substr(16, 5) !== ".json") {
          filename = file.substr(17, 16);
          if (names) {
            contents = JSON.parse(fs.readFileSync(path.join(_this.notebookdir, id + "." + filename + ".noted")));
            return notebook.contents.push({
              id: filename,
              name: contents.name,
              info: contents.content.substring(0, 100),
              date: parseInt(contents.date)
            });
          } else {
            return notebook.contents.push(filename);
          }
        }
      });
      return notebook;
    };

    /*
    	# Read a note
    	# @param {String} id The note id
    	# @return {Object} note Note metadata with content
    */

    noteddb.prototype.readNote = function(id) {
      var note;
      note = fs.readFileSync(path.join(this.notebookdir, this.filenameNote(id)));
      return JSON.parse(note.toString());
    };

    /*
    	# Update Notebook Metadata
    	# @param {String} id The notebook id
    	# @param {Object} data The new notebook data
    	# @return {Object} data The updated notebook data
    */

    noteddb.prototype.updateNotebook = function(id, data) {
      var filename;
      data.id = id;
      filename = id + ".json";
      fs.writeFileSync(path.join(this.notebookdir, filename), JSON.stringify(data));
      this.addToQueue({
        "operation": "update",
        "file": filename,
        "data": data
      });
      return data;
    };

    /*
    	# Update Note Data
    	# @param {String} id The note id
    	# @param {Object} data The new note data
    	# @return {Object} data The updated note data
    */

    noteddb.prototype.updateNote = function(id, data) {
      var filename;
      data.id = id;
      data.date = Math.round(new Date() / 1000);
      filename = data.notebook + "." + id + ".noted";
      if (data.notebook !== this.readNote(id).notebook) {
        this.addToQueue({
          "operation": "remove",
          "file": this.filenameNote(id)
        });
        fs.renameSync(path.join(this.notebookdir, this.filenameNote(id)), path.join(this.notebookdir, data.notebook + "." + id + ".noted"));
        this.addToQueue({
          "operation": "create",
          "file": filename,
          "data": data
        });
      } else {
        this.addToQueue({
          "operation": "update",
          "file": filename,
          "data": data
        });
      }
      fs.writeFileSync(path.join(this.notebookdir, filename), JSON.stringify(data));
      return data;
    };

    /*
    	# Deletes a notebook
    	# @param {String} id The notebook id
    */

    noteddb.prototype.deleteNotebook = function(id) {
      var filename,
        _this = this;
      this.readNotebook(id).contents.forEach(function(file) {
        var filename;
        filename = id + "." + file + ".noted";
        fs.unlink(path.join(_this.notebookdir, filename));
        return _this.addToQueue({
          "operation": "remove",
          "file": filename
        });
      });
      filename = id + ".json";
      fs.unlinkSync(path.join(this.notebookdir, filename));
      return this.addToQueue({
        "operation": "remove",
        "file": filename
      });
    };

    /*
    	# Deletes a note
    	# @param {String} id The note id
    */

    noteddb.prototype.deleteNote = function(id) {
      var filename;
      filename = this.filenameNote(id);
      fs.unlink(path.join(this.notebookdir, filename));
      return this.addToQueue({
        "operation": "remove",
        "file": filename
      });
    };

    noteddb.prototype.addToQueue = function(obj) {
      console.log(obj.file);
      this.queueArr[obj.file] = obj;
      return window.localStorage.setItem(this.queue, JSON.stringify(this.queueArr));
    };

    noteddb.prototype.syncWrite = function(file, content) {
      if (this.client) {
        return this.client.writeFile(file, content, function(err, stat) {
          if (err) console.log(err);
          return console.log(stat);
        });
      }
    };

    return noteddb;

  })();

  module.exports = noteddb;

}).call(this);
