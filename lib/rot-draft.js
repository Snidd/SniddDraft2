// shared stuff

Drafts = new Meteor.Collection("drafts");
Cards = new Meteor.Collection("cards");
FuturePicks = new Meteor.Collection("futurepicks");

if (Meteor.isClient) {
	Meteor.subscribe("futurepicks");
	Meteor.subscribe("drafts");
}
