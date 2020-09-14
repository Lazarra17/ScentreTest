({
    getClauseAndOptions : function(component, event, helper) {
        var action = component.get("c.getClauses");
        action.setParams ({oppId : component.get("v.opportunityId")});
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var allValues = response.getReturnValue().clauseType;
                var options = []; 
                if (allValues != undefined && allValues.length > 0) {
                    options.push({
                        label: "--- None ---",
                        value: ""
                    });                }
                for (var i = 0; i < allValues.length; i++) {
                    options.push({
                        label: allValues[i],
                        value: allValues[i]
                    });
                }
                
                component.set("v.availableClause", response.getReturnValue().clauseWrap);
                component.set("v.displayClauses", response.getReturnValue().clauseWrap);
                component.set("v.selectedClause", response.getReturnValue().clauseSelected);
                component.set("v.precedentClauses", response.getReturnValue().precedentClauseSelected);
                component.set("v.typeOptions", options);
            }
        });
        $A.enqueueAction(action); 
    },
    
    searchClause : function(component, event, helper) {
        var searchKey = component.get("v.searchKey");
        var picklistVal = component.get("v.clauseType");
        var searchClauses = [];
        var cacheClauses = component.get("v.availableClause");
        if(searchKey === "" && picklistVal === ""){
            component.set("v.displayClauses", cacheClauses);
        } 
        else if(searchKey === "" && picklistVal !== ""){
            for (var i = 0; i < cacheClauses.length; i++) {
                if(cacheClauses[i].clauseAvailable.Type__c === picklistVal) {
                    searchClauses.push(cacheClauses[i]);
                }
            }
            component.set("v.displayClauses", searchClauses);
        }
            else if(searchKey !== "" && picklistVal === ""){
                for (var i = 0; i < cacheClauses.length; i++) {
                    if(cacheClauses[i].clauseAvailable.Name.toLowerCase().indexOf(searchKey.toLowerCase()) != -1) {
                        searchClauses.push(cacheClauses[i]);
                    }
                }
                component.set("v.displayClauses", searchClauses);
            }
                else {
                    for (var i = 0; i < cacheClauses.length; i++) {
                        if(cacheClauses[i].clauseAvailable.Name.toLowerCase().indexOf(searchKey.toLowerCase()) != -1
                           && cacheClauses[i].clauseAvailable.Type__c === picklistVal) {
                            searchClauses.push(cacheClauses[i]);
                        }
                    }
                    component.set("v.displayClauses", searchClauses);
                }
    },
    trueIsSelected : function(component, event, helper) {
        var clauseId = component.get("v.idToggled");
        var cacheClauses = component.get("v.availableClause");
        var tempClauses = component.get("v.tempSelectedClause");
        for (var i = 0; i < cacheClauses.length; i++) {
            if(cacheClauses[i].clauseAvailable.Id === clauseId) {
                cacheClauses[i].isSelected = true;
                tempClauses.push(cacheClauses[i]);
                cacheClauses.splice(i,1);
                break;
            }
        }
        component.set("v.availableClause", cacheClauses);
        component.set("v.tempSelectedClause", tempClauses);
        helper.searchClause(component, event, helper);
    },
    falseIsSelected : function(component, event, helper) {
        var clauseId = component.get("v.idToggled");
        var cacheClauses = component.get("v.availableClause");
        var tempClauses = component.get("v.tempSelectedClause");
        for (var i = 0; i < tempClauses.length; i++) {
            if(tempClauses[i].clauseAvailable.Id === clauseId) {
                tempClauses[i].isSelected = false;
                cacheClauses.push(tempClauses[i]);
                tempClauses.splice(i,1);
                break;
            }
        }
        component.set("v.availableClause", cacheClauses);
        component.set("v.tempSelectedClause", tempClauses);
        helper.searchClause(component, event, helper);
    },
    onSave : function(component, event, helper) {
        var selectedClauses = component.get("v.tempSelectedClause");
        var alreadySelectedClauses = component.get("v.selectedClause");
        var saveProcess = component.get("c.saveClause");
        var clearClausesTemp = [];
        var clausesId = [];
        for (var i = 0; i < selectedClauses.length; i++) {
                clausesId.push(selectedClauses[i].clauseAvailable.Id);
        }
        if(clausesId.length === 0)
            return; 
        var soqlString = "SELECT Id, Name, Type__c, ActivatedDate__c, RiskApplies__c, ClauseDetails__c FROM ClauseLibrary__c WHERE";
        for (var i = 0; i < clausesId.length; i++) {
            soqlString += " Id = "+"'"+clausesId[i]+"'";
            if(i < clausesId.length-1)
                soqlString += " OR "
                }
        console.log(soqlString);
        saveProcess.setParams ({oppClauseSOQL : soqlString, oppId : component.get("v.opportunityId")});
        saveProcess.setCallback(this, function(response) {
            console.log(response.getState());
            if (response.getState() === "SUCCESS") {
                var result = response.getReturnValue();
                for(var i = 0; i < result.length; i++)
                alreadySelectedClauses.push(result[i]);
                component.set("v.selectedClause",alreadySelectedClauses);
                component.set("v.tempSelectedClause",[]);
                $A.get('e.force:refreshView').fire();
                helper.searchClause(component, event, helper);
            }
        });
        $A.enqueueAction(saveProcess);
    },
    onEdit : function(component, event, helper) {
        var editRecordEvent = $A.get("e.force:editRecord");
        editRecordEvent.setParams({
            "recordId": component.get("v.recordId")
        });
        editRecordEvent.fire();
    }
})