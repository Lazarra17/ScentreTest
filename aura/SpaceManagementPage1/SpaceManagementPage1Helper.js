({
    pushSelectedSpace : function(component, selectedSpaceList) {
        var eventHandler = component.getEvent("pushSelectedSpaces")
        
        eventHandler.setParams({
            mode : component.get("v.mode"),
            action : "next",
            spaceList : selectedSpaceList
        })
        
        eventHandler.fire();
    },
    
    throwError : function(component, title, state, message){
        var eventHandler = $A.get("e.c:ToastEvent")
        
        eventHandler.setParams({
            state : state,
            title : title,
            message : message
        })
        
        eventHandler.fire()
    }
})