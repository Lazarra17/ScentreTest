({
    onSubmit : function(component, event, helper) {
        var eventFields = event.getParam("fields");
        var isfieldsvalid="true";
        
        if(eventFields.StandardReviewType__c==="" || eventFields.CPIType__c==="" || eventFields.EffectiveFromDate__c===null || eventFields.EffectiveToDate__c===null){
            isfieldsvalid="false";
            component.find('notifLibError').showNotice({
                "variant": "error",
                "header": "Incomplete data entry",
                "message": "Please complete all fields to Save."
            });
        } 
        if(eventFields.StandardReviewType__c==="Non-standard"&&isfieldsvalid==="true"){
            if(eventFields.ReviewType__c===""|| eventFields.RentReviewAmount__c===null){
                isfieldsvalid="false";
                component.find('notifLibError').showNotice({
                    "variant": "error",
                    "header": "Incomplete Review Types entry",
                    "message": "Review Type and Rent Review Amount must be complete for Non-standard Rent Reviews."
                    
                });
            }
        } 
        if(eventFields.EffectiveFromDate__c!==null || eventFields.EffectiveToDate__c!==null&&isfieldsvalid==="true"){
            if(eventFields.EffectiveFromDate__c>eventFields.EffectiveToDate__c){
                isfieldsvalid="false";
                component.find('notifLibError').showNotice({
                    "variant": "error",
                    "header": "Invalid Dates",
                    "message": "Effective From Date must come before Effective To Date for all Rent Reviews."
                    
                });
            }
        }
        console.log(" ISVALID "+isfieldsvalid);
        if(isfieldsvalid==="true"){
            component.set('v.showSpinner', true);
            helper.insertRentReviewRecord(component, event);
        }
    },
    standardReviewChange : function(component, event, helper) {
        if(event.getParam("value") == 'Non-standard'){
            component.set('v.showReviewType', true);
        } else {
            component.set('v.showReviewType', false);
        }
    }
})