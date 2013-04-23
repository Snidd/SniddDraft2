# coffee
Meteor.subscribe "futurepicks"
Meteor.subscribe "drafts"

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

Meteor.methods
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
      fp.picks.push new FutureCard(cardName, "")
      FuturePicks.update _id:fp._id, fp
    else
      pick = new Pick({name: cardName}, new Member(Meteor.user()), draftId)
      draft.picks.push(pick);
      Drafts.update _id:draftId, draft
    draft

#Template.createdraft.helpers
    
#Template.drafts.helpers