({
    doInit : function(component, event, helper){
        let wizardTab = component.find("wizardTab");
        
        if(wizardTab.get("v.selectedItem") === "businessObjective"){
            helper.createComponent(component, "c:BusinessObjective");
        }
        
        if(component.get("v.targtefieldRecord.RecordType.DeveloperName")==="OPP_CommercialLeasing"){
            component.set("v.displayOptionstab",true);
        }
    },
    
    handleSelect : function(component, event, helper) {
        helper.toggleSpinner(component, "show");
        var componentName = "";
        var currentTab = event.getParams().name;
        
        if(currentTab === "businessObjective"){
            componentName = "c:BusinessObjective";
        }else if(currentTab === "rent"){
            componentName = "c:RentCalculator";
        }else if(currentTab === "capital"){
            componentName = "c:Capital";
        }else if(currentTab === "security"){
            componentName = "c:Security";
        }else if(currentTab === "outgoings"){
            componentName = "c:Outgoings";
        }else if(currentTab === "feescharges"){
            componentName = "c:FeesCharges";
        }else if(currentTab === "rentrreviews"){
            componentName = "c:RentReview";
        }else if(currentTab === "risk"){
            componentName = "c:RiskOpportunityClause";
        }else if(currentTab === "options"){
            componentName = "c:OpportunityOptions";
        }
        
        if(componentName){
         	helper.createComponent(component, componentName);
        } else {
            helper.toggleSpinner(component, "hide");
        }
	}
})