({
    searchABN : function(component, event, helper) {
        component.set("v.isLoading", true);
        var mainRecord = component.get("v.mainRecord");
        var sobjectName = component.get("v.sObjectName");
        var recordCountry=null;
        if(sobjectName == 'Lead' && mainRecord.Country!==null) {
            recordCountry = mainRecord.Country;
        } else if(sobjectName == 'Account') {
            recordCountry = mainRecord.BillingCountry;
        }
        component.set("v.recordCountry", recordCountry);
        if(recordCountry != null) {
            component.set("v.displaycomponent",true);
            if(recordCountry == 'New Zealand') {
                helper.searchNZBNHelper(component);
            } else if(recordCountry === 'Australia') {
                if(mainRecord.ABNNZBN__c != null) {
                    helper.searchABNHelper(component, 'ABN', mainRecord.ABNNZBN__c);
                }else{
                    component.set("v.abnErrorMessage","ABN is Empty");
                }
                if(mainRecord.ACN__c != null) {
                    helper.searchABNHelper(component, 'ACN', mainRecord.ACN__c); 
                }else{
                    component.set("v.acnErrorMessage","ACN is Empty");
                }
            }
        } else {
            component.set("v.displaycomponent",false);
        }
        component.set("v.isLoading", false);
    },
    updateAccountdata : function(component, event, helper) {
        helper.validateUpdateOperationHelper(component, event);
    },
    saveAccountdetails : function(component, event, helper) {
        var radioGrpValue = component.get("v.abnBusinessNamestring");
    }
})