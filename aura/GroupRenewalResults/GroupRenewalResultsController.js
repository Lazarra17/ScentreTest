({
	doInit : function(component, event, helper) {
        
        const savedOpps = component.get('v.OpportunityList');
        
		//console.log('TO Datatable ' + JSON.stringify(savedOpps))
        
        savedOpps.forEach(function(savedOpp) {
            savedOpp.accountName = savedOpp.Account.Name;
            savedOpp.propertyName =  savedOpp.Property__r.Name;
            savedOpp.spaceName = savedOpp.Space__r.Name;
            savedOpp.oppUrl = '/' + savedOpp.Id;
        });
            
        component.set('v.data', savedOpps);
        
		//console.log('IN Datatable ' + JSON.stringify(savedOpps))
        
        component.set('v.columns', [
            {label: 'Opportunity name', fieldName: 'oppUrl', type: 'url', typeAttributes: {label : {fieldName:'Name'}}},
            {label: 'Account', fieldName: 'accountName', type: 'text'},
            {label: 'Property', fieldName: 'propertyName', type: 'text'},
            {label: 'Space name', fieldName: 'spaceName', type: 'text'},
            {label: 'Stage', fieldName: 'StageName', type: 'text'},
            {label: 'Type', fieldName: 'Type', type: 'text'},
            {label: 'Deal Type', fieldName: 'DealType__c', type: 'text'},
        ]);
	}
})