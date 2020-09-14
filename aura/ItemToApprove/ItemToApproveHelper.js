({
	handleApprove : function(component, event, headerText) {
		this.createModal(component, event, 'Approve', headerText);
	},
    
    handleReject : function(component, event, headerText) {
		this.createModal(component, event, 'Reject', headerText);
	},
    
    handleReassign : function(component, event, headerText) {
		this.createModal(component, event, 'Reassign', headerText);
	},
    
    createModal : function(component, event, actionType, headerText){
        $A.createComponent(
            "c:CustomApproveReject",
            {
                "actionType": actionType,
                "workItemId" : component.get("v.item.workItemId"),
                "headerText" : headerText
            },
            function(modalComponent, status, errorMessage){
                //Add the new button to the body array
                if (status === "SUCCESS") {
                    var body = component.get("v.body");
                    body.push(modalComponent);
                    component.set("v.body", body);
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                    // Show offline error
                }
                else if (status === "ERROR") {
                    console.log("Error: " + errorMessage);
                    // Show error message
                }
            }
        );
    }
})