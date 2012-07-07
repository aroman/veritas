window.FinderView = Backbone.View.extend
  el: "#finder"

  events:
    "keyup #thebox": "search"
    "click .create-group": "createGroup"

  initialize: () ->
    @render()

  render: () ->
    @$el.html Handlebars.templates.finder()

  showGroups: (models) ->
    @$("#results").html Handlebars.templates.foobar(groups: models)

  createGroup: (e) ->
    name = $(e.target).data("name")
    group = new Group name: name
    groups.add group
    group.save()

  search: (e) ->
    fragment = @$("#thebox").val()
    if fragment
      matches = groups.filter (group) ->
        ~group.get('name').indexOf fragment
      if matches.length > 0
        @showGroups matches
      else
        @$("#results").html Handlebars.templates.no_groups(name: fragment)
    else
      @$("#results").html "Start typing <3"

window.GroupView = Backbone.View.extend
  el: "#group"
  colors: {}

  events:
    "keyup #chat-input": "addMessage"

  initialize: () ->
    @render()
    @model.on "change:messages", () =>
      @render()

  render: () ->
    @$el.html Handlebars.templates.group @colorize(@model.toJSON())
    # Scroll to the bottom
    @$("#messages").scrollTop @$("#messages").prop("scrollHeight")

  colorize: (group) ->
    colorized = []
    _.each group.messages, (message) =>
      # color already generated
      if _.has @colors, message.username
        message.color = @colors[message.username]
      else
        @colors[message.username] = "#"+((1<<24)*Math.random()|0).toString(16)
        message.color = @colors[message.username]
      colorized.push message
    group.messages = colorized
    return group


  addMessage: (e) ->
    if e.keyCode is 13
      message = @$(e.target).val()
      console.log message
      socket.emit "group:message", @model.id, message, (err, res) ->
        if err
          alert("FUCK FUCK SOMETHING BROKE OH SHIT")
          @$el.html Handlebars.templates.group @model.toJSON()

window.AppView = Backbone.View.extend
  el: "body"
  username: null

  events:
    "click a[data-route]": "routeInternal"

  initialize: () ->
    @updateGroupList()
    groups.on "add remove", @updateGroupList, this
    socket.on "online", (people) =>
      @updatePersonList people

  routeInternal: (e) ->
    target = $(e.target)
    href = target.attr "href"
    protocol = window.location.protocol + "//"

    # Ensure the protocol is not part of URL, meaning its relative.
    if href && href[0:protocol.length] != protocol && "javascript:" not in href
      # Stop the default event to ensure the link will not cause a page
      # refresh.
      e.preventDefault()

      # This uses the default router defined above, and not any routers
      # that may be placed in modules.  To have this work globally (at the
      # cost of losing all route events) you can change the following line
      # to: Backbone.history.navigate(href, true);
      router.navigate(href, true);

  updateGroupList: () ->
    @$("#groups").html Handlebars.templates.sidebar_groups(groups: groups.toJSON())

  updatePersonList: (people) ->
    @$("#people").html Handlebars.templates.sidebar_people(people: people)