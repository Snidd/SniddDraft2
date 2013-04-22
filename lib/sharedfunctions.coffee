@getCurrentUserEmail = ->
	user = Meteor.user()
	if user isnt undefined
		for email in user.emails
			return email.address
	return ""

@getCurrentDraft = ->
	draftId = Session.get("currentDraftId")
	Drafts.findOne
		_id : draftId

@getNextPickPosition = (nrOfPicks, draftSize) ->
  finishedRounds = nrOfPicks / (draftSize * 2)
  posInRound = nrOfPicks % (draftSize * 2)
  #return them with -1 since our array is 0 based index
  if posInRound < draftSize
    return parseInt(((finishedRounds + posInRound) % draftSize) + 1)-1
  else
    return parseInt((finishedRounds + (draftSize * 2 - 1 - posInRound)) % draftSize + 1)-1