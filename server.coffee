# Copyright (C) 2012 Avi Romanoff <aviromanoff at gmail.com>

_          = require "underscore"
fs         = require "fs"
os         = require "os"
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
  req.token = req.session.token
  if not req.token
    res.redirect "/?whene=#{req.url}"
  else
    next()

app.get "/", (req, res) ->
  username = req.session.username
  if username
    res.redirect "/app"
  res.render "index"
    appmode: false
 
app.get "/what", (req, res) ->
  res.render "what"
    appmode: false

app.get "/who", (req, res) ->
  res.render "who"
    appmode: false

app.get "/up", (req, res) ->
  res.render "up"
    appmode: false
    failed: false
    dorms: models.DORMS
    dorm: 'derp'
    notevil: ''
    hid: ''

app.post "/up", (req, res) ->
  hid = req.body.hid || ''
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

  if password1 isnt password2
    fail()
  else if password1.length < 5
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

app.get "/out", (req, res) ->
  req.session.destroy()
  res.redirect "/"

app.post "/validate", (req, res) ->
  hid = req.body.hid
  if hid[3..4] is "66" and hid.length is 8
    res.send "OK"
  else
    res.send "BUT SIRRR"

# app.get "/setup", ensureSession, (req, res) ->
#   if req.settings.is_new
#     res.render "setup"
#       appmode: false
#       settings: JSON.stringify req.settings
#   else
#     res.redirect "/"

# app.post "/setup", ensureSession, (req, res) ->
#   settings =
#     firstrun: true
#   if req.body.nickname
#     settings.nickname = req.body.nickname
#   jbha.Client.update_settings req.token, settings, ->
#     res.redirect "/"

# app.get "/app*", ensureSession, (req, res) ->
#   jbha.Client.by_course req.token, (courses) ->
#     if !req.settings || req.settings.is_new
#       res.redirect "/setup"
#     else
#       res.render "app"
#         info: package_info

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