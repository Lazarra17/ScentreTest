({
    handleApproval: function (component, event, helper) {
        var objName = component.get("v.item.objectName");
        switch(event.getParam("value")) {
            case 'Approve':
                helper.handleApprove(component, event, 'Approve '+objName);
                break;
            case 'Reject':
                helper.handleReject(component, event, 'Reject '+objName);
                break;
            case 'Reassign':
                helper.handleReassign(component, event, 'Reassign Approval Request');
                break;
        }
    },
    
    handleNavigate: function (component, event, helper) {
        var navEvt = $A.get("e.force:navigateToSObject");
        console.log(navEvt);
        navEvt.setParams({
            "recordId": component.get("v.item").workItemId,
            "slideDevName": "detail"
        });
        navEvt.fire();
    }
})