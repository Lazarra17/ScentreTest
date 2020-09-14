({
    onDoInit : function(component, event, helper) {
       
        if(component.get("v.sObjectName")==="Opportunity"){
            component.set('v.mycolumns', [
            {label: 'Space', fieldName: 'spaceLink', type: 'url', typeAttributes: { label: { fieldName: 'spaceName' }}},
            {label: 'Clause Name', fieldName: 'clauseLink', type: 'url', typeAttributes: { label: { fieldName: 'clauseName' }}},
            {label: 'Retailer Name', fieldName: 'accountLink', type: 'url', typeAttributes: { label: { fieldName: 'accountName' }}},
            {label: 'Account Category', fieldName: 'accountCategory', type: 'text'}
             ]); 
        }else{
            component.set('v.mycolumns', [
            {label: 'Space', fieldName: 'spaceLink', type: 'url', typeAttributes: { label: { fieldName: 'spaceName' }}, fixedWidth: 100},
            {label: 'Clause Name', fieldName: 'clauseLink', type: 'url', typeAttributes: { label: { fieldName: 'clauseName' }}},
            {label: 'Retailer Name', fieldName: 'accountLink', type: 'url', typeAttributes: { label: { fieldName: 'accountName' }}},
            {label: 'Account Category', fieldName: 'accountCategory', type: 'text'},
            {label: 'High Risk?', fieldName: 'highRiskClause', type: 'boolean', fixedWidth: 150},
            {label: "Reason", fieldName: "reasonRecommendation", type: "text", fixedWidth: 400}
             ]);
        }
        var action = component.get("c.getDetails");
        action.setParams (
            {recordID : component.get("v.recordId"),
             sourceName : ""
            });
        action.setCallback(this, function(response) {
            var res = response.getReturnValue();
            if (response.getState() === "SUCCESS") {
                var returnValue = JSON.parse(res.returnValue);
                var clauseId = returnValue.clauseId;
                var accountId = returnValue.accountId;
                var spaceId = returnValue.spaceId;
                
                    returnValue.forEach(element => {
                        element.spaceLink = "/one/one.app#/sObject/" + element.spaceId;
                        element.clauseLink = "/one/one.app#/sObject/" + element.clauseId;
                        element.accountLink = "/one/one.app#/sObject/" + element.accountId;
                    });                
                
            }
             component.set('v.mydata', returnValue);
             component.set('v.counter', returnValue.length);
        });
        $A.enqueueAction(action); 
    },
    
    back : function(component, event, helper) {
        var sObectEvent = $A.get("e.force:navigateToSObject");
        sObectEvent .setParams({
            "recordId": component.get("v.recordId"),
            "slideDevName": "detail"
        });
        sObectEvent.fire(); 
    },
                        
	getHelpText : function(component){
        let helpText;
        let titletext;
    	let objectName = component.get("v.sObjectName");
        
        switch(objectName){
            case "Opportunity" : 
                helpText = $A.get("$Label.c.OpportunityRiskClauseHelpText");
                titletext="Property High Risk";
                break;
            case "Space__c" : 
                helpText = $A.get("$Label.c.SpaceRiskClauseHelpText");
                titletext="Property Risk";
                break;
            case "Property__c" : 
                helpText = $A.get("$Label.c.PropertyRiskClauseHelpText");
                titletext="Property Risk";
                break;
        }
        component.set("v.helptextstring", helpText);
        component.set("v.titletextstring", titletext);
	}
    
})