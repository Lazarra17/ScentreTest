({
	doInit : function(component, event, helper) {
		var action = component.get("c.getPropertyMapBySpace");
        action.setParams({
            "spaceId": component.get("v.recordId")
        });
        // Add callback behavior for when response is received
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var conts = response.getReturnValue();
                component.set("v.imageLocation", conts);
            }
            else {
                var toastEventFailed = $A.get("e.force:showToast");
                console.log('errorMessage', response.getError());
                toastEventFailed.setParams({
                    "title": "Failed!",
                    "message": "Fail to achieve space property map"
                });
                toastEventFailed.fire();
            }
        });
        // Send action off to be executed
        $A.enqueueAction(action);    
    }
})