({
    doInit : function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Warning!",
            "type":"error",
            "mode":"sticky",
            "message": "This System is under Maintainance."
        });
        toastEvent.fire();
    }
})