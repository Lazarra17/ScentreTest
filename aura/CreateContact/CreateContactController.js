({
    doInit : function(component, event, helper) {
        component.find("accountRecordCreator").getNewRecord(
            "Account", // sObject type (objectApiName)
            null,      // recordTypeId
            false,     // skip cache?
            $A.getCallback(function() {
                var rec = component.get("v.newAccount");
                var error = component.get("v.newAccountError");
                if(error || (rec === null)) {
                    console.log("Error initializing record template: " + error);
                    return;
                }
                console.log("Record template initialized: " + rec.sobjectType);
            })
        );
    },
    handleSuccess : function(component, event, helper) {
        var payload = event.getParams().response;
        console.log('--->' , JSON.parse(JSON.stringify(payload)));
        component.set("v.contactId", payload.id);
        component.set("v.accountId", component.get("v.simpleNewAccount.Id"));
        var navigate = component.get('v.navigateFlow');
        navigate("NEXT");
    },
    handleOnSubmit : function(component, event, helper) {
        event.preventDefault();
        var fields = event.getParam("fields");
        component.set("v.simpleNewAccount.Name", fields.FirstName + ' ' + fields.LastName);
        component.set("v.simpleNewAccount.ShippingCity", fields.MailingCity);
        component.set("v.simpleNewAccount.ShippingCountry", fields.MailingCountry);
        component.set("v.simpleNewAccount.ShippingPostalCode", fields.MailingPostalCode);
        component.set("v.simpleNewAccount.ShippingStateCode", fields.MailingStateCode);
        component.set("v.simpleNewAccount.ShippingStreet", fields.MailingStreet);
        component.set("v.simpleNewAccount.Type", 'Guarantor');
        component.set("v.simpleNewAccount.Phone", fields.Phone);
        component.set("v.simpleNewAccount.TradingName__c", fields.FirstName + ' ' + fields.LastName);
        component.set("v.simpleNewAccount.RecordTypeId", component.get("v.accountRecTypeId"));
        component.set("v.simpleNewAccount.Tech_isDummyRecord__c", true);
        console.log('-->' + component.get("v.simpleNewAccount.Tech_isDummyRecord__c"));
        if(fields.Phone != null || fields.MobilePhone != null || fields.Email != null) {
            component.find("accountRecordCreator").saveRecord(function(saveResult) {
                if (saveResult.state === "SUCCESS") {
                    // record is saved successfully
                    console.log('hey' + component.get("v.simpleNewAccount.Id"));
                    fields["AccountId"] = component.get("v.simpleNewAccount.Id");
                    fields["Title"] = 'Guarantor';
                    component.find("ContactRecordEditForm").submit(fields);
                } else if (saveResult.state === "INCOMPLETE") {
                    // handle the incomplete state
                    console.log("User is offline, device doesn't support drafts.");
                } else if (saveResult.state === "ERROR") {
                    // handle the error state
                    console.log('Problem saving contact, error: ' + JSON.stringify(saveResult.error));
                } else {
                    console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
                }
            });
        } else {
            component.find("ContactRecordEditForm").submit(fields);
        }
    },
    //RPP-9740 START
    toggleNew : function (component, event, helper){
        var toggle = component.get("v.showNew");
        if(toggle){
            component.set("v.showNew", false);
            event.getSource().set("v.label","Create New");
        }else{
            component.set("v.showNew", true);
            event.getSource().set("v.label","Search Existing");
        }   
    },
    
    contactSelected : function (component, event, helper){
        debugger;
        var slectedContact = component.get("v.guarantorContact");
        console.log(slectedContact);
        if(slectedContact != null){
            if(slectedContact.val == ''){
                component.set("v.showNew", true);
                component.find('toggle').set("v.label","Search Existing");
            }else{
                component.set("v.contactId", slectedContact.val);
            }
        }
    },
    
    continue : function (component, event, helper){
    	
    	if(component.get("v.contactId")){
    		component.set("v.showSpinner", true);
    
    		var action = component.get("c.searchContact");
        	
    		action.setParams({
            	conId : component.get("v.contactId")
        	});
            
        	action.setCallback(this, function(a){
                component.set("v.showSpinner", false);
                if(a.getState() === 'SUCCESS'){
                    if(a.getReturnValue() != null){
                        component.set("v.accountId", a.getReturnValue().AccountId);
                    }
                    var navigate = component.get('v.navigateFlow');
					navigate("NEXT");
                }
        	});
			$A.enqueueAction(action);
		}else{
 			alert('Please select Contact');
 		}
	}
    //RPP-9740 END
})