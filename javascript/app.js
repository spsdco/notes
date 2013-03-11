(function() {
  var fs, gui, home_dir, ncp, node, path, reserved_chars, storage_dir, util,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  try {
    gui = require('nw.gui');
    fs = require('fs');
    path = require('path');
    ncp = require('ncp').ncp;
    util = require('util');
    node = true;
    home_dir = process.env.HOME;
    reserved_chars = [186, 191, 220, 222, 106, 56];
    if (process.platform === "darwin") {
      storage_dir = path.join(home_dir, "/Library/Application Support/Noted/");
    } else if (process.platform === "win32") {
      storage_dir = path.join(process.env.LOCALAPPDATA, "/Noted");
    } else if (process.platform === "linux") {
      storage_dir = path.join(home_dir, "/.config/Noted/");
    }
  } catch (e) {
    console.log("ERROR:\nType: " + e.type + "\nArgs: " + e.arguments + "\nMessage: " + e.message);
    console.log("\nSTACKTRACE:\n", e.stack);
  }

  window.noted = {
    selectedList: "all",
    selectedNote: "",
    setupPanel: function() {
      var win;
      win = gui.Window.get();
      win.show();
      win.showDevTools();
      $('#close').click(function() {
        return win.close();
      });
      $('#minimize').click(function() {
        return win.minimize();
      });
      $('#maximize').click(function() {
        return win.maximize();
      });
      $('#panel').mouseenter(function() {
        return $('#panel').addClass('drag');
      }).mouseleave(function() {
        return $('#panel').removeClass('drag');
      });
      return $('#panel #decor img, #panel #noteControls img, #panel #search').mouseenter(function() {
        return $('#panel').removeClass('drag');
      }).mouseleave(function() {
        return $('#panel').addClass('drag');
      });
    },
    setupUI: function() {
      $("#content .edit").click(window.noted.editMode);
      $("body").on("click", "#notebooks li", function() {
        $(this).parent().find(".selected").removeClass("selected");
        $(this).addClass("selected");
        window.noted.loadNotes($(this).text());
        return window.noted.deselectNote();
      });
      $("body").on("contextmenu", "#notebooks li", function() {
        var name;
        name = $(this).text();
        console.log(name);
        window.noted.editor.remove('file');
        return fs.unlink(path.join(storage_dir, "Notebooks", name, '*'), function(err) {
          return fs.rmdir(path.join(storage_dir, "Notebooks", name), function(err) {
            if (err) throw err;
            window.noted.deselectNote();
            return window.noted.listNotebooks();
          });
        });
      });
      $('body').on("keydown", "#notebooks input", function(e) {
        var name;
        name = $('#notebooks input').val();
        if (e.keyCode === 13) {
          e.preventDefault();
          while (fs.existsSync(path.join(storage_dir, "Notebooks", name + '.txt')) === true) {
            name = name + "_";
          }
          fs.mkdir(path.join(storage_dir, "Notebooks", name + '.txt'));
          window.noted.listNotebooks();
          return $('#notebooks input').val("");
        }
      });
      $("body").on("click", "#notes li", function() {
        this.el = $(this);
        $("#notes .selected").removeClass("selected");
        this.el.addClass("selected");
        return window.noted.loadNote(this.el);
      });
      $("body").on("keydown", ".headerwrap .left h1", function(e) {
        var _ref;
        console.log(e.keyCode);
        if (e.keyCode === 13) {
          e.preventDefault();
          return $(this).blur();
        } else if (_ref = e.keyCode, __indexOf.call(reserved_chars, _ref) >= 0) {
          return e.preventDefault();
        }
      });
      $("body").on("keyup", ".headerwrap .left h1", function(e) {
        if ($(this).text() !== "") {
          $("#notes [data-id='" + window.noted.selectedNote + "']").attr("data-id", $(this).text()).find("h2").text($(this).text());
          fs.rename(path.join(storage_dir, "Notebooks", window.noted.selectedList, window.noted.selectedNote + '.txt'), path.join(storage_dir, "Notebooks", window.noted.selectedList, $(this).text() + '.txt'));
          return window.noted.selectedNote = $(this).text();
        }
      });
      window.noted.editor = new EpicEditor({
        container: 'contentbody',
        file: {
          name: 'epiceditor',
          defaultContent: '',
          autoSave: 2500
        },
        theme: {
          base: '/themes/base/epiceditor.css',
          preview: '/themes/preview/style.css',
          editor: '/themes/editor/style.css'
        }
      });
      window.noted.editor.load();
      window.noted.editor.on("save", function(e) {
        var list, notePath;
        list = $("#notes li[data-id='" + window.noted.selectedNote + "']").attr("data-list");
        if (window.noted.selectedNote !== "") {
          notePath = path.join(storage_dir, "Notebooks", list, window.noted.selectedNote + '.txt');
          if (e.content !== fs.readFileSync(notePath).toString()) {
            return fs.writeFile(notePath, e.content);
          }
        }
      });
      $('#new').click(function() {
        var name;
        name = "Untitled Note";
        if (window.noted.selectedList !== "All Notes" && window.noted.editor.eeState.edit === false) {
          while (fs.existsSync(path.join(storage_dir, "Notebooks", window.noted.selectedList, name + '.txt')) === true) {
            name = name + "_";
          }
          return fs.writeFile(path.join(storage_dir, "Notebooks", window.noted.selectedList, name + '.txt'), "Add some content!", function() {
            return window.noted.loadNotes(window.noted.selectedList, "", function() {
              console.log("hello");
              return $("#notes ul li:first").addClass("edit").trigger("click");
            });
          });
        }
      });
      return $('#del').click(function() {
        window.noted.editor.remove('file');
        if (window.noted.selectedNote !== "") {
          return fs.unlink(path.join(storage_dir, "Notebooks", $("#notes li[data-id='" + window.noted.selectedNote + "']").attr("data-list"), window.noted.selectedNote + '.txt'), function(err) {
            if (err) throw err;
            window.noted.deselectNote();
            return window.noted.loadNotes(window.noted.selectedList);
          });
        }
      });
    },
    editMode: function(mode) {
      var el;
      el = $("#content .edit");
      if (mode === "preview" || window.noted.editor.eeState.edit === true && mode !== "editor") {
        el.text("edit");
        $('#content .left h1').attr('contenteditable', 'false');
        $('#contentbody');
        window.noted.editor.save();
        return window.noted.editor.preview();
      } else {
        el.text("save");
        $('.headerwrap .left h1').attr('contenteditable', 'true');
        return window.noted.editor.edit();
      }
    },
    render: function() {
      return window.noted.listNotebooks();
    },
    listNotebooks: function() {
      console.log("NoteBooks Called");
      $("#notebooks ul").html("").append("<li class='all'>All Notes</li>");
      return fs.readdir(path.join(storage_dir, "Notebooks"), function(err, data) {
        var i;
        i = 0;
        while (i < data.length) {
          if (fs.statSync(path.join(storage_dir, "Notebooks", data[i])).isDirectory()) {
            $("#notebooks ul").append("<li data-id='" + data[i] + "'>" + data[i] + "</li>");
          }
          i++;
        }
        if (window.noted.selectedList === "all") {
          return $("#notebooks .all").trigger("click");
        } else {
          return $("#notebooks [data-id='" + window.noted.selectedList + "']").addClass("selected").trigger("click");
        }
      });
    },
    loadNotes: function(list, type, callback) {
      var data, htmlstr, i, name, note, order, time, _i, _len;
      window.noted.selectedList = list;
      $("#notes header h1").html(list);
      $("#notes ul").html("");
      htmlstr = "";
      if (list === "All Notes") {
        htmlstr = "I broke all notes because of the shitty implementation";
      } else {
        data = fs.readdirSync(path.join(storage_dir, "Notebooks", list));
        order = [];
        i = 0;
        while (i < data.length) {
          if (data[i].substr(data[i].length - 4, data[i].length) === ".txt") {
            name = data[i].substr(0, data[i].length - 4);
            time = new Date(fs.statSync(path.join(storage_dir, "Notebooks", list, name + '.txt'))['mtime']);
            order.push({
              id: i,
              time: time,
              name: name
            });
          }
          i++;
        }
        order.sort(function(a, b) {
          return new Date(a.time) - new Date(b.time);
        });
        for (_i = 0, _len = order.length; _i < _len; _i++) {
          note = order[_i];
          htmlstr = "<li data-id='" + note.name + "' data-list='" + list + "'><h2>" + note.name + "</h2></li>" + htmlstr;
        }
      }
      $("#notes ul").html(htmlstr);
      if (callback) return callback();
    },
    loadNote: function(selector) {
      window.noted.selectedNote = $(selector).find("h2").text();
      return fs.readFile(path.join(storage_dir, "Notebooks", $(selector).attr("data-list"), window.noted.selectedNote + '.txt'), 'utf-8', function(err, data) {
        var noteTime, time;
        if (err) throw err;
        $("#content").removeClass("deselected");
        $('.headerwrap .left h1').text(window.noted.selectedNote);
        noteTime = fs.statSync(path.join(storage_dir, "Notebooks", $(selector).attr("data-list"), window.noted.selectedNote + '.txt'))['mtime'];
        time = new Date(Date.parse(noteTime));
        $('.headerwrap .left time').text(window.noted.timeControls.pad(time.getDate()) + "/" + (window.noted.timeControls.pad(time.getMonth() + 1)) + "/" + time.getFullYear() + " " + window.noted.timeControls.pad(time.getHours()) + ":" + window.noted.timeControls.pad(time.getMinutes()));
        window.noted.editor.importFile('file', data);
        if (selector.hasClass("edit")) {
          window.noted.editMode("editor");
          $("#content .left h1").focus();
          return selector.removeClass("edit");
        } else {
          return window.noted.editMode("preview");
        }
      });
    },
    deselectNote: function() {
      $("#content").addClass("deselected");
      $("#content .left h1, #content .left time").text("");
      window.noted.selectedNote = "";
      window.noted.editor.importFile('file', "");
      return window.noted.editor.preview();
    }
  };

  window.noted.timeControls = {
    pad: function(n) {
      if (n < 10) {
        return "0" + n;
      } else {
        return n;
      }
    }
  };

  $(function() {
    window.noted.setupUI();
    $('#panel, #notebooks, #notes').mousedown(function() {
      $(this).css('cursor', 'default');
      return false;
    });
    if (node) {
      window.noted.setupPanel();
      return fs.readdir(path.join(storage_dir, "/Notebooks/"), function(err, data) {
        if (err) {
          if (err.code === "ENOENT") {
            return fs.mkdir(path.join(storage_dir, "/Notebooks/"), function() {
              return ncp(path.join(window.location.pathname, "../default_notebooks"), path.join(storage_dir, "/Notebooks/"), function(err) {
                return window.noted.render();
              });
            });
          }
        } else {
          return window.noted.render();
        }
      });
    }
  });

}).call(this);
