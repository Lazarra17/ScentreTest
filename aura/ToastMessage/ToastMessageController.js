({
	showMessage : function(component, event, helper) {
		var toast = component.find("toastm");
        $A.util.removeClass(toast, "slds-hide");
        setTimeout(
            function(){
                let toa = component.find("toastm");
                if(!$A.util.isEmpty(toa)){
                    $A.util.addClass(toa, "slds-hide");
                }
            }, 
            component.get("v.duration")
        );
	},
    
    closeToast : function(component, event, helper) {
		var toast = component.find("toastm");
        $A.util.addClass(toast, "slds-hide");
	}
})