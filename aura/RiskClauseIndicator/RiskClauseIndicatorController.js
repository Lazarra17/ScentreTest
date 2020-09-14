({
	doInit: function (component, event, helper) {
        var action = component.get("c.getDetails");
        action.setParams ({
            recordID : component.get("v.recordId"),
            sourceName : ""
        });
        action.setCallback(this, function(response) {
            var res = response.getReturnValue();
            if (response.getState() === "SUCCESS") {
                var returnValue = JSON.parse(res.returnValue);
                component.set('v.counter', returnValue.length);
                
                if(returnValue.length > 0){
                    component.set('v.isMore', true);
                }
            }
        });
        $A.enqueueAction(action); 

    },
    navigateToComp : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:DisplayRiskClause",
            componentAttributes: {
                recordId: component.get("v.recordId"),
                enableBack:  true
            }
          
        });
        evt.fire();
    }
})