({
	doInit : function(component, event, helper) {
		var calloutResult = component.get("c.getOppty");
        
            calloutResult.setParams({
                opptyId : component.get("v.recordId")
            });
            
            calloutResult.setCallback(this, function(response){
                var state = response.getState();
                
                var getReturn = response.getReturnValue();
                if(state == "SUCCESS"){
                    
                    
                }else{
                    component.set("v.errorMsg", getReturn.errorMessage);
                }
            })
            $A.enqueueAction(calloutResult);
	},
    handleShowModal: function(component) {
        $A.createComponent("c:OpportunityReversalConfirmationModal", {},
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   var modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: "Are you sure you want to Reset this Opportunity? Please ensure you cancel any outstanding tasks, update the Opportunity and Resubmit for Approval",
                                       body: modalBody, 
                                       showCloseButton: false,
                                       closeCallback: function(ovl) {}
                                   }).then(function(overlay){});
                               }
                           });
    },
    handleApplicationEvent : function(component, event, helper) {
        
        var message = event.getParam("message");
        if(message == 'Ok'){
            component.set("v.showSpinner", true);
        	var calloutResult = component.get("c.reverseOpportunity");
        
            calloutResult.setParams({
                newOppId : component.get("v.recordId")
            });
            
            calloutResult.setCallback(this, function(response){
                var state = response.getState();
                var res = response.getReturnValue();
                if(state == "SUCCESS" && res.status === "SUCCESS"){
                    helper.showToast(component, "success", "Success!", "Opportunity reversed successfully.");
                    component.set("v.showSpinner", false);
                    $A.get('e.force:refreshView').fire();  
                }else if(res.errortype === "IsISTask"){
                    let errors = response.getError();
					console.log('errorMessage', response.getError());
                    
                    helper.showToast(component, "Failed", "error!", "Instruct Solicitor task is completed. Opportunity cannot be reversed.");
                    component.set("v.showSpinner", false);
                }else if(res.errortype === "ISADSTask"){
                    let errors = response.getError();
					console.log('errorMessage', response.getError());
                    
                    helper.showToast(component, "Failed", "error!", "Opportunity cannot be reversed.");
                    component.set("v.showSpinner", false);
                }else if(res.errortype === "IsJVTask"){
                    let errors = response.getError();
					console.log('errorMessage', response.getError());
                    
                    helper.showToast(component, "Failed", "error!", "JV Approval is pending, Opportunity cannot be reversed.");
                    component.set("v.showSpinner", false);
                }else{
                    let errors = response.getError();
					console.log('errorMessage', response.getError());
                    
                    helper.showToast(component, "Failed", "error!", res.errorMsg);
                    component.set("v.showSpinner", false);
                }
            })
            
            $A.enqueueAction(calloutResult);
        }else if(message == 'Cancel'){
        	// if the user clicked the Cancel button do your further Action here for canceling
      	}
    }
})