// Generated by CoffeeScript 1.3.3
(function() {
  var MongoStore, app, async, chbs, cleans, colors, connect, curses, cussFilter, ensureSession, express, fs, io, isValidEmailAddress, mailer, models, online, os, package_info, pwh, secrets, sessionStore, smtp, socketio, uuid, _,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  _ = require("underscore");

  fs = require("fs");

  os = require("os");

  pwh = require("password-hash");

  chbs = require("connect-handlebars");

  uuid = require("node-uuid");

  async = require("async");

  colors = require("colors");

  mailer = require("nodemailer");

  connect = require("connect");

  express = require("express");

  socketio = require("socket.io");

  MongoStore = require("connect-mongo")(express);

  models = require("./models");

  secrets = require("./secrets");

  package_info = JSON.parse(fs.readFileSync("" + __dirname + "/package.json", "utf-8"));

  isValidEmailAddress = function(emailAddress) {
    var pattern;
    pattern = new RegExp(/^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?$/i);
    return pattern.test(emailAddress);
  };

  app = express.createServer();

  io = socketio.listen(app);

  smtp = mailer.createTransport("SMTP", {
    service: "Gmail",
    auth: {
      user: secrets.EMAIL_ADDRESS,
      pass: secrets.EMAIL_PASSWORD
    }
  });

  sessionStore = new MongoStore({
    db: 'keeba',
    url: secrets.MONGO_URI,
    stringify: false,
    clear_interval: 432000
  }, function() {
    app.listen(process.env.PORT || 7331);
    console.log("   ---------".red);
    console.log("   | VE RI |".red);
    console.log("    \\ TAS /".red);
    return console.log("     \\___/".red);
  });

  online = {};

  app.configure(function() {
    app.use(express.cookieParser());
    app.use(express.bodyParser());
    app.use(express.session({
      store: sessionStore,
      secret: secrets.SESSION_SECRET,
      key: "express.sid"
    }));
    app.use(app.router);
    app.use(express["static"]("" + __dirname + "/static"));
    app.use(express.errorHandler({
      dumpExceptions: true,
      showStack: true
    }));
    app.use("/js/templates.js", chbs("" + __dirname + "/templates", {
      exts: ['hbs']
    }));
    app.set('jsonp callback');
    app.set('view engine', 'jade');
    app.set('views', "" + __dirname + "/views");
    return app.use(express.limit('1mb'));
  });

  app.dynamicHelpers({
    version: function(req, res) {
      return package_info.version;
    }
  });

  ensureSession = function(req, res, next) {
    if (!req.session.uid) {
      return res.redirect("/in?whence=" + req.url);
    } else {
      return next();
    }
  };

  app.get("/", function(req, res) {
    if (req.session.uid) {
      return res.redirect("/lounge");
    } else {
      return res.render("index", {
        failed: false,
        email: '',
        appmode: false
      });
    }
  });

  app.get("/what", function(req, res) {
    return res.render("what", {
      appmode: req.session.uid
    });
  });

  app.get("/who", function(req, res) {
    return res.render("who", {
      appmode: req.session.uid
    });
  });

  app.get("/up", function(req, res) {
    if (req.session.uid) {
      return res.redirect("/lounge");
    } else {
      return res.render("up", {
        appmode: false,
        failed: false,
        dorms: models.DORMS,
        dorm: '',
        notevil: '',
        ovaries: '',
        first: '',
        last: '',
        email: '',
        hid: ''
      });
    }
  });

  app.post("/up", function(req, res) {
    var dorm, email, fail, first, hid, last, notevil, ovaries, password1, password2, person;
    hid = req.body.hid || '';
    first = req.body.first;
    last = req.body.last;
    email = req.body.email;
    password1 = req.body.password1;
    password2 = req.body.password2;
    ovaries = req.body.ovaries;
    dorm = req.body.dorm;
    notevil = req.body.notevil;
    fail = function() {
      return res.render("up", {
        appmode: false,
        failed: true,
        dorms: models.DORMS,
        hid: hid,
        dorm: dorm,
        notevil: notevil,
        ovaries: ovaries,
        first: first,
        last: last,
        email: email
      });
    };
    if (password1 !== password2) {
      return fail();
    } else if (!first || !last) {
      return fail();
    } else if (password1.length < 5) {
      return fail();
    } else if (!isValidEmailAddress(email)) {
      return fail();
    } else if (_.isUndefined(notevil)) {
      return fail();
    } else if (__indexOf.call(models.DORMS, dorm) < 0) {
      return fail();
    } else if (hid.length !== 8) {
      return fail();
    } else {
      person = new models.Person();
      person.hid = Number(hid);
      person.first = first;
      person.last = last;
      person.email = email;
      if (ovaries) {
        person.ovaries = true;
      } else {
        person.ovaries = false;
      }
      person.password = password1;
      person.dorm = dorm;
      return person.save(function(err) {
        if (err) {
          console.log(err);
          return fail();
        } else {
          return async.waterfall([
            function(wf_callback) {
              return models.Group.findOne().where("name", person.dorm).run(function(err, group) {
                return wf_callback(err, group);
              });
            }, function(group, wf_callback) {
              person.groups.addToSet(group);
              return person.save(function(err) {
                return wf_callback(err, group);
              });
            }, function(group, wf_callback) {
              group.members.addToSet(person);
              return group.save(wf_callback);
            }
          ], function(err) {
            if (err) {
              console.log(err);
              return fail();
            } else {
              req.session.uid = person._id;
              return res.redirect("/lounge");
            }
          });
        }
      });
    }
  });

  app.get("/in", function(req, res) {
    return res.render("in", {
      appmode: false,
      failed: false,
      email: ''
    });
  });

  app.post("/in", function(req, res) {
    var email, fail, password;
    email = req.body.email || '';
    password = req.body.password;
    fail = function() {
      return res.render("in", {
        appmode: false,
        failed: true,
        email: email
      });
    };
    return models.Person.findOne().where("email", email).run(function(err, person) {
      if (err || !person) {
        return fail();
      } else {
        if (pwh.verify(password, person.password)) {
          req.session.uid = person._id;
          return res.redirect("/lounge");
        } else {
          return fail();
        }
      }
    });
  });

  app.get("/out", function(req, res) {
    req.session.destroy();
    return res.redirect("/");
  });

  app.get("/forgot", function(req, res) {
    return res.render("forgot", {
      appmode: false,
      failed: false,
      email: ''
    });
  });

  app.get("/forgot/sent", function(req, res) {
    return res.render("forgot-sent", {
      appmode: false
    });
  });

  app.get("/forgot/complete", function(req, res) {
    return res.render("forgot-complete", {
      appmode: false
    });
  });

  app.post("/forgot", function(req, res) {
    var email;
    email = req.body.email;
    return models.Person.findOne().where("email", email).run(function(err, person) {
      var options, reset_token, reset_url;
      if (err || !person) {
        return res.render("forgot", {
          appmode: false,
          failed: true,
          email: email
        });
      } else {
        reset_token = uuid.v4();
        reset_url = "" + req.headers.origin + "/forgot/" + reset_token;
        options = {
          from: "Veritas <" + secrets.EMAIL_ADDRESS + ">",
          to: person.email,
          subject: "Password reset",
          html: "<pre>\n  Hey " + person.first + ",\n\n  Word on the street is that you want to reset your password on Veritas.\n\n  To do so, just click here: <a href=\"" + reset_url + "\">" + reset_url + "</a>\n\n  If you didn't request this reset, you can safely ignore this message.\n\n  Peace out.\n</pre>"
        };
        return async.parallel([
          function(cb) {
            return models.Person.update({
              email: email
            }, {
              reset_token: reset_token
            }, cb);
          }, function(cb) {
            return smtp.sendMail(options, cb);
          }
        ], function(err) {
          if (err) {
            console.log(err);
            return res.render("error", {
              appmode: false
            });
          } else {
            return res.redirect("/forgot/sent");
          }
        });
      }
    });
  });

  app.get("/forgot/:token", function(req, res) {
    var reset_token;
    reset_token = req.params.token;
    return models.Person.findOne().where("reset_token", reset_token).run(function(err, person) {
      if (err || !person) {
        return res.render("error", {
          appmode: false,
          failed: false
        });
      } else {
        return res.render("forgot-reset", {
          appmode: false,
          failed: false
        });
      }
    });
  });

  app.post("/forgot/:token", function(req, res) {
    var pw1, pw2, reset_token;
    reset_token = req.params.token;
    pw1 = req.body.pw1;
    pw2 = req.body.pw2;
    if (pw1 !== pw2) {
      return res.render("forgot-reset", {
        appmode: false,
        failed: true
      });
    } else {
      return models.Person.update({
        reset_token: reset_token
      }, {
        password: pwh.generate(pw1),
        $unset: {
          reset_token: 1
        }
      }, function(err, person) {
        if (err || !person) {
          console.log(err);
          return res.render("error", {
            appmode: false
          });
        } else {
          return res.redirect("/forgot/complete");
        }
      });
    }
  });

  app.post("/validate", function(req, res) {
    var hid;
    hid = req.body.hid;
    if (hid.length === 8) {
      return res.send("OK");
    } else {
      return res.send("BUT SIRRR");
    }
  });

  app.get("/people/:id", ensureSession, function(req, res) {
    var id;
    if (req.params.id === "me") {
      return res.redirect("/people/" + req.session.uid);
    }
    id = req.params.id;
    return models.Person.findOne().where("_id", id).populate("groups").run(function(err, person) {
      if (err || !person) {
        return res.render("error", {
          appmode: false
        });
      } else {
        return res.render("person", {
          appmode: true,
          person: person
        });
      }
    });
  });

  app.get("/choose", ensureSession, function(req, res) {
    return models.Group.where("flag", "harvard-course").select("name").run(function(err, courses) {
      console.log(err);
      return res.render("choose", {
        appmode: true,
        courses: JSON.stringify(courses)
      });
    });
  });

  app.get("/lounge*", ensureSession, function(req, res) {
    var uid;
    uid = req.session.uid;
    return async.parallel([
      function(cb) {
        return models.Person.findOne().where("_id", uid).select("first", "last", "groups").populate("groups").run(cb);
      }, function(cb) {
        return models.Group.where("flag", "harvard-global").populate("members", ["first", "last"]).run(cb);
      }
    ], function(err, results) {
      var global_groups, person;
      if (err) {
        return res.render("error");
      } else {
        person = results[0];
        global_groups = results[1];
        if (!person || !global_groups) {
          return res.redirect("/out");
        }
        if (!(person.groups.length > 1)) {
          return res.redirect("/choose");
        }
        online[uid] = {
          name: "" + person.first + " " + person.last,
          id: uid
        };
        return res.render("lounge", {
          appmode: true,
          groups_bootstrap: JSON.stringify(_.union(person.groups, global_groups)),
          online: JSON.stringify(_.values(online))
        });
      }
    });
  });

  curses = ["fuck", "shit", "bitch", "douche", "cock", "fag", "faggot", "nigger", "cunt", "whore", "ass", "dick", "penis", "vagina", "pussy", "tits"];

  cleans = ["squidward", "jigglypuff", "trollface", "cowsaysmoo", "soap", "AGNRY FAIC", "Sarah Palin", "N00t G1ngr1ch", "l.o.l", "$#&!*#$*@&!&$", "pikachu", "creampuffs", "mushrooms", "Kleenex", "POLAR BEARS", "OVER 9000", "supersain", "deep", "BUT SIRRR", "DEEEEEEEEEEEEEEP", "GREAT SUCCESS", "chair", "ductape", "agua", "חביטאח", "watermellon", "Wal-Mart", "EXCEELLLENT", "thorax", "timmy", "James", "bob saget"];

  cussFilter = function(text) {
    var curse, pattern, _i, _len;
    for (_i = 0, _len = curses.length; _i < _len; _i++) {
      curse = curses[_i];
      pattern = new RegExp(curse, 'gi');
      text = text.replace(pattern, cleans[Math.floor(Math.random() * cleans.length)]);
    }
    return text;
  };

  io.set("authorization", function(data, accept) {
    if (data.headers.cookie) {
      data.cookie = connect.utils.parseCookie(data.headers.cookie);
      data.sessionID = data.cookie['express.sid'];
      data.sessionStore = sessionStore;
      return sessionStore.get(data.sessionID, function(err, session) {
        if (err) {
          return accept(err.message.toString(), false);
        } else {
          data.session = new connect.middleware.session.Session(data, session);
          return accept(null, true);
        }
      });
    } else {
      return accept("No cookie transmitted.", false);
    }
  });

  io.sockets.on("connection", function(socket) {
    var sync, uid;
    uid = socket.handshake.session.uid;
    socket.join(uid);
    models.Person.findOne().where("_id", uid).select("first", "last").run(function(err, person) {
      online[uid] = {
        name: "" + person.first + " " + person.last,
        id: uid
      };
      return socket.broadcast.emit("online", _.values(online));
    });
    sync = function(model, method, data) {
      var event_name;
      event_name = "" + model + "/" + data._id + ":" + method;
      return io.sockets.emit(event_name, data);
    };
    socket.on("group:message", function(group_id, body, cb) {
      if (body.length > 1000) {
        return cb(true, "length");
      }
      return async.waterfall([
        function(wf_callback) {
          return models.Person.findOne().where("_id", uid).run(function(err, account) {
            return wf_callback(err, account);
          });
        }, function(account, wf_callback) {
          return models.Group.findOne().where("_id", group_id).run(function(err, group) {
            return wf_callback(err, account, group);
          });
        }, function(account, group, wf_callback) {
          var message;
          message = {
            first: account.first,
            person_id: account._id,
            body: cussFilter(body)
          };
          group.messages.push(message);
          return group.save(function(err) {
            return wf_callback(err, group, message);
          });
        }
      ], function(err, group, message) {
        io.sockets.emit("message", {
          message: message,
          group: group._id
        });
        return cb(err);
      });
    });
    socket.on("join groups", function(groups, cb) {
      var done, itr;
      done = function(err) {
        return cb(err);
      };
      itr = function(group_id, async_cb) {
        return async.waterfall([
          function(wf_callback) {
            return models.Person.findOne().where("_id", uid).run(wf_callback);
          }, function(account, wf_callback) {
            return models.Group.findOne().where("_id", group_id).run(function(err, group) {
              return wf_callback(err, account, group);
            });
          }, function(account, group, wf_callback) {
            account.groups.addToSet(group);
            return account.save(function(err, account) {
              return wf_callback(err, account, group);
            });
          }, function(account, group, wf_callback) {
            group.members.addToSet(account);
            return group.save(wf_callback);
          }
        ], async_cb);
      };
      return async.forEach(groups, itr, done);
    });
    return socket.on("disconnect", function() {
      if (_.has(online, uid)) {
        delete online[uid];
      }
      return socket.broadcast.emit("online", _.values(online));
    });
  });

}).call(this);
