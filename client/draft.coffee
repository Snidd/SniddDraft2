Template.draftInProgress.rendered = ->
  Meteor.defer ->

    $("input.important").popover
      offset: 10
      trigger: 'hover'
      animate: false
      html: false
      placement: 'right'
      #content: '<span class="popovertext">When this checkbox is checked, it will not continue to pick any cards if this card is missing. If its NOT checked, it will continue with the next pick on your list.</span>'
      #title: '<span class="popovertext">Important flag</span>'
      content: 'When this checkbox is checked, it will not continue to pick any cards if this card is missing. If its NOT checked, it will continue with the next pick on your list.'
      title: 'Important flag'
    
    jsPlumb.ready ->
      jsPlumb.Defaults.Anchors =
        ["RightMiddle", "LeftMiddle"]
      jsPlumb.Defaults.Endpoint =
        "Blank"
      jsPlumb.Defaults.Connector =
        ["Flowchart", 25]
      jsPlumb.Defaults.Overlays =
        ["Arrow"]
      jsPlumb.Defaults.PaintStyle =
        lineWidth: 2,
        strokeStyle: "#000"

      ###
      draft = getCurrentDraft()
      if draft.picks.length > 0
      jsPlumb.connect
        source: "future0"
        target: "pick1"
        connector: [ "Flowchart", 25 ],
        anchors: ["TopCenter", "TopCenter"]

      jsPlumb.connect
        source: "future0"
        target: "info1"
        connector: [ "Flowchart", 25 ],
        anchors: ["RightMiddle", "LeftMiddle"]
      ###

Template.draftPick.events
  'submit #pickCardForm' : ->
    pickCardField = document.getElementById('pickCard')
    cardName = pickCardField.value
    console.log "Picking #{cardName}"
    Meteor.call "pickCard", cardName, Session.get("currentDraftId"), (error, result) ->
      switch error?.error
        when 404
          console.log "Card not found"
          $("#pickContainer").append(alertDiv "Not found!", "#{cardName} unfortunately doesn't exist.")
        when 505
          console.log "No access"
          $("#pickContainer").append(alertDiv "Weeelll", "No, just no.")
        when 601
          console.log "Card already picked"
          $("#pickContainer").append(alertDiv "#{cardName}", "Is already picked!")
      true
    pickCardField.value = ''
    false

Template.spreadsheet.helpers
  draftMembers: ->
    currentDraft = getCurrentDraft()
    for i in [0..currentDraft.members.length-1] by 1
      if currentDraft.members[i].id is Meteor.userId()
        currentDraft.members[i].cssclass = "self"
      else
        currentDraft.members[i].cssclass = "player#{i}"
    currentDraft.members
  picksByMember: (memberId) ->
    currentDraft = getCurrentDraft()
    currentDraft.picks.filter (pick) ->
      pick.member.id is memberId
  cardColorClass: (card) ->
    getCardColorClass card
  currentDraft: ->
    getCurrentDraft()

Template.switchView.helpers
  switchTo: ->
    ret = {url: "/404", text: "Unknown"}
    switch Meteor.Router.page()
      when 'draft'
        ret = 
          url: Meteor.Router.spreadsheetPath(Session.get('currentDraftId'))
          text: "Spreadsheet view"
      when 'spreadsheet'
        ret = 
          url: Meteor.Router.draftPath(Session.get('currentDraftId'))
          text: "Draft view"
    return ret

Template.draftInProgress.events
  'click .close.futurepick': (event) ->
    console.log "Removing #{this.name}"
    Meteor.call "removeFuturePick", this.name, Session.get("currentDraftId")
    false
  'click .important': (event) ->
    important = event.currentTarget.checked
    Meteor.call "setImportant", Session.get("currentDraftId"), this.name, important
    console.log "setting #{this.name} to important: #{important}"
    $("#" + event.currentTarget.id).popover('show')
    event.preventDefault()
  'mouseenter .pick.waiting': (event) ->
    $(".pick.picked." + this.cssclass).addClass("highlight")
  'mouseleave .pick.waiting': ->
    $(".pick.picked." + this.cssclass).removeClass("highlight")
  'click .pick.waiting': ->
    $(".pick.picked." + this.cssclass).removeClass("hide")
    $(".pick.picked").not('.' + this.cssclass).addClass("hide")
    $("#showingall").removeClass("hide").addClass(this.cssclass)
    $("#showingall .member").text(this.email)
  'click #showallbtn' : (event) ->
    $(".pick.picked").removeClass("hide")
    $("#showingall").attr('class', 'pick filter hide')
  'mouseenter .pick.picked' : ->
    $(".pick.waiting.player" + this.playerNumber).addClass("highlight")
  'mouseleave .pick.picked' : ->
    $(".pick.waiting.player" + this.playerNumber).removeClass("highlight")

Template.draftInProgress.helpers
  currentDraft: ->
    getCurrentDraft()
  pickOrder: ->
    currentDraft = getCurrentDraft()
    for i in [0..currentDraft.members.length*4] by 1
      pickPosition = getNextPickPosition(i + currentDraft.picks.length , currentDraft.members.length)
      pick = {}
      pick.id = currentDraft.members[pickPosition].id
      pick.email = currentDraft.members[pickPosition].email
      pick.counter = i
      pick.position = pickPosition+1
      pick.cssclass = "player#{pickPosition}" 
      pick.isself = pick.id is Meteor.userId()
      pick
  pickHistory: ->
    currentDraft = getCurrentDraft()
    if !currentDraft.picks? or currentDraft.length is 0 
      return [new Pick("", "No picks yet")]
    else
      return currentDraft.picks.reverse()
  myFuture: ->
    FuturePicks.findOne
      userId: Meteor.userId()
      draftId: Session.get("currentDraftId")
  myTurn: ->
    draft = getCurrentDraft()
    pickPosition = getNextPickPosition(draft.picks.length,draft.members.length)
    return draft.members[pickPosition].id is Meteor.userId()
  cardColorClass: (card) ->
    getCardColorClass card

getCardColorClass = (card) ->
  if !card? then return "unknown"
  if !card.manacost? then return "unknown"
  white = card.manacost.indexOf("W",0) > -1
  blue = card.manacost.indexOf("U",0) > -1
  black = card.manacost.indexOf("B",0) > -1
  red = card.manacost.indexOf("R",0) > -1
  green = card.manacost.indexOf("G",0) > -1

  colors = []

  if white then colors.push "white"
  if blue then colors.push "blue"
  if black then colors.push "black"
  if red then colors.push "red"
  if green then colors.push "green"

  if colors.length is 1 then return colors[0]
  if colors.length > 3 then return "gold"
  if colors.length is 0 then return "colorless"
  if colors.length is 3 then return colors[0] + colors[1] + colors[2]
  return colors[0] + colors[1]



