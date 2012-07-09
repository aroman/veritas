# Copyright (C) 2012 Avi Romanoff <aviromanoff at gmail.com>

_          = require "underscore"
fs         = require "fs"
os         = require "os"
pwh        = require "password-hash"
chbs       = require "connect-handlebars"
async      = require "async"
colors     = require "colors"
connect    = require "connect"
express    = require "express"
socketio   = require "socket.io"
MongoStore = require("connect-mongo")(express)

models     = require "./models"
secrets    = require "./secrets"

package_info = JSON.parse(fs.readFileSync "#{__dirname}/package.json", "utf-8")

app = express.createServer()
io = socketio.listen app

io.set 'transports', [
  'htmlfile',
  'xhr-polling',
  'jsonp-polling'
]

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

ensureSession = (req, res, next) ->
  if not req.session.username
    res.redirect "/?whence=#{req.url}"
  else
    next()

app.get "/", (req, res) ->
  if req.session.username
    res.redirect "/lounge"
  else
    res.render "index"
      appmode: false
 
app.get "/what", (req, res) ->
  res.render "what"
    appmode: req.session.username

app.get "/who", (req, res) ->
  res.render "who"
    appmode: req.session.username

app.get "/up", (req, res) ->
  if req.session.username
    res.redirect "/lounge"
  else
    res.render "up"
      appmode: false
      failed: false
      dorms: models.DORMS
      dorm: ''
      notevil: ''
      ovaries: ''
      username: ''
      hid: ''

app.post "/up", (req, res) ->
  hid = req.body.hid or ''
  username = req.body.username
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
      username: username

  if password1 isnt password2
    fail()
  else if username < 5 or username > 18
    fail()
  else if password1.length < 5
    fail()
  else if " " in username
    fail()
  else if _.isUndefined(notevil)
    fail()
  else if dorm not in models.DORMS
    fail()
  else if hid[3..4] isnt "66" or hid.length isnt 8
    fail()
  else
    person = new models.Person()
    person.hid = Number(hid)
    person.username = username
    if ovaries
      person.ovaries = true
    else
      person.ovaries = false
    person.password = password1
    person.dorm = dorm
    person.save (err) ->
      if err
        fail()
      else
        res.redirect "/"

app.get "/in", (req, res) ->
  res.render "in"
    appmode: false
    failed: false
    username: ''

app.post "/in", (req, res) ->
  username = req.body.username or ''
  password = req.body.password

  fail = () ->
    res.render "in"
      appmode: false
      failed: true
      username: username

  models.Person
    .findOne()
    .where("username", username)
    .run (err, person) ->
      if err or not person
        fail()
      else
        if pwh.verify(password, person.password)
          req.session.username = username
          res.redirect "/lounge"
        else
          fail()

app.get "/out", (req, res) ->
  req.session.destroy()
  res.redirect "/"

app.post "/validate", (req, res) ->
  hid = req.body.hid
  if hid[3..4] is "66" and hid.length is 8
    res.send "OK"
  else
    res.send "BUT SIRRR"

app.post "/username", (req, res) ->
  username = req.body.username
  models.Person
    .findOne()
    .where("username", username)
    .run (err, person) ->
      if person
        res.send "umad?"
      else
        res.send "OK"

app.get "/people/:id", ensureSession, (req, res) ->
  if req.params.id is "me"
    id = req.session.username
  else
    id = req.params.id
  models.Person
    .findOne()
    .where("username", id)
    .populate("groups")
    .run (err, person) ->
      if err or not person
        res.render "error"
          appmode: false
      else
        res.render "person"
          appmode: true
          person: person


app.post "/people/:id", ensureSession, (req, res) ->
  res.render "person"
    appmode: true

app.get "/lounge*", ensureSession, (req, res) ->
  username = req.session.username
  async.parallel [
    (cb) ->
      models.Group
        .find()
        .populate("members", ["username"])
        .run cb
  ],
  (err, results) ->
    if err
      res.render "error"
    else
      # Copy the online list and add ourselves
      # to a local copy of it for bootstrap sake
      # if needed. (Initial page req.)
      _online = _.clone online
      unless _.has _online, username
        _online[username] = 1
      res.render "lounge"
        appmode: true
        groups_bootstrap: JSON.stringify results[0]
        online: JSON.stringify _.keys(_online)

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
  "ass",
  "dick",
  "penis",
  "vagina",
  "pussy",
  "tits"
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
  "James"
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
        accept null, true
  else
    accept "No cookie transmitted.", false

io.sockets.on "connection", (socket) ->
  username = socket.handshake.session.username
  socket.join username

  if _.has online, username
    online[username]++
  else
    online[username] = 1

  socket.broadcast.emit "online", _.keys(online)

  sync = (model, method, data) ->
    event_name = "#{model}/#{data._id}:#{method}"
    io.sockets.emit event_name, data

  # Broadcasts a message to all connected sessions,
  # INCLUDING the one that initiated the message.
  # broadcast = (message, data) ->
  #   io.sockets.in(token.username).emit(message, data)

  socket.on "group:create", (data, cb) ->
    async.waterfall [
      (wf_callback) ->
        models.Person
          .findOne()
          .where("username", username)
          .run wf_callback
      (account, wf_callback) ->
        group = new models.Group()
        group.name = data.name
        group.members.push account
        group.save (err, group) ->
          wf_callback err, account, group
      (account, group, wf_callback) ->
        account.groups.push group
        account.save (err, account) ->
          wf_callback err, group
    ],
    (err, group) ->
      socket.broadcast.emit "groups:add", group
      cb err, group

  socket.on "group:message", (group_id, body, cb) ->
    async.waterfall [
      (wf_callback) ->
        models.Group
          .findOne()
          .where("_id", group_id)
          .run wf_callback
      (group, wf_callback) ->
        message =
          username: username
          body: cussFilter body
        group.messages.push message
        group.save (err) ->
          wf_callback err, group, message
    ],
    (err, group, message) ->
      io.sockets.emit "message", message: message, group: group._id
      cb err

  socket.on "disconnect", () ->
    online[username]--
    if online[username] is 0
      delete online[username]
    socket.broadcast.emit "online", _.keys(online)