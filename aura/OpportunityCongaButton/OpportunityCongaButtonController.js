({
	generateofferlatter : function(component, event, helper) {
        
		var urlEvent = $A.get("e.force:navigateToURL");
        console.log("ID: "+component.get("v.recordId"));
        console.log("ID: "+component.get("v.recordId"));
        console.log("URL: "+component.get("v.targetopptyrecord.Tech_GenerateOfferLetter__c"));
        console.log("URL: "+component.get("v.OpptyRecord.Tech_GenerateOfferLetter__c"));
        urlEvent.setParams({
          //"url": component.get("v.targetFields.Tech_GenerateOfferLetter__c")
          "url": "www.google.com.au"
        });
        urlEvent.fire();
	}
})