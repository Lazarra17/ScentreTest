({
	showToast : function(component, state, title, message){
        var eventHandler = $A.get("e.c:ToastEvent");
        
        eventHandler.setParams({
            state : state,
            title : title,
            message : message
        });
        
        eventHandler.fire();
    }
})