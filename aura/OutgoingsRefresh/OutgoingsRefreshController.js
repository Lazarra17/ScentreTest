({
	getTableRecords : function(component, event, helper) {
        helper.getColumns(component);
		helper.getOpportunityHelper(component);
        
        component.set("v.rentDateRange", {})
	},
    
    refreshOppLineItem : function(component, event, helper){
        let opportunityList = component.get("v.filterOpportunityList");
        
        if(!$A.util.isEmpty(opportunityList)){
            helper.toggleSpinner(component, "show");
        	helper.refreshOppLineItemHelper(component)
        } else {
            helper.showToast(component, "error", "Error!", "No Opportunities for refresh");
        }
    },
    
    filterOpportunity : function(component, event, helper){
        helper.toggleSpinner(component, "show");
        helper.filterOpportunityHelper(component)
    }
})