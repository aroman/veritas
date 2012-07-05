# Copyright (C) 2012 Avi Romanoff <aviromanoff at gmail.com>

_          = require "underscore"
fs         = require "fs"
os         = require "os"
colors     = require "colors"
connect    = require "connect"
express    = require "express"
socketio   = require "socket.io"
MongoStore = require("connect-mongo")(express)

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
    console.log "   _______".red
    console.log "    VE RI \n     TAS".red

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
  res.render "index"
    failed: false

app.post "/", (req, res) ->
  email = req.body.email
  password = req.body.password
  whence = req.query.whence
 
# app.get "/about", (req, res) ->
#   res.render "about"
#     appmode: false

# app.get "/help", (req, res) ->
#   res.render "help"
#     appmode: false

# app.get "/feedback", (req, res) ->
#   jbha.Client.read_feedbacks (err, feedbacks) ->
#     res.render "feedback"
#       feedbacks: feedbacks
#       appmode: false

# app.get "/logout", (req, res) ->
#   req.session.destroy()
#   res.redirect "/"

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