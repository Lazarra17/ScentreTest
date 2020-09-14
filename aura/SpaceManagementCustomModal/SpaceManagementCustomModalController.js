({
	createNewLostSpace : function(component, event, helper) {
        var lostSpace = {}
        var params = event.getParam('arguments')
        
        lostSpace.Name = null;
        lostSpace.Type__c = "20";
        lostSpace.RentableArea__c = params.lostSpaceArea;
        lostSpace.ReasonForChange__c = null;
        
        component.set("v.lostSpace", lostSpace);
	}, 
    
    closeModal : function(component, event, helper){
        helper.closeModalHelper(component)
    },
    
    save : function(component, event, helper){
        var modalMode = component.get("v.modalMode");
        
        var elements = [
            "spaceName",
            "reasonForChange"
        ]
        
        console.log("modalMode : ", modalMode);
        
        if(modalMode === "Lost Space"){
            if(helper.areFieldsValid(component, elements)){
                helper.saveSpace(component, modalMode)
            } else {
                helper.showToast(component, "error", "Error!", "Please make sure fields are populated correctly below.");
            }
        } else if(modalMode === "Confirm"){
            helper.saveSpace(component, modalMode)
        }
    }
})