linkify = (text) ->
  # URLs starting with http://, https://, or ftp://
  replacePattern1 = /(\b(https?|ftp):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/gim
  replacedText = text.replace(replacePattern1, '<a href="$1" target="_blank">$1</a>')

  # URLs starting with www. (without // before it, or it'd re-link the ones done above)
  replacePattern2 = /(^|[^\/])(www\.[\S]+(\b|$))/gim
  replacedText = replacedText.replace(replacePattern2, '$1<a href="http://$2" target="_blank">$2</a>')

  # Change email addresses to mailto:: links
  replacePattern3 = /(\w+@[a-zA-Z_]+?\.[a-zA-Z]{2,6})/gim
  replacedText = replacedText.replace(replacePattern3, '<a href="mailto:$1">$1</a>')

  return replacedText

Handlebars.registerHelper "render_message", (o) =>
  """
    <p>
      <a href="/people/#{o.person_id}" style="color:#{o.color}"> #{o.first}</a>: #{linkify(o.body)}
    </p>
  """

window.ChooseView = Backbone.View.extend
  el: "#choose"
  #TODO: Determine whether this is still needed.
  selected: []

  events:
    "keyup #thebox": "search"
    "click .join-group": "joinGroup"
    "click .leave-group": "leaveGroup"
    "click #go": "go"

  initialize: () ->
    @render()

  render: () ->
    @$el.show()
    @$el.html Handlebars.templates.finder(selected: @selected)
    @$("#thebox").focus()

  go: (e) ->
    $(e.target).button("loading")
    @$(":input").prop('disabled', true)

    ack = (err) =>
      if err
        $(e.target).button('reset')
        @$(":input").prop('disabled', false)
        @$("#error").show()
      else
        window.location.replace("#{location.protocol}//#{location.host}/lounge");

    socket.emit "join groups", _.pluck(@selected, "_id"), ack

  joinGroup: (e) ->
    id = $(e.target).data("id")
    @selected.push
      _id: id
      name: $(e.target).text()
    for course, index in harvard_courses
      if course._id is id
        harvard_courses[index].selected = true
        break
    @render()

  leaveGroup: (e) ->
    id = $(e.target).data("id")
    group = _.find @selected, (group) ->
      group._id == id
    @selected.splice _.indexOf(@selected, group), 1
    for course, index in harvard_courses
      if course._id is id
        delete harvard_courses[index].selected
        break
    @render()

  showGroups: (models) ->
    @$("#results").html Handlebars.templates.foobar(groups: models)

  search: (e) ->
    fragment = @$("#thebox").val()
    if fragment.length
      matches = harvard_courses.filter (course) ->
        course.name.toLowerCase().indexOf(fragment.toLowerCase()) isnt -1
      if matches.length > 0
        @showGroups matches
        @$("#thebox").parent().removeClass("error")
      else
        @$("#results").html Handlebars.templates.no_groups(name: fragment)
        @$("#thebox").parent().addClass("error")
    else
      @render()

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
    if @model.get('messages').length is 0
      @$("#messages").html """
        <div id="emptybit" class="centex">
          <i>No messages yet :'(
        </div>
      """
    # Scroll to the bottom
    @$("#messages").scrollTop 1234567890
    @$("#chat-input").focus()
    @model.set unread: 0
    app.updateGroupList()

  getColor: (person_id) ->
    unless _.has @colors, person_id
      @colors[person_id] = @color_bank[Math.floor(Math.random() * @color_bank.length)]
    @colors[person_id]

  colorize: (group) ->
    colorized = []
    _.each group.messages, (message) =>
      message.color = @getColor message.person_id
      colorized.push message
    group.messages = colorized
    return group

  pushMessage: (message) ->
    @$("#emptybit").hide()
    @$("#messages").append Handlebars.helpers.render_message(message)
    @$("#messages").scrollTop 1234567890

  addMessage: (e) ->
    if e.keyCode is 13
      body = @$(e.target).val()
      return unless body
      @$(e.target).prop "disabled", true
      socket.emit "group:message", @model.id, body, (err) =>
        @$(e.target).prop "disabled", false
        if err
          if err is "length"
            alert "Message too large (> 1000 characters) to post."
          else
            alert "Message failed for an unknown reason. Yell at Avi."
        else
          @$(e.target).val('')

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
    # Fetch from server
    socket.emit "get online", (people) =>
      @updatePersonList people
    # Subscribe to future updates
    socket.on "online", (people) =>
      @updatePersonList people
    socket.on "message", (data) =>
      group = groups.get data.group
      group.get('messages').push data.message
      if router.current_view and router.current_view.model.id is group.id
        router.current_view.pushMessage data.message
      else
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
    console.log people
    @$("#people").html Handlebars.templates.sidebar_people(people: people)

  highlightSidebar: () ->
    @$('li.active:not(.nav-link)').removeClass('active')
    @$("a[href='/#{Backbone.history.fragment}']").parent().addClass('active')