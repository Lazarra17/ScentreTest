({
	spaceDetails : function(component, event, helper) {
		var spaceId = event.getParam("spaceId");
        console.log('spaceId', spaceId);
        component.set("v.spaceId", spaceId);
	},
    doInit : function(component, event, helper) {
        component.set('v.columns', [
            { label: 'Shop NO.', fieldName: 'spaceLink', type: 'url', typeAttributes: { label: { fieldName: 'Name' } }},
            { label: 'Current Retailer', fieldName: 'accountLink', type: 'url', typeAttributes: { label: { fieldName: 'accountName' } }},
			{ label: 'Current Rent', fieldName: 'CurrentRent__c', type: 'currency', cellAttributes: { alignment: 'left'}},
            { label: 'Rentable Area', fieldName: 'rentableArea', type: 'text'},
            { label: 'Usable Area', fieldName: 'usableArea', type: 'text'},
            { label: 'Propidex Link', fieldName: 'propidexLink', type: 'url', typeAttributes: { label: { fieldName: 'propidexLinkName' } }},
            { label: 'Risk', fieldName: 'CurrentLeaseRiskApplied__c', type: 'boolean', cellAttributes: { alignment: 'right'}},
            { label: 'Find', type: 'button', initialWidth: 135, typeAttributes: { label: 'Find Me', name: 'view_details', title: 'Click to Highlight In the Map'}}
        ]);
        //component.set("v.level", "1"); //Default
        var action = component.get("c.getSpacesAndImageByProperty");
        if (action != null) {
        	action.setParams({
                "propertyId": component.get("v.recordId"),
                "level": "initial"
            });
            // Add callback behavior for when response is received
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var conts = JSON.parse(response.getReturnValue());
                    var spaces = conts.spaces;
                    var imageUrl = conts.imageUrl;
                    var level = conts.level;
                    var propertyMaps = conts.propertyMaps;
                    spaces.forEach(element => {
                        element.rentableArea = element.RentableArea__c + '';
                        element.usableArea = element.UsableArea__c + '';
                        if (element.Property__r != null) {
                        	element.propidexLink = "http://aupdc00-pdx01p/PROPIDEX/PROPIDEX.APPLICATION?P:" + element.Property__r.JDEPropertyNumber__c + "&U:" + element.Name;
                        } else {
                        	element.propidexLink = "http://aupdc00-pdx01p/PROPIDEX/PROPIDEX.APPLICATION?P:" + element.Property__r.JDEPropertyNumber__c;    
                        }
                        element.spaceLink = "/one/one.app#/sObject/" + element.Id;
                        if (!$A.util.isUndefinedOrNull(element.Name)) {
                        	element.propidexLinkName = element.Name + ' Propidex Link';
                    	} else {
                        	element.propidexLinkName = 'Propidex Link';
                    	}
                        if (!$A.util.isUndefinedOrNull(element.CurrentRetailer__r)) {
                            element.accountName = element.CurrentRetailer__r.Name;
                        	element.accountLink = "/one/one.app#/sObject/" + element.CurrentRetailer__c;
                        } else {
                            element.accountName = "";
                        	element.accountLink = "";
                        }
                    });
                    console.log('spaces', spaces);
                    component.set("v.spaceData", spaces);
                    console.log("v.imageLocation", imageUrl);
                    component.set("v.imageLocation", imageUrl);
                    component.set("v.levelButtons", propertyMaps);
                    component.set("v.level", level);
                }
                else {
                    var toastEventFailed = $A.get("e.force:showToast");
                    console.log('errorMessage', response.getError());
                    toastEventFailed.setParams({
                        "title": "Failed!",
                        "message": "Fail to achieve space details"
                    });
                    toastEventFailed.fire();
                }
            });
            // Send action off to be executed
            $A.enqueueAction(action);    
        }
    },
    handleClick : function(component, event, helper) {
        var idx = event.target.id;
        component.set("v.level", idx);
        var action = component.get("c.getSpacesAndImageByProperty");
        if (action != null) {
        	action.setParams({
                "propertyId": component.get("v.recordId"),
                "level": idx
            });
            // Add callback behavior for when response is received
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var conts = JSON.parse(response.getReturnValue());
                    var spaces = conts.spaces;
                    var imageUrl = conts.imageUrl;
                    var propertyMaps = conts.propertyMaps;
                    spaces.forEach(element => {
                        element.rentableArea = element.RentableArea__c + '';
                        element.usableArea = element.UsableArea__c + '';
                        if (element.Property__r != null) {
                        	element.propidexLink = "http://aupdc00-pdx01p/PROPIDEX/PROPIDEX.APPLICATION?P:" + element.Property__r.JDEPropertyNumber__c + "&U:" + element.Name;
                        } else {
                        	element.propidexLink = "http://aupdc00-pdx01p/PROPIDEX/PROPIDEX.APPLICATION?P:" + element.Property__r.JDEPropertyNumber__c;    
                        }
                        element.spaceLink = "/one/one.app#/sObject/" + element.Id;
                        if (!$A.util.isUndefinedOrNull(element.Name)) {
                        	element.propidexLinkName = element.Name + ' Propidex Link';
                    	} else {
                        	element.propidexLinkName = 'Propidex Link';
                    	}
                        if (!$A.util.isUndefinedOrNull(element.CurrentRetailer__r)) {
                            element.accountName = element.CurrentRetailer__r.Name;
                        	element.accountLink = "/one/one.app#/sObject/" + element.CurrentRetailer__c;
                        } else {
                            element.accountName = "";
                        	element.accountLink = "";
                        }
                    });
                    component.set("v.spaceData", spaces);
                    component.set("v.imageLocation", imageUrl);
                    component.set("v.levelButtons", propertyMaps);
                }
                else {
                    var toastEventFailed = $A.get("e.force:showToast");
                    console.log('errorMessage', response.getError());
                    toastEventFailed.setParams({
                        "title": "Failed!",
                        "message": "Fail to achieve space details"
                    });
                    toastEventFailed.fire();
                }
            });
            // Send action off to be executed
            $A.enqueueAction(action);   
        }
    },
    handleRowAction : function(component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'view_details':
                helper.sendToVF(row, component);
                break;
            default:
                helper.sendToVF(row, component);
                break;
        }
    }
})