Template.information.helpers
  latestDraft: ->
  	searchObject = '$or': [ { owner: Meteor.userId() }, {public: true} ]
			sortObject = 'sort': created:-1
			Drafts.findOne searchObject,sortObject

Template.index.helpers
  breadcrumbs: ->
    if Meteor.Router.page() is 'information' then return undefined
    curPage = Meteor.Router.page()
    ret = []

    ret.push
      name: 'Home'
      active: false
      link: Meteor.Router.informationPath()
          
    if curPage is 'draft' or 'spreadsheet'
    then ret.push 
      name: 'Drafts'
      active:false
      link: Meteor.Router.draftsPath()
    ret.push
      name: pageRouterNameTranslation curPage
      active: true
    return ret

Template.draft.helpers
	started: -> getCurrentDraft().started is true

#Drafts.find({ "$or" : [{owner: "RQsrRsjmgmdKp8vN2"}, { public: true, started:true}, { "members.email" : "m.kjellberg@gmail.com", started:true }] }).fetch();
Template.drafts.helpers
	mydrafts: ->
		findObject = '$or': [ 
			{ owner: Meteor.userId() }, 
			{ public: true, started: true}, 
			{ "members.email": getCurrentUserEmail(), started: true } ]
		Drafts.find(findObject)
	statusclass: (draft) ->
		if draft.finished
			return "finished"
		if draft.started
			return "started"
		"waiting"
	deletable: (draft) ->
		if draft.owner isnt Meteor.userId() then return false
		if not draft.started then return true
		if draft.finished then return true
		return false


Template.startDraft.helpers
	draftMembers: -> getCurrentDraft().members
	startable: ->
		if getCurrentDraft().members.length > 1
			return ""
		else
			return "disabled"

## EVENTS ##

Template.drafts.events
	'click .viewdraft' : ->
		Meteor.Router.to 'draft', this._id
	'click .deletedraft' : ->
		console.log "removing draft #{this._id}"
		Meteor.call "removeDraft", this._id

Template.startDraft.events
	'click .inviteEmail' : ->
		inviteEmail()
	'submit #invitePeopleForm' : ->
		inviteEmail()
	'click .startdraft' : ->
		Meteor.call "startDraft", Session.get('currentDraftId')
	'click .label.email' : (event) ->
		console.log "Removing: #{this.email}"
		Meteor.call "removeEmailFromDraft", Session.get('currentDraftId'), this.email, (error, result) ->
			switch error?.error
				when 501
					console.log "You cannot remove yourself!"
					$('#draftMembers').append(alertDiv "Yourself!", "You cannot remove yourself from the draft!")

inviteEmail = ->
		emailInput = document.getElementById('addEmailInput')
		emailAddress = emailInput.value
		if not emailAddress?.length then return false
		Meteor.call "addMemberToDraft", Session.get('currentDraftId'), emailAddress, (error, result) ->
			switch error?.error
				when 404 
					console.log "Email not found!"
					$('#draftMembers').append(alertDiv "Not found", "The email you entered could not be found in the system.")
				when 405
					console.log "Email already added"
					$('#draftMembers').append(alertDiv "Already exists", "The email you entered already exists in the draft.")
			true
		emailInput.value = ''
		emailInput.focus()
		return false

Template.index.events
	'click .createdraft' : (event) ->
		Meteor.Router.to 'drafts'

Template.createdraft.events
	'click .btn.create' : (event) ->
		draftname = document.getElementById('draftname').value
		formattype = document.getElementById('formattype').value
		ispublic = document.getElementById('ispublic').value
		console.log "creating draft with name #{draftname}"
		newDraft =
			name: draftname
			format: formattype.toLowerCase
			public: ispublic is "on"
			owner: Meteor.userId()
			created: new Date()
			started: false
			finished: false
			members: [
				id: Meteor.userId()
				email: Meteor.user().emails[0].address
			]
		draftId = Drafts.insert newDraft
		Meteor.Router.to 'draft', draftId
		return false