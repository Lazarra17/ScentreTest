({
    /*doInit : function(component, helper) {
        var flow = component.find("newretailerflow");
        // In that component, start your flow. Reference the flow's Unique Name.
        var inputVariables = [
         { name : "recordId", type : "String", value:""},
		 { name : "propertyId", type : "String", value:""},
       ];
        flow.startFlow("OPP_NewRetailer",inputVariables);
    },*/
    closeModal:function(component,event,helper){    
        var cmpTarget = component.find('Modalbox');
        var cmpBack = component.find('Modalbackdrop');
        $A.util.removeClass(cmpBack,'slds-backdrop--open');
        $A.util.removeClass(cmpTarget, 'slds-fade-in-open'); 
            var homeEvt = $A.get("e.force:navigateToObjectHome");
            homeEvt.setParams({
                "scope": "Opportunity"
            });
            homeEvt.fire();
    }
})