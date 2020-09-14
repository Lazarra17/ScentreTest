({
	spaceDetails : function(component, event, helper) {
		var spaceId = event.getParam("spaceId");
        console.log('spaceId', spaceId);
        component.set("v.spaceId", spaceId);
	}
})