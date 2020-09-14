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
                    console.log(retVal);
                    component.set("v.promoRevItemList", retVal.promoReviewList);
                    component.set("v.oppLineItemList", retVal.rentReviewList);
                    component.set("v.rentRevPbEntry", retVal.rentRevPbEntry);
                    component.set("v.promoRevPbEntry", retVal.promoRevPbEntry);
                    component.set("v.rentReviewProdId", retVal.rentReviewProdId);
                    component.set("v.promoRevProdId", retVal.promoRevProdId);
                }
            } else {
                console.log(getReturn.message);
            }
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
    },
    deleteLineItem : function(component, row) {
        var action = component.get("c.deleteLineItem");
        
        action.setParams({
            oppLineItemId : row.Id
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            if(state === "SUCCESS"){
                this.showToast(component, 'success', 'Rent Review Deleted!', '');
                this.getOpportunityLineItems(component);
            } else {
                this.showToast(component, 'error', 'Error!', 'Error');
                console.log("ERROR");
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
    
    //RPP - 9653  6-May-2020
    getOppLineItemsRentReviewUpdate : function(component){
        component.set("v.showSpinner", true);
        var action = component.get("c.getOppLineItemForUpdate");
        
        action.setParams({
            opportunityId : component.get('v.recordId'),
            oppLineItemIds : component.get("v.oppLineItemRentRows"),
            cpiType : component.get('v.rentCPIType'),
            stdRevType : component.get('v.rentStdRevType')
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            component.set("v.showSpinner", false);
            if (state === "SUCCESS") {
                $A.get('e.force:refreshView').fire();
                this.getOpportunityLineItems(component);
                this.showToast(component, 'success', 'Rent Reviews Updated!', '');
                component.set('v.rentCPIType','--None--');
                component.set('v.rentStdRevType','--None--');
            }else{
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.showToast(component, 'error', 'Error!', errors[0].message);
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } 
                else {
                    console.log("Unknown Error");
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    //RPP - 9653  6-May-2020
    getOppLineItemsPromoReviewUpdate : function(component){
        component.set("v.showSpinner", true);
        var action = component.get("c.getOppLineItemForUpdate");
        
        action.setParams({
            opportunityId : component.get('v.recordId'),
            oppLineItemIds : component.get("v.oppLineItemPromoRows"),
            cpiType : component.get('v.promoCPIType'),
            stdRevType : component.get('v.promoStdRevType')
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            component.set("v.showSpinner", false);
            if (state === "SUCCESS") {
                $A.get('e.force:refreshView').fire();
                this.getOpportunityLineItems(component);
                this.showToast(component, 'success', 'Promo Reviews Updated!', '');
                component.set('v.promoCPIType','--None--');
                component.set('v.promoStdRevType','--None--');
            }else{
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.showToast(component, 'error', 'Error!', errors[0].message);
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } 
                else {
                    console.log("Unknown Error");
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    //RPP - 9653  6-May-2020
    getCPItypeValues : function(component){
        var action = component.get("c.getCPITypeValues");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var CPITypes = response.getReturnValue();
                component.set("v.CPITypeValues", CPITypes);
            }
        });
        $A.enqueueAction(action);
    },
    
    //RPP - 9653  6-May-2020
    getStdReviewTypeValues : function(component){
        var action = component.get("c.getStdReviewTypeValues");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var stdRevTypes = response.getReturnValue();
                component.set("v.stdRevTypeValues", stdRevTypes);
            }
        });
        $A.enqueueAction(action);
        
    }
})