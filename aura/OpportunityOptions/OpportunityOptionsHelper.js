({
    getOpportunityLineItems : function(component) {
        var action = component.get("c.getOpportunityLineItem");
        action.setParams({
            opportunityId : component.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            if(state === "SUCCESS" && getReturn.status === "SUCCESS") {
                var retVal;
                if(getReturn.returnValue){
                    retVal = JSON.parse(getReturn.returnValue);
                    component.set("v.optionPBentryRecordId", retVal.optionpriceBookentryRecordList[0].Id);
                    component.set("v.optionProductRecordId", retVal.optionpriceBookentryRecordList[0].Product2Id);
                    component.set("v.oppLineItemList", retVal.optionslineItemList);
                    
                }
            } else {
                console.log(getReturn.message);
            }
        });
        $A.enqueueAction(action);
    },
    verifyUserAccess : function(component) {
        var action = component.get("c.userHasEditAccess");
        action.setParams({
            opportunityId : component.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            if(state === "SUCCESS" && getReturn.status === "SUCCESS") {
                var retVal;
                if(getReturn.returnValue){
                    retVal = JSON.parse(getReturn.returnValue);
                    if(retVal) {
                        component.set("v.isReadOnly", retVal);
                    }
                }
            } else {
                console.log(getReturn.message);
            }
        });
        $A.enqueueAction(action);
    },
    
    showToast : function(component, type, title, message) {
    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
        "type": type,
        "title": title,
        "message": message
    });
    toastEvent.fire();
	},
    
    
    removeOpportunity: function (component, row) {
        component.set('v.showSpinner', true);
		var action = component.get("c.removeOpportunity");
        action.setParams({
            opportunityProductId : row.Id
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            if(state === "SUCCESS") {     
                this.showToast(component, 'success', 'SUCCESS!', 'Option successfully deleted');
                this.getOpportunityLineItems(component);
            } else {
                this.showToast(component, 'error', 'OOPS!', 'Option delete failed');
                console.log("ERROR");
            }
			component.set('v.showSpinner', false);
        });
        $A.enqueueAction(action);
    }
})