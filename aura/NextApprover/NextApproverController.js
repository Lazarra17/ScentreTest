({
	doInit : function(component, event, helper) {
		var action = component.get("c.getNextApprover");
        action.setParams({
            "oppId" : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            if(state === "SUCCESS") {
                //alert('getReturn==> ' + getReturn);
                component.set("v.nextApproverName", getReturn);
            }
        });
        $A.enqueueAction(action);
	}
})