({
	doInit: function(cmp, event, helper) {
		console.log("init started")
		cmp.set('v.atomicChanges', []);
		cmp.set('v.draftValues', []);
		cmp.set('v.mycolumns', [
			{ label: 'Space', fieldName: 'spaceUrl', type: 'url', typeAttributes: { label: { fieldName: 'spaceName' } }},
			{ label: 'Current / Previous Tenant', fieldName: 'CurrentPreviousTenant__c', type: 'text' },
            { label: 'Opportunity Name', fieldName: 'oppoUrl', type: 'url', typeAttributes: { label: { fieldName: 'Name' } }},
			{ label: 'Stage', fieldName: 'StageName', type: 'text', editable: true },
            { label: 'Forecasted Rent Termination Date', fieldName: 'ForecastedRentTerminationDate__c', type: 'date', editable: true},
            { label: 'Annual Minimum Rent Amount', fieldName: 'AnnualMinimumRent__c', type: 'currency', editable: true}
        ]);
		helper.getData(cmp);

		helper.resolveSaveLocalStorage(cmp);
		helper.resolveAutoSaveValue(cmp);
		if (cmp.get('v.saveLocalStorage')) {
			helper.resolveDraftValues(cmp);
		}
	},
	handleClick: function(component, event, helper) {
		component.set("v.typeTest", "date")
	},
	handleSave: function(cmp, event, helper) {
		var draftValues = event.getParam('draftValues');
		helper.saveChanges(cmp, draftValues);
	},
	handleSaveInLocalStorage: function(cmp, event, helper) {
		helper.handleSaveInLocalStorage(cmp, event);
	},
	handleEditCell: function(cmp, event, helper) {
		helper.handleEditCell(cmp, event);
	},
	handleCancel: function(cmp, event, helper) {
		helper.clearDraftValuesLS();
	},
	toggleColumn: function(component, event, helper) {
        helper.toggleCol(component,event,helper);
	}
})