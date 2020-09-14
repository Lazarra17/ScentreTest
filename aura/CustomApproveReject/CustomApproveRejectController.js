({
    doInit : function(component, event, helper) {
        //alert('doinit');
        component.find('comments').focus();
    },
    
    closeModal : function(component, event, helper) {
        component.destroy();
    },
    
    handleSave : function(component, event, helper) {
        if(helper.isValidInput(component, event)){
            var newUser;
            if(component.get("v.reassignedUser") != null){
                newUser = component.get("v.reassignedUser").val;
            }
            component.set("v.showSpinner", true);
            var action = component.get("c.saveItemToApprove");
            action.setParams({
                "workItemId":component.get("v.workItemId"),
                "updatedStatus":component.get("v.actionType"),
                "comments":component.get("v.comments"),
                "newAssignedUser": newUser
            });
            action.setCallback(this, function(a){
                
                component.set("v.showSpinner", false);
                if(a.getState() === 'SUCCESS'){
                    console.log(a.getReturnValue());
                    component.destroy();
                    $A.get('e.force:refreshView').fire();
                }
            });
            $A.enqueueAction(action);
        }
    }
})