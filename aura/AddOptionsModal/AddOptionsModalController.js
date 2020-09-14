({
    insertOptionsRecords : function(component, event,helper) {  
        component.set('v.showSpinner', true);
        var action = component.get("c.insertOptions");
        var eventFields = event.getParam("fields");
        action.setParams({
            description : eventFields.Description,
            pricebookEntryId : component.get('v.pricebookEntryId'),
            product2Id : component.get('v.product2Id'),
            optionTerms: eventFields.OptionsTerm__c,
            opportunityId : component.get("v.oppRecordId")
        });
        action.setCallback(this, function(response) {            
            var state = response.getState();
            console.log(state+" INSIDE RESPONSE");
            if(state === "SUCCESS"){
                //this.showToast(component, 'success', 'Options Created!', '');
                component.find("overlayLib").notifyClose();
            }else {
                //this.showToast(component, 'error', 'Error!', 'Error on creating review');
            }
            component.set('v.showSpinner', false);
        });
        $A.enqueueAction(action);
    },
    showToast : function(component, state, title, message){
        var eventHandler = $A.get("e.c:ToastEvent");
        eventHandler.setParams({
            state : state,
            title : title,
            message : message
        });
        eventHandler.fire();
    }
})