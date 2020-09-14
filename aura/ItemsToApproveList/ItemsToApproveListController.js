({
	doInit : function(component, event, helper) {
		var action = component.get("c.getItemsToApprove");
        	
        	action.setCallback(this, function(a){
                debugger;
                //component.set("v.showSpinner", false);
                if(a.getState() === 'SUCCESS'){
                    console.log(a.getReturnValue());
                    component.set("v.itemsList", a.getReturnValue());
                }
        	});
			$A.enqueueAction(action);
	}
})