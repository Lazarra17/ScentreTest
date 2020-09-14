({
    handleSubmit : function(component, event, helper) {
        event.preventDefault();
        
        const eventFields = event.getParam("fields");
        component.set('v.showSpinner', true);
        const action = component.get('c.unLockOpportunity');
        
        action.setParam('oppId',component.get('v.recordId'));
        
        action.setCallback(this, function(response) {
            
            const state = response.getState();
            const apexReturnValue = JSON.parse(response.getReturnValue().returnValue);
            if (state === 'SUCCESS') {
                component.set('v.isLocked', apexReturnValue.lockedOpp);
                component.find('recordForm').submit(eventFields);
                
            } else {
                helper.errorMessage();
            }
        });
        $A.enqueueAction(action);
    },
    handleSuccess : function(component, event, helper) {
        if (component.get('v.isLocked')) {
            helper.lockAccount(component);
        } else {
            helper.successMessage();
            component.set('v.showSpinner', false);
        }
    },
    handleError : function(component, event, helper) {
        helper.errorMessage();
        component.set('v.showSpinner', false);
    }
})