# coffee
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

#Template.createdraft.helpers
    
#Template.drafts.helpers