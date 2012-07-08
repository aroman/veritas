window.FindPeopleView = Backbone.View.extend
  el: "#find-people"

  events:
    "keyup #thebox": "search"
    "click .create-group": "createGroup"

  initialize: () ->
    @render()

  render: () ->
    @$el.show()
    @$el.html Handlebars.templates.finder()

  showGroups: (models) ->
    @$("#results").html Handlebars.templates.foobar(groups: models)

  createGroup: (e) ->
    name = $(e.target).data("name")
    group = new Group name: name

    success_cb = () ->
      groups.add group
      router.navigate "/groups/#{group.id}", true

    error_cb = () ->
      alert "OH SHIT SOMETHING BROKE"

    group.save {}, {success: success_cb, error: error_cb}

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

  remove: () ->
   @$el.hide()
   @$el.children().remove()
   return @

window.FindGroupsView = Backbone.View.extend
  el: "#find-groups"

  events:
    "keyup #thebox": "search"
    "click .create-group": "createGroup"

  initialize: () ->
    @render()

  render: () ->
    @$el.show()
    @$el.html Handlebars.templates.finder()

  showGroups: (models) ->
    @$("#results").html Handlebars.templates.foobar(groups: models)

  createGroup: (e) ->
    name = $(e.target).data("name")
    group = new Group name: name

    success_cb = () ->
      groups.add group
      router.navigate "/groups/#{group.id}", true

    error_cb = () ->
      alert "OH SHIT SOMETHING BROKE"

    group.save {}, {success: success_cb, error: error_cb}

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

  remove: () ->
   @$el.hide()
   @$el.children().remove()
   return @

window.GroupView = Backbone.View.extend
  el: "#group"
  color_bank: [
    "#C91371",
    "#6477CA",
    "#869A80",
    "#F79B06",
    "#CE9F9F",
    "#1EA3D2",
    "#A2C085",
    "#87BB06",
    "#BD1FFC",
    "#3FCECB",
    "#F8D19E",
    "#48EE59",
    "#A8E947",
    "#11A0E1",
    "#DAD2AD",
    "#FAC528",
    "#D92A53",
    "#EED516",
    "#F3322A",
    "#579C94"
  ]
  colors: {}

  events:
    "keyup #chat-input": "addMessage"

  initialize: () ->
    @render()

  render: () ->
    @$el.show()
    @$('.inner').html Handlebars.templates.group @colorize(@model.toJSON())
    # Scroll to the bottom
    @$("#messages").scrollTop 1234567890
    @$("#chat-input").focus()
    @model.set unread: 0
    app.updateGroupList()

  getColor: (username) ->
    unless _.has @colors, username
      @colors[username] = @color_bank[Math.floor(Math.random() * @color_bank.length)]
    @colors[username]

  colorize: (group) ->
    colorized = []
    _.each group.messages, (message) =>
      message.color = @getColor message.username
      colorized.push message
    group.messages = colorized
    return group

  pushMessage: (message) ->
    str = '<p><span style="color:'+@getColor(message.username)+'">'+message.username+': </span>'+message.body+'</p>'
    @$("#messages").append(str)
    @$("#messages").scrollTop 1234567890

  addMessage: (e) ->
    if e.keyCode is 13
      message = @$(e.target).val()
      @$(e.target).val('')
      if message
        socket.emit "group:message", @model.id, message, (err, res) =>
          if err
            alert "FUCK FUCK SOMETHING BROKE OH SHIT"
          else
            @render

  remove: () ->
    @$el.hide()
    @$el.children().empty()
    @undelegateEvents() 
    return @

window.AppView = Backbone.View.extend
  el: "body"
  username: null

  events:
    "click a[data-route]": "routeInternal"

  initialize: () ->
    @updateGroupList()
    router.on 'highlight', this.highlightSidebar, this
    groups.on "add remove", @updateGroupList, this
    socket.on "online", (people) =>
      console.log people
      @updatePersonList people
    socket.on "message", (data) =>
      group = groups.get data.group
      group.get('messages').push data.message
      if router.current_view.model.id is group.id
        console.log "We're currently viewing this group"
        router.current_view.pushMessage data.message
      else
        console.log "Not currently viewing"
        group.set unread: group.get('unread') + 1
        @updateGroupList()

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
    @highlightSidebar()

  updatePersonList: (people) ->
    @$("#people").html Handlebars.templates.sidebar_people(people: people)

  highlightSidebar: () ->
    @$('li.active:not(.nav-link)').removeClass('active')
    @$("a[href='/#{Backbone.history.fragment}']").parent().addClass('active')