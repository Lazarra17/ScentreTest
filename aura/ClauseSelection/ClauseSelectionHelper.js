({
    getClauseAndOptions : function(component, event, helper) {
    	var self = this; 
        var action = component.get("c.getClauses");
        action.setParams ({oppId : component.get("v.recordId")});
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
                
                self.searchClause(component, event, helper);
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
        
        component.set("v.isSaveDisabled", false);
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
        
        if($A.util.isEmpty(tempClauses)){
            component.set("v.isSaveDisabled", true);
        }
        
        helper.searchClause(component, event, helper);
    }, 
    checkIfEnableClauseEditUpdate : function(component, event, helper){
        var isLocked = component.get("c.enableClauseEditUpdate");
        isLocked.setParams({
            oppId : component.get("v.recordId")
        });
        isLocked.setCallback(this, function(response) {
            var state = response.getState();
            var isEnabled = response.getReturnValue();
            
            if(state === "SUCCESS"){
                component.set("v.isOppLocked", isEnabled);
            } else {
                console.log('Show error here');
            }
            
        });
        $A.enqueueAction(isLocked);
    },
    onSave : function(component, event, helper) {
        var self = this;
        var selectedClauses = component.get("v.tempSelectedClause");
        var selectedClauseTemp = [];
        var alreadySelectedClauses = component.get("v.selectedClause");
        var saveProcess = component.get("c.saveClause");
        var clearClausesTemp = [];
        var clausesId = [];
        
        for (var i = 0; i < selectedClauses.length; i++) {
            //clausesId.push(selectedClauses[i].clauseAvailable.Id);
            selectedClauseTemp.push(selectedClauses[i].clauseAvailable);
        }
        
        /*if(clausesId.length === 0)
            return; 
        
        var soqlString = "SELECT Id, Name, Type__c, ActivatedDate__c, RiskApplies__c, ClauseDetails__c FROM ClauseLibrary__c WHERE";
        
        for (var i = 0; i < clausesId.length; i++) {
            soqlString += " Id = "+"'"+clausesId[i]+"'";
            if(i < clausesId.length-1){
                soqlString += " OR "   
            }
        }
        
        console.log(soqlString);*/
        console.log("selectedClauseTemp : ", selectedClauseTemp)
        saveProcess.setParams ({
            oppClauseJSON : JSON.stringify(selectedClauseTemp),
            oppId : component.get("v.recordId")
       	});
        
        saveProcess.setCallback(this, function(response) {
            console.log(response.getState());
            var res = response.getReturnValue();
            if (res.status === "SUCCESS") {
                var oppClauseList = JSON.parse(res.returnValue);
                
                for(var i = 0; i < oppClauseList.length; i++){
                 	alreadySelectedClauses.push(oppClauseList[i]);   
                }
                
                component.set("v.selectedClause",alreadySelectedClauses);
                component.set("v.tempSelectedClause",[]);
                component.set("v.isSaveDisabled", true);
                
                $A.get('e.force:refreshView').fire();
                
                helper.searchClause(component, event, helper);
            } else {
                console.log("res.message : ", res.message);
                res.message = self.errorHandler(res.message);
                self.toggleToast(component, "error", "Error!", res.message);
            }
        });
        $A.enqueueAction(saveProcess); 
        
        
    },
    onEdit : function(component, event, helper) {
        var modalBody;
        var self = this;
        $A.createComponent("c:EditRecordModal", {
            "recordId" : component.get("v.oppClauseId")
        },
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: "Edit Opportunity Clause",
                                       body: modalBody, 
                                       showCloseButton: true,
                                       closeCallback: function() {
                                           self.getClauseAndOptions(component, event, helper);
                                       }
                                   })
                               }                               
                           });
    },
    onDelete : function(component, event, helper) {
        var oppClauseId = component.get("v.oppClauseId");
        var clauseId;
        var alreadySelectedClauses = component.get("v.selectedClause");
        var availableClauses = component.get("v.availableClause");
        var action = component.get("c.deleteClause");
        for(var i  = 0; i < alreadySelectedClauses.length; i++){
            if(alreadySelectedClauses[i].Id === oppClauseId){
                clauseId = alreadySelectedClauses[i].ReferencedClause__c;
                alreadySelectedClauses.splice(i,1);
                break;
            }
        }
        action.setParams ({oppClause : oppClauseId, clauseIds : clauseId});
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                this.clearvalues(component);
                component.set("v.availableClause", response.getReturnValue().clauseWrap);
                component.set("v.displayClauses", response.getReturnValue().clauseWrap);
                component.set("v.selectedClause", response.getReturnValue().clauseSelected);
                component.set("v.precedentClauses", response.getReturnValue().precedentClauseSelected);
            }else if(response.getState() === "ERROR"){
                component.set("v.oppClauseId",oppClauseId);
                component.find('notifLib').showNotice({
                    "variant": "error",
                    "header": "No Usage Clause",
                    "message": "There should be atleast one Usage Clause on Opportunity."
                    
                });
            }
        });
        $A.enqueueAction(action); 
    },
    getUpdates : function(component, event, helper) {
        var alreadySelectedClauses = component.get("v.selectedClause");
        var oppClauseId = component.get("v.oppClauseId");
        var action = component.get("c.getUpdatedClause");
        action.setParams ({oppClause : oppClauseId});
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                for(var i  = 0; i < alreadySelectedClauses.length; i++){
                    if(alreadySelectedClauses[i].Id === oppClauseId){
                        alreadySelectedClauses.splice(i,1);
                        break;
                    }
                }
                var oppClause = response.getReturnValue();
                console.log(oppClause.Name);
                alreadySelectedClauses.push(oppClause);
                component.set("v.selectedClause", alreadySelectedClauses);
            }
        });
        $A.enqueueAction(action); 
    },
    clearvalues : function (component){
        component.set("v.availableClause", "");
        component.set("v.displayClauses", "");
        component.set("v.selectedClause", "");
        component.set("v.precedentClauses", "");
    },
    
    errorHandler : function(message) {
        var idxStack = message.indexOf("STACK TRACE:");
        var msg = idxStack != -1 ? message.substring(0, idxStack-1) : message;
        var idx = msg.indexOf("first error:");
        var errMsg = idx != -1 ? msg.substring(idx + 13, msg.length) : 'Something went wrong. Please contact your System Administrator.';
        
        while(errMsg.includes('&quot;')){
            errMsg = errMsg.replace('&quot;', '');
        }
        
        if(errMsg.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
            errMsg = errMsg.replace('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', '');
            var messages = errMsg.split(':');
            var valMsg = '';
            for(var i=0; i< messages.length - 1; i++){
                valMsg = valMsg + messages[i];
            }
            errMsg = valMsg;
        }
        
        return errMsg;
    },
    
    toggleToast : function(component, state, title, message){
        var eventHandler = $A.get("e.c:ToastEvent")
        
        eventHandler.setParams({
            state : state,
            title : title,
            message : message
        })
        
        eventHandler.fire()
    },
})