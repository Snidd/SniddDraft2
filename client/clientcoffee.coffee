

Meteor.Router.filters
  'checkLoggedIn': (page) ->
      if Meteor.loggingIn() then 'loading'
      else if Meteor.user() then page
      else 'signin'
  'checkSnidd': (page) ->
    if getCurrentUserEmail() is 'm.kjellberg@gmail.com' then page
    else '404'

Meteor.Router.filter(
    'checkLoggedIn'
    { except: 'information'}
)

Meteor.Router.filter(
  'checkSnidd'
  { only: 'cards' }
)

Meteor.Router.add
  '/':'information'
  '/create':  
  	to: 'createdraft'
  	as: 'createdraft'
  '/drafts':'drafts'
  '/cards':'cards'
  '/draft/:id': 
  	to: 'draft'
  	and: (id) -> Session.set('currentDraftId', id)
  '/draft/spreadsheet/:id':
    to: 'spreadsheet'
    and: (id) -> Session.set('currentDraftId', id)

Meteor.methods
  setImportant: (draftId, cardName, important) ->
    fp = FuturePicks.findOne
      userId: Meteor.userId()
      draftId: draftId
    if !fp? then return

    fpid = fp._id
    pickIndex = _.indexOf(_.pluck(fp.picks, 'name'), cardName)
    
    modified = {$set: {}}
    modified.$set["picks." + pickIndex + ".important"] = important
    FuturePicks.update fpid, modified
  removeFuturePick: (cardName, draftId) ->
    fps = FuturePicks.findOne
      userId: Meteor.userId()
      draftId: draftId
    fps.picks = fps.picks.filter (p) ->
      p.name isnt cardName
    FuturePicks.update _id: fps._id, fps
  addMemberToDraft: (draftId, emailAddress) ->
    #do stuff here to add member to draft
    draft = Drafts.findOne
      _id: draftId
    draft.members.push
      email: emailAddress
    Drafts.update _id:draftId, draft
    draft
  removeEmailFromDraft: (draftId, emailAddress) ->
    draft = Drafts.findOne
      _id: draftId
    newMembers = draft.members.filter (member) -> member.email isnt emailAddress
    draft.members = newMembers
    Drafts.update _id:draftId, draft
    draft
  removeDraft: (draftId) ->
    draft = Drafts.findOne
      _id: draftId
    Drafts.remove
      _id:draftId
  pickCard: (cardName, draftId) ->
    draft = Drafts.findOne
      _id: draftId
    if cardAlreadyPicked(draft, cardName) then return false
    userId = Meteor.userId()
    pickPosition = getNextPickPosition(draft.picks.length,draft.members.length)
    
    if draft.members[pickPosition].id isnt userId
      fp = FuturePicks.findOne
        userId: userId
        draftId: draftId
      if !fp?
        fp = new FuturePick(userId, draftId)
        FuturePicks.insert fp
      if stringInArray(fp.picks, cardName) then return false
      newPick = new FutureCard(cardName, "")
      FuturePicks.update { _id: fp._id },
        "$push": { "picks" : newPick }
    else
      newPick = new Pick({name: cardName}, new Member(Meteor.user()), draftId, pickPosition)
      Drafts.update { _id: draftId },
        "$push": { "picks" : newPick }
    draft

#Template.createdraft.helpers
    
#Template.drafts.helpers