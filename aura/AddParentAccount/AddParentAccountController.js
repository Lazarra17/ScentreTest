({
    onLoad : function(component, event, helper) {
        var accountRecord = component.get("v.accountRecordField");
        if(accountRecord != null) {
            component.find("accountNameField").set("v.value", accountRecord.Name.slice(0,accountRecord.Name.length - 6));
            component.find("accountABN").set("v.value", accountRecord.ABNNZBN__c);
            component.find("accountACN").set("v.value", accountRecord.ACN__c);
            component.find("accountTradingName").set("v.value", accountRecord.TradingName__c);
            component.find("accountLesseeName").set("v.value", accountRecord.LesseeName__c);
            component.find("accountType").set("v.value", accountRecord.Type);
            component.find("accountCategory").set("v.value", accountRecord.Category__c);
            component.find("accountSuperfineCategory").set("v.value", accountRecord.SuperfineCategory__c);
            component.find("accountCluster").set("v.value", accountRecord.Cluster__c);
            component.find("accountBillingCountry").set("v.value", accountRecord.BillingCountry);
            component.find("accountBillingState").set("v.value", accountRecord.BillingState);
            component.find("accountBillingStreet").set("v.value", accountRecord.BillingStreet);
            component.find("accountBillingCity").set("v.value", accountRecord.BillingCity);
            component.find("accountBillingPostalCode").set("v.value", accountRecord.BillingPostalCode);
            component.find("accountShippingCountry").set("v.value", accountRecord.ShippingCountry);
            component.find("accountShippingState").set("v.value", accountRecord.ShippingState);
            component.find("accountShippingStreet").set("v.value", accountRecord.ShippingStreet);
            component.find("accountShippingCity").set("v.value", accountRecord.ShippingCity);
            component.find("accountShippingPostalCode").set("v.value", accountRecord.ShippingPostalCode);
        }
    },
	onSuccess : function(component, event, helper) {
        var record = event.getParam("response");
        component.set("v.accountRecordField.ParentId", record.id);
        component.find("childAccountRecord").saveRecord(function(saveResult) {
            var toast = component.find("toast-account");
            if(saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                toast.set("v.title", "Account Record Created!");
                toast.set("v.state", "success");
                toast.set("v.message", "Parent Account is created successfully.");
                toast.showToast();
                //component.set("v.isLoading", false);
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": record.id
                });
                navEvt.fire();
            } else if (saveResult.state === "ERROR") {
                toast.set("v.title", "Error On Updating Account!");
                toast.set("v.state", "error");
                toast.set("v.message", "Error on updating child account");
                toast.showToast();
                component.set("v.isLoading", false);
                console.log('Problem saving record, error: ' + JSON.stringify(saveResult.error));
            }
        });
	},
    onError : function(component, event, helper) {
        component.set("v.isLoading", false);
        var errorParamsRaw = event.getParams();
        var errorParamsJSON = JSON.stringify(errorParamsRaw);
        console.log(errorParamsJSON);
	},
    onSubmit : function(component, event, helper) {
		component.set("v.isLoading", true);
	},
    closeModal : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
	}
})