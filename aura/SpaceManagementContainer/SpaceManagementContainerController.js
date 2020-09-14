({
    handleRecordUpdate : function(component, event, helper) {
        const eventParams = event.getParams();
        if (eventParams.changeType === "LOADED") {
            const propStatus = component.get('v.propertyRecord.PropertyStatus__c');
            if (propStatus !== 'Active') {
                helper.showToast(component, {
                    mode: 'dismissible',
                    title : 'Property is not Active',
                    message : 'Reconfiguration can be done on Active Properties only',
                    type : 'error',
                    duration : 3000
                });
                
                // Close the action panel
                const dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                
            }
        }
    },
	doInit : function(component, event, helper) {      
		helper.getUserAccess(component);
	},
    
    getSelectedSpace : function(component, event, helper){
        var selectedSpaceArea = 0;
        var selectedSpaceList = event.getParams().spaceList
        
        component.set("v.mode", event.getParams().mode)
        component.set("v.selectedSpaceList", selectedSpaceList);
        component.set("v.currentPage", component.get("v.currentPage") + 1);
        
        var page2 = component.find("page-2");
        selectedSpaceArea = helper.getSelectedSpaceArea(selectedSpaceList);
        console.log("selectedSpaceArea : ", selectedSpaceArea)
        page2.set("v.mode", component.get("v.mode"))
        page2.set("v.selectedSpaceArea", selectedSpaceArea)
        page2.set("v.typePicklistValueList", component.get("v.typePicklistValueList"))
    },
    
    goBack : function(component, event, helper){
        component.set("v.currentPage", component.get("v.currentPage") - 1);
    },
    
    confirmCreation : function(component, event, helper){
        var selectedSpaceList = component.get("v.selectedSpaceList")
        var newSpaceList = event.getParams().spaceList;
        var lostSpaceArea = helper.getLostSpace(selectedSpaceList, newSpaceList);
        
        component.set("v.newSpaceList", newSpaceList)
        console.log("newSpaceList : ", newSpaceList)
        
        var lostSpaceExemption = parseFloat($A.get("$Label.c.SpaceReconfig_LostSpaceExemption"));
        
        console.log("lostSpaceExemption-container : ", lostSpaceExemption);
        
        if(lostSpaceArea <= lostSpaceExemption){
            helper.toggleModal(component, lostSpaceArea, "Confirm") 
        } else {
            helper.toggleModal(component, lostSpaceArea, "Lost Space")
        }
    },
    
    saveSpaces : function(component, event, helper){
        var lostSpace = event.getParams().space
        var newSpaceList = component.get("v.newSpaceList");
        var selectedSpaceList = component.get("v.selectedSpaceList")        
        
        console.log("saveSpaces-lostSpace : ", lostSpace)
        
        helper.toggleSpinner(component)
        
        if(!$A.util.isEmpty(lostSpace)){
            //lostSpace.Type__c = "20";
            newSpaceList.push(lostSpace);
        }
        
        helper.saveSpacesHelper(component, selectedSpaceList, newSpaceList);
    }
})