({
	showToast : function(component, state, title, message){
        var toast = component.find("toastMessage");
        
        toast.set("v.title", title);
        toast.set("v.state", state);
        toast.set("v.message", message);
        
        toast.showToast();
    },
    insertRentReviewRecord : function(component, event) {
        var action = component.get("c.insertRentReview");
        var eventFields = event.getParam("fields");
        action.setParams({
            standardReviewType : eventFields.StandardReviewType__c,
            CPIType : eventFields.CPIType__c,
            effectiveFromDate : eventFields.EffectiveFromDate__c,
            effectiveToDate : eventFields.EffectiveToDate__c,
            description : eventFields.Description,
            opportunityId : component.get('v.oppRecordId'),
            pricebookEntryId : component.get('v.pricebookEntryId'),
            product2Id : component.get('v.product2Id'),
            reviewType : eventFields.ReviewType__c,
            amount : eventFields.RentReviewAmount__c,
            cappedpercentage: eventFields.CappedPercent__c
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            var retVal = response.getReturnValue();
            if(state === "SUCCESS" && retVal.status === "SUCCESS"){
                this.showToast(component, 'success', 'Review Created!', '');
                component.find("overlayLib").notifyClose();
            } else {
                if(retVal) {
                    this.showToast(component, 'error', 'Error!', retVal.message);
                }
            }
            component.set('v.showSpinner', false);
        });
        $A.enqueueAction(action);
    }
})