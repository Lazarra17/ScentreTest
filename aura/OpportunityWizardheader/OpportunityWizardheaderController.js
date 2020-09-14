({
	doInit : function(component, event, helper) {
       
		var action = component.get("c.getMoreValue");
		action.setParams({
            "opportunityId": component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            console.log(response.getReturnValue().spaceType+"HEADER"+state)
            if(state === "SUCCESS"){
                 component.set("v.spaceType", response.getReturnValue().spaceType);
            } 
        });
        $A.enqueueAction(action);
	}
})