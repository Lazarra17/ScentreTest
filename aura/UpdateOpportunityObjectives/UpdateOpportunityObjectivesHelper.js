({    
    successMessage : function() {
        const toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: "Success",
            message: "Opportunity Updated",
            type: "success",
            duration:'5000',
            key: 'info_alt',
            mode: 'pester'
        });
        toastEvent.fire();
    },
    errorMessage : function() {
        const toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: "Error!",
            message: "Updating Opportunity Failed",
            type: "error",
            duration:'5000',
            key: 'info_alt',
            mode: 'pester'
        });
        toastEvent.fire();
    },
    lockAccount : function(component) {
        const action = component.get('c.lockOpportunity');
        action.setParam('oppId', component.get('v.recordId'));
        action.setCallback(this, function(response) {
            const state = response.getState();
            console.log('state2 -- ' + state);
            if (state === 'SUCCESS') {
                this.successMessage();
            } else {
                this.errorMessage();
            }
            component.set('v.showSpinner', false); 
        });
        $A.enqueueAction(action);
    }
})