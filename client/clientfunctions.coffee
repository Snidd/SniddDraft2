@pageRouterNameTranslation = (pageName) ->
	switch pageName
		when 'createdraft' then 'Create Draft'
		when 'signin' then 'Sign In'
		when 'drafts' then 'Drafts'
		when 'draft'
		 	curDraft = getCurrentDraft()
		 	curDraft.name

@alertDiv = (header, message) ->
	"<div class='alert'><button type='button' class='close' data-dismiss='alert'>&times;</button><strong>#{header}</strong> #{message}</div>"

@getCurrentDraft = ->
  Drafts.findOne
  	_id:Session.get 'currentDraftId'