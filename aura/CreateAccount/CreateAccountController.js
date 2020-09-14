({
    handleSuccess : function(component, event, helper) {
        var payload = event.getParams().response;
        console.log('--->' , JSON.parse(JSON.stringify(payload)));
        component.set("v.simpleNewContact.LastName", payload.fields.Name.value);
        component.set("v.simpleNewContact.AccountId", payload.id);
        component.set("v.simpleNewContact.MailingCity", payload.fields.ShippingCity.value);
        component.set("v.simpleNewContact.MailingCountryCode", payload.fields.ShippingCountryCode.value);
        component.set("v.simpleNewContact.MailingPostalCode", payload.fields.ShippingPostalCode.value);
        component.set("v.simpleNewContact.MailingStateCode", payload.fields.ShippingStateCode.value);
        component.set("v.simpleNewContact.MailingStreet", payload.fields.ShippingStreet.value);
        component.set("v.simpleNewContact.Phone", '123456789');
        component.set("v.simpleNewContact.Status__c", 'Active');
        component.set("v.simpleNewContact.Title", 'Guarantor');
        component.find("contactRecordCreator").saveRecord(function(saveResult) {
                if (saveResult.state === "SUCCESS") {
                    // record is saved successfully
                    component.set("v.contactId", component.get("v.simpleNewContact.Id"));
                    component.set("v.accountRecordId", payload.id);	
                    var navigate = component.get('v.navigateFlow');
                    navigate("NEXT");
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
    }, 
    handleOnLoad : function(component, event, helper) {
        component.find("contactRecordCreator").getNewRecord(
            "Contact", // sObject type (objectApiName)
            null,      // recordTypeId
            false,     // skip cache?
            $A.getCallback(function() {
                var rec = component.get("v.newContact");
                var error = component.get("v.newContactError");
                if(error || (rec === null)) {
                    console.log("Error initializing record template: " + error);
                    return;
                }
                console.log("Record template initialized: " + rec.sobjectType);
            })
        );
        component.find("typeField").set("v.value", 'Guarantor');
    },
    handleOnSubmit : function(component, event, helper) {
        event.preventDefault();
        var fields = event.getParam("fields");
        fields["RecordTypeId"] = component.get("v.accountRecTypeId");
        fields["TradingName__c"] = fields.Name;
        component.find("recordEditForm").submit(fields);
    },
    handleError : function(component, event, helper) {
        window.scroll(0,0);
    },
    
    //RPP-9740 START
    toggleNew : function (component, event, helper){
        var toggle = component.get("v.showNew");
        //var label = event.getSource().get("v.label");
        //var btn = component.find("toggle");
        if(toggle){
            component.set("v.showNew", false);
            event.getSource().set("v.label","Create New");
        }else{
            component.set("v.showNew", true);
            event.getSource().set("v.label","Search Existing");
        }   
    },
    
    accountSelected : function (component, event, helper){
        debugger;
        var slectedAccount = component.get("v.guarantorAccount");
        console.log(slectedAccount);
        if(slectedAccount != null){
            if(slectedAccount.val == ''){
                component.set("v.showNew", true);
                component.find('toggle').set("v.label","Search Existing");
            }else{
                component.set("v.accountRecordId", slectedAccount.val);
            }
        }
    },
    
    continue : function (component, event, helper){
    	
    	if(component.get("v.accountRecordId")){
    		component.set("v.showSpinner", true);
    
    		var action = component.get("c.searchContact");
        	
    		action.setParams({
            	accId : component.get("v.accountRecordId")
        	});
            
        	action.setCallback(this, function(a){
                console.log()
                component.set("v.showSpinner", false);
                if(a.getState() === 'SUCCESS'){
                    if(a.getReturnValue() != null){
                        component.set("v.contactId", a.getReturnValue().Id);
                    }
                    var navigate = component.get('v.navigateFlow');
					navigate("NEXT");
                }
        	});
			$A.enqueueAction(action);
		}else{
 			alert('Please select Account');
 		}
	}
    //RPP-9740 END
})