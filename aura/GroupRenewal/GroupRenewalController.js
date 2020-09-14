({
	doInit : function(component, event, helper) {
        component.set('v.isLoading', true);
		const action = component.get('c.getData');
		action.setParam('accId', component.get('v.recordId'));
	    action.setCallback(this, function(response) { 
        	const state = response.getState();
			const returnVal = response.getReturnValue();
			if (state === 'SUCCESS' && returnVal.status === 'SUCCESS') {
            	console.log(response.getReturnValue());
            	const apexRetVal = JSON.parse(returnVal.returnValue);
            	if (apexRetVal.contracts!= null && apexRetVal.contracts.length > 0) {
                    
                    component.set('v.oppOwnerId', apexRetVal.oppOwnerId);
                    component.set('v.dealTypes', apexRetVal.dealTypeValues);
                    
                    helper.prepareDrafts(component, apexRetVal.contracts);
            		console.log(component.get('v.draftOpps'));
                    
            	}            	
            	
			} else {
                helper.showError(component, returnVal.message);
			}
            
            component.set('v.isLoading', false);
            
        });
        $A.enqueueAction(action);
    },
	onSelectAllChange : function(component, event, helper) {
		const areAllSelected = event.getSource().get('v.checked');
        const draftOpps = component.get('v.draftOpps');
        
        draftOpps.forEach(function(draft) {
            draft.isSelected = areAllSelected;
        });
            
		component.set('v.draftOpps', draftOpps);
        component.set('v.saveEnabled', areAllSelected);
        
	},
    onRowSelectChange : function(component, event, helper) {
        
        const isRowSelected = event.getSource().get('v.checked');
        
        if (!isRowSelected) {
            component.find('select all').set('v.checked', false);
        }
        
        const draftOpps = component.get('v.draftOpps');
        
        component.set('v.saveEnabled', draftOpps.find(draft => draft.isSelected));
        
    },
    saveDrafts : function(component, event, helper) {
        event.preventDefault();
        console.log('Event Fields ' + JSON.stringify(event.getParam("fields")));
        
        const primaryContact = event.getParam("fields").PrimaryContact__c;
        const groupRenewalAdmin = event.getParam("fields").Group_Renewal_Retail_Admin__c;
        
        component.set('v.isLoading', true);
        $A.util.addClass(component.find('errorMessage'), 'slds-hide');
        
        
		const draftOpps = component.get('v.draftOpps');
        const checkedOpps = draftOpps.filter(draft => draft.isSelected);
         
        if (checkedOpps.length > 0) {
			const oppList = helper.prepareData(component, checkedOpps, primaryContact, groupRenewalAdmin);
            
            //console.log('FROM JS ' + JSON.stringify(oppList));
            
            const action = component.get('c.saveOpportunities');
            action.setParam('oppList',oppList);
            action.setCallback(this, function(response) {
                const state = response.getState();
                const returnVal = response.getReturnValue();
                //console.log (returnVal);
                if (state === 'SUCCESS' && returnVal.status === 'SUCCESS') {
                    const apexRetVal = JSON.parse(returnVal.returnValue);
                    //console.log('FROM APEX ' + JSON.stringify(apexRetVal));
                    component.set('v.savedOpps', apexRetVal.savedOpps);
                    component.set('v.showResults', true);
                    
                } else {
                    //console.log(returnVal.message);
                    helper.showError(component, returnVal.message);
                }
                component.set('v.isLoading', false);
            });
            
            $A.enqueueAction(action);
        }  
    },
    calculateEndDate : function(component, event, helper){
		const idx = event.target.dataset.index;
        const draftOpps = component.get('v.draftOpps');
        
        const draftForUpdate = draftOpps[idx];
        const startDate = draftForUpdate.proposedStartDate ? new Date(draftForUpdate.proposedStartDate) : null;

        
        if (helper.isValidDate(startDate)) {
            const year = startDate.getFullYear() + (draftForUpdate.termYears && !isNaN(draftForUpdate.termYears) ? parseInt(draftForUpdate.termYears) : 0);
            const month = startDate.getMonth() + (draftForUpdate.termMonths && !isNaN(draftForUpdate.termMonths) ? parseInt(draftForUpdate.termMonths) : 0);
            let day = startDate.getDate() + 1 + (draftForUpdate.termDays && !isNaN(draftForUpdate.termDays) ? parseInt(draftForUpdate.termDays) : 0);
            
            
            if (year != 0 || month != 0 || day != 0) {
                day -= 1; 
            }
            
            draftOpps[idx].leaseEndDate = (new Date(year, month, day)).toISOString();
            component.set('v.draftOpps', draftOpps);
            
        }
        
    },
    dataServiceLoad : function(component, event, helper) {
        component.set('v.isDataServiceLoading', false);
    }
    
})