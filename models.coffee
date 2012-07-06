# Copyright (C) 2012 Avi Romanoff <aviromanoff at gmail.com>

_            = require "underscore"
async        = require "async"
cheerio      = require "cheerio"
mongoose     = require "mongoose"
moment       = require "moment"
pwh          = require "password-hash"

secrets      = require "./secrets"

M = {}

mongoose.connect secrets.MONGO_URI

M.DORMS = [
          "Canaday",
          "Claverly",
          "Hollis",
          "Hurlbut",
          "Lionel",
          "Mower",
          "Pennypacker",
          "Stoughton",
          "Straus",
          "Thayer",
          "Wigglesworth"
        ]

M.AccountSchema = new mongoose.Schema
  hid:
    type: Number
    required: true
    unique: true
  username:
    type: String
    required: true
    unique: true
  password:
    type: String
    required: true
    set: (raw) ->
      pwh.generate(raw)
  date_created:
    type: Date
    required: true
    default: Date.now()
  firstrun:
    type: Boolean
    required: true
    default: true

  dorm:
    type: String
    required: true
    enum: M.DORMS

  nickname: String

M.Account = mongoose.model 'account', M.AccountSchema

module.exports = M