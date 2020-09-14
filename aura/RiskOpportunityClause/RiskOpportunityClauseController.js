({
	getTableRecords : function(component, event, helper) {
		//helper.getEditAccess(component);
		helper.getRiskOpportunityClause(component);
	},
	
	handleSave : function(component, event, helper){
        component.set("v.isLoading", true);
		helper.updateOppClause(component, event.getParam('draftValues'));
	},
	
	handleEditCell : function(component, event, helper){
	
	},
	
	handleCancel : function(component, event, helper){
		component.set("v.opportunityClauseTemp", []);
	}
})