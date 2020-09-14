({
    verifyUserAccess : function(component) {
        var action = component.get("c.userHasEditAccess");
        action.setParams({
            opportunityId : component.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            if(state === "SUCCESS") {
                if(getReturn){
                    component.set("v.isReadOnly", getReturn);
                }
            } else {
                console.log(getReturn.message);
            }
        });
        $A.enqueueAction(action);
    },
    showToast : function(component, type, title, message){
        var toast = component.find("toast");
        
        toast.set("v.title", title);
        toast.set("v.state", type);
        toast.set("v.message", message);
        
        toast.showToast();
    }
})