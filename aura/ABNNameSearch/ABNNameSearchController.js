({
    searchAccountName : function(component, event, helper) {
        let accRec = component.get('v.mainRecord');
        if(accRec.BillingCountry != null) {
            component.set("v.displayComponent", true);
            if(accRec.BillingCountry == 'Australia') {
                component.set("v.column", [
                    { label: "ABN", fieldName: "Abn", type: "text"},
                    { label: "Entity Name", fieldName: "Name", type: "text"},
                    { label: "Entity Type", fieldName: "NameType", type: "text"},
                    { label: "Post Code", fieldName: "Postcode", type: "text"},
                    { label: "State", fieldName: "State", type: "text"},
                    {label: 'Update', type: 'button', initialWidth: 135, typeAttributes: { label: 'Update', name: 'update_abn', title: 'Click to Update'}}
                ]);
                helper.searchABNNameHelper(component);
            } else if(accRec.BillingCountry == 'New Zealand') {
                component.set("v.column", [
                    { label: "NZBN", fieldName: "nzbn", type: "text"},
                    { label: "Entity Name", fieldName: "entityName", type: "text"},
                    { label: "Entity Type", fieldName: "entityType", type: "text"},
                    {label: 'Update', type: 'button', initialWidth: 135, typeAttributes: { label: 'Update', name: 'update_nzbn', title: 'Click to Update'}}
                ]);
                helper.searchNZBNNameHelper(component);
            }
        }
    },
    updateTradingName : function(component, event, helper) {
        component.set("v.isLoading", true);
        let actionHandler = component.get("c.isaccountvalidtoupdatedetails");
        let accountRec = component.get("v.mainRecord");
        actionHandler.setParams({
            accountRecordId : accountRec.Id
        });
        actionHandler.setCallback(this, function(response){           
            let res = response.getReturnValue();
            if(res.status!==null&&res.status === "SUCCESS"){
                let returndetails = JSON.parse(res.returnValue);
                component.set("v.activecontracts",returndetails);
                if(returndetails <= 0) {
                    helper.updateTradingNameHelper(component,event);
                } else {
                    component.find('notifLib').showToast({
                        "title": "Error On Updating Account!",
                        "message": $A.get("$Label.c.ABNActiveContractErrorMessage"),
                        "variant": "error"
                    });
                    component.set("v.isLoading", false);
                }
            }
        });
        $A.enqueueAction(actionHandler);
    },
    updateLesseeName : function(component, event, helper) {
        component.set("v.isLoading", true);
        let actionHandler = component.get("c.isaccountvalidtoupdatedetails");
        let accountRec = component.get("v.mainRecord");
        actionHandler.setParams({
            accountRecordId : accountRec.Id
        });
        actionHandler.setCallback(this, function(response){           
            let res = response.getReturnValue();
            if(res.status!==null&&res.status === "SUCCESS"){
                let returndetails = JSON.parse(res.returnValue);
                component.set("v.activecontracts",returndetails);
                if(returndetails <= 0) {
                    helper.updateLesseeNameHelper(component,event);
                } else {
                    component.find('notifLib').showToast({
                        "title": "Error On Updating Account!",
                        "message": $A.get("$Label.c.ABNActiveContractErrorMessage"),
                        "variant": "error"
                    });
                    component.set("v.isLoading", false);
                }
            }
        });
        $A.enqueueAction(actionHandler);
    }
})