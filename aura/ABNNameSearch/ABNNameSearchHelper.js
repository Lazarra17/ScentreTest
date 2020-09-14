({
    searchABNNameHelper : function(component) {
        component.set("v.isLoading", true);
        var action = component.get("c.getABNNameList");
        let accRec = component.get('v.mainRecord');
        action.setParams({
            tradingName : accRec.TradingName__c,
            lesseeName : accRec.LesseeName__c
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            console.log("RESPONSE: "+response);
            if(state === "SUCCESS" && getReturn.status === "SUCCESS") {
                var retVal;
                if(getReturn.returnValue){
                    retVal = JSON.parse(getReturn.returnValue);
                    if(retVal.abnTradingNameSearch.Names) {
                        component.set("v.ABNTradingNameSearchResultWrapper", retVal.abnTradingNameSearch.Names);
                    }
                    if(retVal.abnLesseeNameSearch.Names) {
                        component.set("v.ABNLesseNameSearchResultWrapper", retVal.abnLesseeNameSearch.Names);
                    }
                } else {
                    component.set("v.ABNTradingNameSearchResultWrapper", []);
                    component.set("v.ABNLesseNameSearchResultWrapper", []);
                }
            } else {
                if(getReturn.message){
                    console.log(getReturn.message);
                }
            }
            component.set("v.isLoading", false);
        });
        $A.enqueueAction(action);
    },
    searchNZBNNameHelper : function(component) {
        component.set("v.isLoading", true);
        var action = component.get("c.getNZBNNameList");
        let accRec = component.get('v.mainRecord');
        action.setParams({
            tradingName : accRec.TradingName__c,
            lesseeName : accRec.LesseeName__c
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            if(state === "SUCCESS" && getReturn.status === "SUCCESS") {
                var retVal;
                if(getReturn.returnValue){
                    retVal = JSON.parse(getReturn.returnValue);
                    if(retVal.nzbnTradingNameSearch) {
                        component.set("v.NZBNTradingNameSearchResultWrapper", retVal.nzbnTradingNameSearch);
                    }
                    if(retVal.nzbnLesseeNameSearch) {
                        component.set("v.NZBNLesseNameSearchResultWrapper", retVal.nzbnLesseeNameSearch);
                    }
                } else {
                    component.set("v.NZBNTradingNameSearchResultWrapper", []);
                    component.set("v.NZBNLesseNameSearchResultWrapper", []);
                }
            } else {
                if(getReturn.message){
                    console.log(getReturn.message);
                }
            }
            component.set("v.isLoading", false);
        });
        $A.enqueueAction(action);
    },
    updateTradingNameHelper : function(component, event) {
        component.set("v.isLoading", true);
        var action = event.getParam('action');
        let accRec = component.get('v.mainRecord');
        var row = event.getParam('row');
        if(accRec.BillingCountry != null) {
            if(accRec.BillingCountry == 'Australia') {
                if(row.Name != null) {
                    component.set("v.mainRecord.TradingName__c", row.Name);
                    component.set("v.mainRecord.ABNNZBN__c", row.Abn);
                }
            } else if(accRec.BillingCountry == 'New Zealand') {
                if(row.entityName != null) {
                    component.set("v.mainRecord.TradingName__c", row.entityName);
                    component.set("v.mainRecord.ABNNZBN__c", row.nzbn);
                }
            }
        }
        component.find("accountRecord").saveRecord(function(saveResult) {
            if(saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                component.find('notifLib').showToast({
                    "title": "Success On Updating Account!",
                    "message": "The record has been updated successfully.",
                    "variant": "success"
                });
                component.find("accountRecord").reloadRecord();
            } else if (saveResult.state === "ERROR") {
                component.set("v.isLoading", false);
                var errMsg = "";
                for (var i = 0; i < saveResult.error.length; i++) {
                    errMsg += saveResult.error[i].message + "\n";
                }
                component.find('notifLib').showToast({
                    "title": "Error On Updating Account!",
                    "message": errMsg,
                    "variant": "error"
                });
                console.log('Problem saving record, error: ' + JSON.stringify(saveResult.error));
            }
        });
    },
    updateLesseeNameHelper : function(component, event) {
        component.set("v.isLoading", true);
        var action = event.getParam('action');
        var row = event.getParam('row');
        let accRec = component.get('v.mainRecord');
        if(accRec.BillingCountry != null) {
            if(accRec.BillingCountry == 'Australia') {
                if(row.Name != null) {
                    component.set("v.mainRecord.LesseeName__c", row.Name);
                    component.set("v.mainRecord.ABNNZBN__c", row.Abn);
                }
            } else if(accRec.BillingCountry == 'New Zealand') {
                if(row.entityName != null) {
                    component.set("v.mainRecord.LesseeName__c", row.entityName);
                    component.set("v.mainRecord.ABNNZBN__c", row.nzbn);
                }
            }
        }
        component.find("accountRecord").saveRecord(function(saveResult) {
            if(saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                component.find('notifLib').showToast({
                    "title": "Success On Updating Account!",
                    "message": "The record has been updated successfully.",
                    "variant": "success"
                });
                component.find("accountRecord").reloadRecord();
            } else if (saveResult.state === "ERROR") {
                component.set("v.isLoading", false);
                var errMsg = "";
                for (var i = 0; i < saveResult.error.length; i++) {
                    errMsg += saveResult.error[i].message + "\n";
                }
                component.find('notifLib').showToast({
                    "title": "Error On Updating Account!",
                    "message": errMsg,
                    "variant": "error"
                });
                console.log('Problem saving record, error: ' + JSON.stringify(saveResult.error));
            }
        });
    }
})