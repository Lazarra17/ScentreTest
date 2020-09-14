({
    save : function(component, event, helper) {
        component.find("edit").get("e.recordSave").fire();
        var eventHandler = $A.get("e.c:ToastEvent");
        eventHandler.setParams({
            state : 'success',
            title : 'Task Saved',
            message : ''
        });
        eventHandler.fire();
        component.find("overlayLib").notifyClose();
    }
})