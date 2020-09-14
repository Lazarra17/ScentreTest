({
    getOpportunityClauseWrapper : function(component) {
        var action = component.get("c.buildOpportunityClauseWrapper");
        action.setParams({
            "opportunityId" : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            if(state === "SUCCESS" && getReturn.status === "SUCCESS") {
                var retVal = JSON.parse(getReturn.returnValue);
                component.set("v.clauseList", retVal.availableClauseList);
                component.set("v.opportunityClauseList", retVal.opportunityClauseList);
                this.helperSearch(component);
            } else {
                console.log(getReturn.message);
            }
        });
        $A.enqueueAction(action);
    },
    verifyUser : function(component) {
        var action = component.get("c.verifyOpportunity");
        action.setParams({
            "opportunityId" : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            if(state === "SUCCESS") {
                component.set("v.isOppLocked", getReturn);
            } else {
                console.log(getReturn.message);
            }
        });
        $A.enqueueAction(action);
    },
    getClauseTypePicklistValues : function(component) {
        var action = component.get("c.getClauseTypePicklistValues");
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            if(state === "SUCCESS" && getReturn.status === "SUCCESS") {
                var retVal = JSON.parse(getReturn.returnValue);
                component.set("v.clauseTypePicklistValues", retVal);
            } else {
                console.log(getReturn.message);
            }
        });
        $A.enqueueAction(action);
    },
    getDocLocPicklistValues : function(component) {
        var action = component.get("c.getDocLocPicklistValues");
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            if(state === "SUCCESS" && getReturn.status === "SUCCESS") {
                var retVal = JSON.parse(getReturn.returnValue);
                component.set("v.docLocPicklistValues", retVal);
            } else {
                console.log(getReturn.message);
            }
        });
        $A.enqueueAction(action);
    },
    getApplicableStatePicklistValues : function(component){
        var action = component.get("c.getApplicationStatePicklistValues");
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            if(state === "SUCCESS" && getReturn.status === "SUCCESS") {
                var retVal = JSON.parse(getReturn.returnValue);
                component.set("v.applicableStatePicklistValues", retVal);
            } else {
                console.log(getReturn.message);
            }
        });
        $A.enqueueAction(action);
    },
    saveSelectedClauseList : function(component) {
        var selectedClauseList = component.get("v.selectedClauseList");
        var action = component.get("c.createOpportunityClause");
        action.setParams({
            "clauseLibraryStringList" : JSON.stringify(selectedClauseList),
            "opportunityId" : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            if(state == "SUCCESS" && getReturn.status == "SUCCESS") {
                this.refreshClauseList(component);
            } else {
                console.log(getReturn.message);
            }
            component.set("v.showSpinner", false);
        });
        $A.enqueueAction(action);
    },
    deleteOpportunityClause : function(component, event) {
        var action = component.get("c.deleteOpportunityClause");
        var opportunityClauseList = component.get("v.opportunityClauseList");
        action.setParams({
            "opportunityClauseId" :  event.getSource().get("v.name")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            if(state == "SUCCESS" && getReturn.status == "SUCCESS") {
                this.refreshClauseList(component);
            } else {
                console.log(getReturn.message);
            }
            component.set("v.showSpinner", false);
        });
        $A.enqueueAction(action);
    },
    refreshClauseList : function(component) {
        component.set("v.showSpinner", true);
        component.set("v.clauseList", []);
        component.set("v.displayClauseList", []);
        component.set("v.selectedClauseList", []);
        component.set("v.opportunityClauseList", []);
        this.getOpportunityClauseWrapper(component);
    },
    onStateChange : function(component){
        var selectedState = component.get("v.selectedApplicableState");
        var newDisplayClauseList = [];
        var displayClauseList = component.get("v.displayClauseList");
        console.log('selectedState: '+selectedState);
        for(var i = 0; i <displayClauseList.length; i++) {
            console.log("applicable State: "+displayClauseList[i].ApplicableState__c);
            console.log(selectedState == displayClauseList[i].ApplicableState__c);
            if(selectedState == displayClauseList[i].ApplicableState__c){
                newDisplayClauseList.push(displayClauseList[i]);
            }
        }
        component.set("v.displayClauseList",newDisplayClauseList);
    },
    helperSearch : function(component) {
        var searchKey = component.get("v.searchKey");
        var searchClauseType = component.find('clauseTypePicklist').get('v.value');
        var searchDocLoc = component.find('docLocPicklist').get('v.value');
        var displayClauseList = component.get("v.clauseList");
        var displayOppClauseList = component.get("v.opportunityClauseList");
        var selectedState = component.get("v.selectedApplicableState");
        var newDisplayClauseList = [];
        var newDisplayClauseWithStateList = [];
        var newDisplayOppClauseList = [];
        if(searchKey != "" || searchClauseType != "" || searchDocLoc != "") {
            for(var i = 0; i <displayClauseList.length; i++) {
                if((searchKey != "" && searchKey != null) &&
                   (searchClauseType == "" || searchClauseType == null) &&
                   (searchDocLoc == "" || searchDocLoc == null)) {
                    if((displayClauseList[i].Name.toLowerCase().indexOf(searchKey.toLowerCase()) != -1)) {
                        newDisplayClauseList.push(displayClauseList[i]);
                    }
                } else if((searchKey != "" && searchKey != null) &&
                          (searchClauseType != "" && searchClauseType != null) &&
                          (searchDocLoc == "" || searchDocLoc == null)) {
                    if((displayClauseList[i].Name.toLowerCase().indexOf(searchKey.toLowerCase()) != -1) &&
                       (displayClauseList[i].Type__c == searchClauseType)) {
                        newDisplayClauseList.push(displayClauseList[i]);
                    }
                } else if((searchKey != "" && searchKey != null) &&
                          (searchDocLoc != "" && searchDocLoc != null) &&
                          (searchClauseType == "" || searchClauseType == null)) {
                    if((displayClauseList[i].Name.toLowerCase().indexOf(searchKey.toLowerCase()) != -1) &&
                       (displayClauseList[i].DocumentLocation__c == searchDocLoc)) {
                        newDisplayClauseList.push(displayClauseList[i]);
                    }
                } else if((searchClauseType != "" && searchClauseType != null) &&
                          (searchKey == "" || searchKey == null) &&
                          (searchDocLoc == "" || searchDocLoc == null)) {
                    if(displayClauseList[i].Type__c == searchClauseType) {
                        newDisplayClauseList.push(displayClauseList[i]);
                    }
                } else if((searchClauseType != "" && searchClauseType != null) &&
                          (searchDocLoc != "" && searchDocLoc != null) &&
                          (searchKey == "" || searchKey == null)) {
                    if((displayClauseList[i].Type__c == searchClauseType) && 
                       (displayClauseList[i].DocumentLocation__c == searchDocLoc)) {
                        newDisplayClauseList.push(displayClauseList[i]);
                    }
                } else if((searchDocLoc != "" && searchDocLoc != null) &&
                          (searchKey == "" || searchKey == null) &&
                          (searchClauseType == "" || searchClauseType == null)) {
                    if((displayClauseList[i].DocumentLocation__c == searchDocLoc)) {
                        newDisplayClauseList.push(displayClauseList[i]);
                    }
                } else if((searchKey != "" && searchKey != null) &&
                          (searchDocLoc != "" && searchDocLoc != null) &&
                          (searchClauseType != "" && searchClauseType != null)) {
                    if((displayClauseList[i].Name.toLowerCase().indexOf(searchKey.toLowerCase()) != -1) &&
                       (displayClauseList[i].DocumentLocation__c == searchDocLoc) &&
                       (displayClauseList[i].Type__c == searchClauseType)) {
                        newDisplayClauseList.push(displayClauseList[i]);
                    }
                }
            }
            if(displayOppClauseList.length > 0) {
                for(var i = 0; i <displayOppClauseList.length; i++) {
                    if((searchClauseType != "" && searchClauseType != null) &&
                       (searchDocLoc == "" || searchDocLoc == null)) {
                        if(displayOppClauseList[i].Type__c == searchClauseType) {
                            newDisplayOppClauseList.push(displayOppClauseList[i]);
                        }
                    } else if((searchClauseType != "" && searchClauseType != null) &&
                              (searchDocLoc != "" && searchDocLoc != null)) {
                        if(displayOppClauseList[i].ReferencedClause__c != null && (displayOppClauseList[i].ReferencedClause__r.DocumentLocation__c != null || 
                           displayOppClauseList[i].ReferencedClause__r.DocumentLocation__c != '')) {
                            if((displayOppClauseList[i].Type__c == searchClauseType) && 
                               (displayOppClauseList[i].ReferencedClause__r.DocumentLocation__c == searchDocLoc)) {
                                newDisplayOppClauseList.push(displayOppClauseList[i]);
                            }
                        }
                    } else if((searchDocLoc != "" && searchDocLoc != null) &&
                              (searchClauseType == "" || searchClauseType == null)) {
                        if(displayOppClauseList[i].ReferencedClause__c != null && (displayOppClauseList[i].ReferencedClause__r.DocumentLocation__c != null || 
                           displayOppClauseList[i].ReferencedClause__r.DocumentLocation__c != '')) {
                            if(displayOppClauseList[i].ReferencedClause__r.DocumentLocation__c == searchDocLoc) {
                                newDisplayOppClauseList.push(displayOppClauseList[i]);
                            }
                        }
                    }
                }
            }
        }
        if(searchKey == "" && searchClauseType == "" && searchDocLoc == ""){
            newDisplayClauseList = component.get("v.clauseList");
            newDisplayOppClauseList = component.get("v.opportunityClauseList");
        }
        
        for(var i = 0; i <newDisplayClauseList.length; i++) {
            console.log("applicable State: "+newDisplayClauseList[i].ApplicableState__c);
            console.log(selectedState == newDisplayClauseList[i].ApplicableState__c);
            if(selectedState == newDisplayClauseList[i].ApplicableState__c){
                newDisplayClauseWithStateList.push(newDisplayClauseList[i]);
            }
        }
        //component.set("v.displayClauseList",newDisplayClauseList);
        component.set("v.displayClauseList", newDisplayClauseWithStateList);
        component.set("v.displayOppClauseList", newDisplayOppClauseList);
    }
})