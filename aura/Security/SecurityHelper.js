({
	getAffiliationList : function(component) {
		var action = component.get("c.getAffiliations");
        action.setParams({
            opportunityId : component.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            if(state === "SUCCESS" && getReturn.status === "SUCCESS") {
                var retVal;
                if(getReturn.returnValue){
                    let counter = 0;
                    retVal = JSON.parse(getReturn.returnValue);
                    console.log(retVal);
                    component.set("v.affiliationWrapper", retVal);
                }
            } else {
                if(getReturn.message){
                    console.log(getReturn.message);
                }
            }
        });
        $A.enqueueAction(action);
	},
    saveAffiliationList : function(component, updatedAffList) {
		var action = component.get("c.saveAffiliationList");
        action.setParams({
            opportunityId : component.get('v.recordId'),
            updatedAffListJSON : JSON.stringify(updatedAffList)
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            if(state === "SUCCESS" && getReturn.status === "SUCCESS") {
                var retVal;
                if(getReturn.returnValue){
                    this.getAffiliationList(component);
                }
            } else {
                console.log(getReturn.message);
            }
            $A.get('e.force:refreshView').fire() 
        });
        $A.enqueueAction(action);
	},
    getChanges : function(component, event) {
        let draftValues = event.getParam("draftValues");
        let object = component.get("v.affiliationWrapper");
        for(let x in object) {
            for(let i in draftValues) {
                if(object[x].recordId == draftValues[i].recordId) {
                    if(object[x].isActive != draftValues[i].isActive) {
                        object[x].isActive = draftValues[i].isActive;
                    }
                }
            }
        }
        return object;
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
    
    createRCAOppClauseHelper : function(component, updatedOpp){
        let oppRecordMaster = component.get("v.oppRecord");
        let actionHandler = component.get("c.createRCAOppClause");
        
        console.log("updatedOpp!!", JSON.parse(JSON.stringify(updatedOpp)))
        console.log(updatedOpp.SecurityDepositDays__c === undefined);
        oppRecordMaster.SecurityDepositDays__c =  updatedOpp.SecurityDepositDays__c !== undefined ? updatedOpp.SecurityDepositDays__c.value : '';
        oppRecordMaster.SecurityDepositWeeks__c = updatedOpp.SecurityDepositWeeks__c !== undefined ? updatedOpp.SecurityDepositWeeks__c.value : '';
        oppRecordMaster.SecurityDepositMonths__c = updatedOpp.SecurityDepositMonths__c !== undefined ? updatedOpp.SecurityDepositMonths__c.value : '';


        actionHandler.setParams({
            opp : oppRecordMaster
        })

        actionHandler.setCallback(this, function(response){
            component.set("v.showSpinner", false);
            
            console.log('response : ', response.getState());
            $A.get('e.force:refreshView').fire(); 
        })
        
        $A.enqueueAction(actionHandler);
    },
        showToast : function(component, type, title, message){
        var toast = component.find("toast");
        
        toast.set("v.title", title);
        toast.set("v.state", type);
        toast.set("v.message", message);
        
        toast.showToast();
    }
})