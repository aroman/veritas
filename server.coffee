# Copyright (C) 2012 Avi Romanoff <aviromanoff at gmail.com>

_          = require "underscore"
fs         = require "fs"
os         = require "os"
pwh        = require "password-hash"
colors     = require "colors"
connect    = require "connect"
express    = require "express"
socketio   = require "socket.io"
MongoStore = require("connect-mongo")(express)

models    = require "./models"
secrets    = require "./secrets"

package_info = JSON.parse(fs.readFileSync "#{__dirname}/package.json", "utf-8")

app = express.createServer()
io = socketio.listen app

sessionStore = new MongoStore
  db: 'keeba'
  url: secrets.MONGO_URI
  stringify: false
  clear_interval: 432000, # 5 days
  () ->
    app.listen 7331
    console.log "   ---------".red
    console.log "   | VE RI |".red
    console.log "    \\ TAS /".red
    console.log "     \\___/".red

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
  app.set 'jsonp callback'
  app.set 'view engine', 'jade'
  app.set 'views', "#{__dirname}/views"

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
      username: ''
      hid: ''

app.post "/up", (req, res) ->
  hid = req.body.hid or ''
  username = req.body.username
  password1 = req.body.password1
  password2 = req.body.password2
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
    account = new models.Account()
    account.hid = Number(hid)
    account.username = username
    account.password = password1
    account.dorm = dorm
    account.save (err) ->
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

  models.Account
    .findOne()
    .where("username", username)
    .run (err, account) ->
      if err or not account
        fail()
      else
        if pwh.verify(password, account.password)
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
  models.Account
    .findOne()
    .where("username", username)
    .run (err, account) ->
      if account
        res.send "umad?"
      else
        res.send "OK"

app.get "/lounge*", ensureSession, (req, res) ->
  res.render "lounge"
    appmode: true

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
        if not data.session.token
          accept "No session token", false
        else
          accept null, true
  else
    accept "No cookie transmitted.", false

io.sockets.on "connection", (socket) ->
  token = socket.handshake.session.token
  socket.join token.username

  # # Syncs model state to all connected sessions,
  # # EXCEPT the one that initiated the sync.
  # sync = (model, method, data) ->
  #   event_name = "#{model}/#{data._id}:#{method}"
  #   socket.broadcast.to(token.username).emit(event_name, data)

  # Broadcasts a message to all connected sessions,
  # INCLUDING the one that initiated the message.
  # broadcast = (message, data) ->
  #   io.sockets.in(token.username).emit(message, data)

  # socket.on "course:create", (data, cb) ->
  #   return unless _.isFunction cb
  #   jbha.Client.create_course token, data, (err, course) ->
  #     socket.broadcast.to(token.username).emit("courses:create", course)
  #     cb null, course