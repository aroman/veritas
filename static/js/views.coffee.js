AppView = Backbone.View.extend
  el: $("body"),

  events:
    "keyup #thebox": "foobar"

  foobar: () =>
