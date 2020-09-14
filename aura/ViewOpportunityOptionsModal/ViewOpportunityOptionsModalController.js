({
    doInit : function(component, event, helper){
        var standardReview = component.get('v.standardReview');
        if(standardReview == 'Non-standard') {
            component.set('v.showReviewType', true);
        } else {
            component.set('v.showReviewType', false);
        }
    },
    
    successSaving : function(component, event, helper) {
        helper.showToast(component, 'success', 'Options Updated!', '');
        component.set('v.showSpinner', false);
        component.find("overlayLib").notifyClose();
    },
    
    errorSaving : function(component, event, helper) {
        helper.showToast(component, 'error', 'Error!', 'Error on updating rent review');
        component.set('v.showSpinner', false);
    },
    
    onSubmit : function(component, event, helper) {
        component.set('v.showSpinner', true);
    }
})