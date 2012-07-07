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

M.PersonSchema = new mongoose.Schema
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
  joined:
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

  groups:
    [
      type: mongoose.Schema.ObjectId
      ref: 'group'
    ]

  nickname: String

M.Person = mongoose.model 'person', M.PersonSchema

M.GroupSchema = new mongoose.Schema
  name:
    type: String
    required: true
    unique: true
  created:
    type: Date
    required: true
    default: Date.now()
  members:
    [
      type: mongoose.Schema.ObjectId
      ref: 'person'
    ]

M.Group = mongoose.model 'group', M.GroupSchema

module.exports = M