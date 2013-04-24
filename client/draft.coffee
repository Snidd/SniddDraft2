Template.draftInProgress.rendered = ->
  Meteor.defer ->
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
      console.log "plumbing!"
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
        when 505
          console.log "No access"
        when 601
          console.log "Card already picked"
      true
    pickCardField.value = ''
    false

Template.viewDraftInProgress.helpers
  draftMembers: ->
    currentDraft = getCurrentDraft()
    currentDraft.members
  picksByMember: (memberId) ->
    currentDraft = getCurrentDraft()
    currentDraft.picks.filter (pick) ->
      pick.member.id is memberId
  cardColorClass: (card) ->
    getCardColorClass card

Template.draftInProgress.helpers
  pickOrder: ->
    currentDraft = getCurrentDraft()
    for i in [0..currentDraft.members.length*4] by 1
      pickPosition = getNextPickPosition(i + currentDraft.picks.length , currentDraft.members.length)
      pick = {}
      pick.id = currentDraft.members[pickPosition].id
      pick.email = currentDraft.members[pickPosition].email
      pick.counter = i
      pick.position = pickPosition+1
      pick.cssclass = if pick.id is Meteor.userId() then "self" else "player#{pickPosition}" 
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
  if colors.length > 2 then return "gold"
  if colors.length is 0 then return "colorless"
  return colors[0] + colors[1]



