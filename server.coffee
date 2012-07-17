# Copyright (C) 2012 Avi Romanoff <aviromanoff at gmail.com>

_          = require "underscore"
fs         = require "fs"
os         = require "os"
pwh        = require "password-hash"
chbs       = require "connect-handlebars"
uuid       = require "node-uuid"
async      = require "async"
colors     = require "colors"
mailer     = require "nodemailer"
connect    = require "connect"
express    = require "express"
socketio   = require "socket.io"
MongoStore = require("connect-mongo")(express)

models     = require "./models"
secrets    = require "./secrets"

package_info = JSON.parse(fs.readFileSync "#{__dirname}/package.json", "utf-8")

# http://stackoverflow.com/questions/2855865/jquery-validate-e-mail-address-regex
isValidEmailAddress = (emailAddress) ->
  pattern = new RegExp(/^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?$/i)
  pattern.test emailAddress

app = express.createServer()
io = socketio.listen app

smtp = mailer.createTransport "SMTP",
  service: "Gmail"
  auth:
    user: secrets.EMAIL_ADDRESS
    pass: secrets.EMAIL_PASSWORD

io.set 'transports', ["xhr-polling"]
io.set 'polling duration', 10
io.set 'close timeout', 15

sessionStore = new MongoStore
  db: 'keeba'
  url: secrets.MONGO_URI
  stringify: false
  clear_interval: 432000, # 5 days
  () ->
    app.listen process.env.PORT or 7331
    console.log "   ---------".red
    console.log "   | VE RI |".red
    console.log "    \\ TAS /".red
    console.log "     \\___/".red

online = {}

app.configure ->
  app.use express.cookieParser()
  app.use express.bodyParser()
  app.use express.session
    store: sessionStore
    secret: secrets.SESSION_SECRET
    key: "express.sid"
  app.use app.router
  app.use express.static "#{__dirname}/static"
  app.use express.errorHandler(dumpExceptions: true, showStack: true)
  app.use "/js/templates.js", chbs("#{__dirname}/templates", exts: ['hbs'])
  app.set 'jsonp callback'
  app.set 'view engine', 'jade'
  app.set 'views', "#{__dirname}/views"
  app.use express.limit('1mb')

app.dynamicHelpers
  version: (req, res) ->
    return package_info.version

validateHID = (hid) ->
  if hid[1..2] is "08"
    return true
  else
    return false

ensureSession = (req, res, next) ->
  if not req.session.person
    res.redirect "/in?whence=#{req.url}"
  else
    next()

# Redirect requests coming from
# unsupported browsers to landing
# page for old browsers.
browserCheck = (req, res, next) ->
  ua = req.headers['user-agent']
  if ua.indexOf("MSIE") isnt -1
    regex = /MSIE\s(\d{1,2}\.\d)/.exec(ua)
    version = Number(regex[1])
    if version < 8
      return res.redirect "/unsupported"
  next()

app.get "/", browserCheck, (req, res) ->
  if req.session.person
    res.redirect "/lounge"
  else
    res.render "index"
      failed: false
      email: ''
      appmode: false
 
app.get "/unsupported", (req, res) ->
  res.render "unsupported"
    appmode: false

app.get "/what", browserCheck, (req, res) ->
  res.render "what"
    appmode: req.session.person

app.get "/who", browserCheck, (req, res) ->
  res.render "who"
    appmode: req.session.person

app.get "/up", browserCheck, (req, res) ->
  if req.session.person
    res.redirect "/lounge"
  else
    res.render "up"
      appmode: false
      failed: false
      dorms: models.DORMS
      dorm: ''
      notevil: ''
      ovaries: ''
      first: ''
      last: ''
      email: ''
      hid: ''

app.post "/up", (req, res) ->
  hid = req.body.hid or ''
  first = req.body.first
  last = req.body.last
  email = req.body.email
  password1 = req.body.password1
  password2 = req.body.password2
  ovaries = req.body.ovaries
  dorm = req.body.dorm
  notevil = req.body.notevil

  fail = () ->
    res.render "up"
      appmode: false
      failed: true
      dorms: models.DORMS
      hid: hid
      dorm: dorm
      notevil: notevil
      ovaries: ovaries
      first: first
      last: last
      email: email

  if password1 isnt password2
    fail()
  else if !first or !last
    fail()
  else if password1.length < 5
    fail()
  else if !isValidEmailAddress(email)
    fail()
  else if _.isUndefined(notevil)
    fail()
  else if dorm not in models.DORMS
    fail()
  # else if hid[1..2] isnt "08" or hid.length isnt 8
  else if !validateHID(hid)
    fail()
  else
    person = new models.Person()
    person.hid = Number(hid)
    person.first = first
    person.last = last
    person.email = email
    if ovaries
      person.ovaries = true
    else
      person.ovaries = false
    person.password = password1
    person.dorm = dorm
    person.save (err) ->
      if err
        console.log err
        fail()
      else
        async.waterfall [
          (wf_callback) ->
            models.Group
              .findOne()
              .where("name", person.dorm)
              .run (err, group) ->
                wf_callback err, group

          (group, wf_callback) ->
            person.groups.addToSet group
            person.save (err) ->
              wf_callback err, group

          (group, wf_callback) ->
            group.members.addToSet person
            group.save wf_callback
        ], (err) ->
          if err
            console.log err
            fail()
          else
            # Log them in.
            req.session.person =
              _id: String(person._id)
              first: person.first
              last: person.last
            res.redirect "/lounge"

app.get "/in", browserCheck, (req, res) ->
  res.render "in"
      appmode: false
      failed: false
      email: ''

app.post "/in", (req, res) ->
  email = req.body.email or ''
  password = req.body.password

  fail = () ->
    res.render "in"
      appmode: false
      failed: true
      email: email

  models.Person
    .findOne()
    .where("email", email)
    .run (err, person) ->
      if err or not person
        fail()
      else
        if pwh.verify(password, person.password)
          req.session.person =
            _id: String(person._id)
            first: person.first
            last: person.last
          res.redirect "/lounge"
        else
          fail()

app.get "/out", (req, res) ->
  req.session.destroy()
  res.redirect "/"

app.get "/forgot", (req, res) ->
  res.render "forgot"
    appmode: false
    failed: false
    email: ''

app.get "/forgot/sent", (req, res) ->
  res.render "forgot-sent"
    appmode: false

app.get "/forgot/complete", (req, res) ->
  res.render "forgot-complete"
    appmode: false

app.post "/forgot", (req, res) ->
  email = req.body.email
  models.Person
    .findOne()
    .where("email", email)
    .run (err, person) ->
      if err or not person
        res.render "forgot"
          appmode: false
          failed: true
          email: email
      else
        reset_token = uuid.v4()
        reset_url = "http://#{req.headers.host}/forgot/#{reset_token}"
        options =
          from: "Veritas <#{secrets.EMAIL_ADDRESS}>"
          to: person.email
          subject: "Password reset"
          html: """
                <pre>
                  Hey #{person.first},

                  Word on the street is that you want to reset your password on Veritas.

                  To do so, just click here: <a href="#{reset_url}">#{reset_url}</a>

                  If you didn't request this reset, you can safely ignore this message.

                  Peace out.
                </pre>
                """
        async.parallel [
          (cb) ->
            models.Person.update {email: email}, {reset_token: reset_token}, cb
          (cb) ->
            smtp.sendMail options, cb
        ], (err) ->
          if err
            console.log err
            res.render "error"
              appmode: false
          else
            res.redirect "/forgot/sent"

app.get "/forgot/:token", (req, res) ->
  reset_token = req.params.token
  models.Person
    .findOne()
    .where("reset_token", reset_token)
    .run (err, person) ->
      if err or not person
        res.render "error"
          appmode: false
          failed: false
      else
        res.render "forgot-reset"
          appmode: false
          failed: false

app.post "/forgot/:token", (req, res) ->
  reset_token = req.params.token
  pw1 = req.body.pw1
  pw2 = req.body.pw2
  if pw1 isnt pw2
    res.render "forgot-reset"
      appmode: false
      failed: true
  else
    models.Person.update {reset_token: reset_token},
      {password: pwh.generate(pw1), $unset: {reset_token: 1}},
      (err, person) ->
        if err or not person
          console.log err
          res.render "error"
            appmode: false
        else
          res.redirect "/forgot/complete"

app.post "/validate", (req, res) ->
  if validateHID(req.body.hid)
    res.send "OK"
  else
    res.send "BUTT SIRRR"

app.get "/people/:id", ensureSession, (req, res) ->
  if req.params.id is "me"
    return res.redirect "/people/#{req.session.person._id}"

  id = req.params.id
  models.Person
    .findOne()
    .where("_id", id)
    .populate("groups")
    .run (err, person) ->
      if err or not person
        res.render "error"
          appmode: false
      else
        res.render "person"
          appmode: true
          person: person

app.get "/choose", ensureSession, (req, res) ->
  models.Group
    .where("flag", "harvard-course")
    .select("name")
    .run (err, courses) ->
      console.log err
      res.render "choose"
        appmode: true
        courses: JSON.stringify courses

app.get "/lounge*", ensureSession, (req, res) ->
  person = req.session.person

  async.parallel [
    (cb) ->
      models.Person
        .findOne()
        .where("_id", person._id)
        .select("first", "last", "groups")
        .populate("groups")
        .run cb
    (cb) ->
      models.Group
        .where("flag", "harvard-global")
        .populate("members", ["first", "last"])
        .run cb
  ],
  (err, results) ->
    if err
      res.render "error"
    else
      person = results[0]
      global_groups = results[1]

      if !person or !global_groups
        return res.redirect "/out"
      unless person.groups.length > 1 # 1 = dorm
        return res.redirect "/choose"

      # XXX: Don't do this hardcode patch crap.
      # Actually specify in the query.
      groups = _.union(person.groups, global_groups)
      for group in groups
        group.messages = group.messages[-200..]

      res.render "lounge"
        appmode: true
        groups_bootstrap: JSON.stringify groups

curses = [
  "fuck",
  "shit",
  "bitch",
  "douche",
  "cock",
  "fag",
  "faggot",
  "nigger",
  "cunt",
  "whore",
  "dick",
  "penis",
  "vagina",
  "pussy",
  "bastard",
  "tits",
  "titty",
  "titties"
]

cleans = [
  "squidward",
  "jigglypuff",
  "trollface",
  "cowsaysmoo",
  "soap",
  "AGNRY FAIC",
  "Sarah Palin",
  "N00t G1ngr1ch",
  "l.o.l",
  "$#&!*#$*@&!&$",
  "pikachu",
  "creampuffs",
  "mushrooms",
  "Kleenex",
  "POLAR BEARS",
  "OVER 9000",
  "supersain",
  "deep",
  "BUT SIRRR",
  "DEEEEEEEEEEEEEEP",
  "GREAT SUCCESS",
  "chair",
  "ductape",
  "agua",
  "חביטאח",
  "watermellon",
  "Wal-Mart",
  "EXCEELLLENT",
  "thorax",
  "timmy",
  "bob saget"
]

cussFilter = (text) ->
  for curse in curses
    pattern = new RegExp curse, 'gi'
    text = text.replace pattern, cleans[Math.floor(Math.random() * cleans.length)]
  text

io.set "authorization", (data, accept) ->
  if data.headers.cookie
    data.cookie = connect.utils.parseCookie data.headers.cookie
    data.sessionID = data.cookie['express.sid']
    data.sessionStore = sessionStore
    sessionStore.get data.sessionID, (err, session) ->
      if err
        accept err.message.toString(), false
      else
        data.session = new connect.middleware.session.Session data, session
        if not data.session.person
          accept "No session person", false
        else
          accept null, true
  else
    accept "No cookie transmitted.", false

io.sockets.on "connection", (socket) ->
  person = socket.handshake.session.person
  socket.join person._id

  if _.has online, person._id
    online[person._id].count += 1
  else
    online[person._id] =
      name: "#{person.first} #{person.last}"
      id: person._id
      count: 1
    socket.broadcast.emit "online", _.values online

  sync = (model, method, data) ->
    event_name = "#{model}/#{data._id}:#{method}"
    io.sockets.emit event_name, data

  socket.on "get online", (cb) ->
    cb _.values(online)

  socket.on "group:message", (group_id, body, cb) ->
    if body.length > 1000
      return cb "length"

    message =
      first: person.first
      last: person.last
      person_id: person._id
      body: cussFilter body

    models.Group.update {_id: group_id},
      {$push: {messages: message}},
      (err) ->
        cb err
        unless err
          io.sockets.emit "message", message: message, group: group_id


  socket.on "join groups", (groups, cb) ->
    done = (err) ->
      cb err

    itr = (group_id, async_cb) ->
      async.waterfall [
        (wf_callback) ->
          models.Person
            .findOne()
            .where("_id", person._id)
            .run wf_callback

        (account, wf_callback) ->
          models.Group
            .findOne()
            .where("_id", group_id)
            .run (err, group) ->
              wf_callback err, account, group

        (account, group, wf_callback) ->
          account.groups.addToSet group
          account.save (err, account) ->
            wf_callback err, account, group

        (account, group, wf_callback) ->
          group.members.addToSet account
          group.save wf_callback
      ], async_cb

    async.forEach groups, itr, done

  socket.on "disconnect", () ->
    # Decrement count
    online[person._id].count -= 1
    # Remove user if there's no more ghosts
    if online[person._id].count is 0
      delete online[person._id]
      socket.broadcast.emit "online", _.values online