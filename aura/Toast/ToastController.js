({
	showToast : function(component, event, helper) {
		var toast = component.find("toast");
        
        $A.util.removeClass(toast, "slds-hide");
        component.set("v.state", event.getParams().state);
        component.set("v.title", event.getParams().title);
        component.set("v.message", event.getParams().message);
        
        setTimeout(
            function(){
                let toa = component.find("toast");
                if(!$A.util.isEmpty(toa)){
                    $A.util.addClass(toa, "slds-hide");
                }
            }, 
            component.get("v.duration")
        );
	},
    
    closeToast : function(component, event, helper) {
		var toast = component.find("toast");
        $A.util.addClass(toast, "slds-hide");
	}
})