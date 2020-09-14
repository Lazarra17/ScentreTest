({
	saveSpace : function(component, modalMode) {        
		var eventHandler = component.getEvent("save")
        
        console.log("lostSpace : ", JSON.parse(JSON.stringify(component.get("v.lostSpace"))));
        
        if(modalMode === "Lost Space"){
            eventHandler.setParams({
                space : component.get("v.lostSpace")
            })
        }
        
        eventHandler.fire()
        
        this.closeModalHelper(component)
	},
    
    closeModalHelper : function(component){
        var modalBox = component.find("modalbox");
        var modalBackdrop = component.find("modalBackdrop")
        
        $A.util.addClass(modalBox, "slds-fade-in-close") 
        $A.util.removeClass(modalBox, "slds-fade-in-open")
        $A.util.addClass(modalBackdrop, "slds-backdrop--close") 
        $A.util.removeClass(modalBackdrop, "slds-backdrop--open")
    },
    
    areFieldsValid : function(component, elements){
        var isValid = true;
        
        for (var i in elements){
            var elem = component.find(elements[i]);
			
            if (!$A.util.isEmpty(elem)){
                if(!elem.get("v.validity").valid) {
                    elem.showHelpMessageIfInvalid();
                    isValid = false;
                }
            }
        } 
        
        return isValid;
    },
    
    showToast : function(component, state, title, message){
        var eventHandler = $A.get("e.c:ToastEvent")
        
        eventHandler.setParams({
            state : state,
            title : title,
            message : message
        })
        
        eventHandler.fire()
    },
})