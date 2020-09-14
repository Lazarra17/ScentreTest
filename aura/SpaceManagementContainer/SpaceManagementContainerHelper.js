({
	getSpacesHelper : function(component) {
		var actionHandler = component.get("c.getSpaces");
        
        actionHandler.setParams({
            propertyId : component.get("v.recordId")
        })
        
        actionHandler.setCallback(this, function(response){
            var res = response.getReturnValue();
            
            if(res.status === "SUCCESS"){
                var spaceWrap = JSON.parse(res.returnValue);
                var page1 = component.find("page-1");
                
                page1.set("v.tableColumns", this.getTableColumns(component));
                page1.set("v.spaceList", spaceWrap.spaceList);
                page1.set("v.filteredSpaceList", JSON.parse(JSON.stringify(spaceWrap.spaceList)));
                
                console.log("spaceList : ", spaceWrap.spaceList);
                component.set("v.spaceList", spaceWrap.spaceList);
                component.set("v.typePicklistValueList", spaceWrap.typePicklistValueList);
            } else {
                console.log("ERROR : ", res.message);
            }
            
            this.toggleSpinner(component)
        })
        
        $A.enqueueAction(actionHandler);
	},
    
    getUserAccess : function(component){
        let self = this;
        let actionHandler = component.get("c.hasUserAccess");
        
        actionHandler.setCallback(this, function(response){
            if(response.getReturnValue()){
                self.getSpacesHelper(component);
                component.set("v.hasUserAccess", true)
            } else {
                self.toggleSpinner(component)
                component.set("v.hasUserAccess", false)
                self.showToast(component, "error", "No Access", $A.get("$Label.c.SpaceManagementUserAccessErrorMessage"))
            }
        })
        
        $A.enqueueAction(actionHandler)
    },
    
    saveSpacesHelper : function(component, selectedSpaceList, newSpaceList){        
        var actionHandler = component.get("c.createSpaces")
        
        actionHandler.setParams({
        	property : component.get("v.propertyRecord"),
            sourceSpaceListJSON : JSON.stringify(component.get("v.selectedSpaceList")),
            newSpaceListJSON : JSON.stringify(newSpaceList),
            mode : component.get("v.mode")
            
        })
        
        actionHandler.setCallback(this, function(response){
            var res = response.getReturnValue();
            this.toggleSpinner(component)
            console.log("response.getError() : ", response.getError())
            
            if(res.status == 'SUCCESS'){
                var spaceWrapper = JSON.parse(res.returnValue)
                
                component.set("v.spaceWrapper", spaceWrapper)
                component.set("v.currentPage", component.get("v.currentPage") + 1)
                var page3 = component.find("page-3")
                page3.set("v.spaceWrapper", spaceWrapper);
                console.log("spaceWrapper : ", spaceWrapper)
            } else if(res.status == 'FAILED'){
                var errorMessage = this.errorHandler(res.message);
                this.showToast(component, 'error', 'Error!', errorMessage);
                console.log("ERROR : ", res.message);
            }
        });
        
        $A.enqueueAction(actionHandler);
    },
    
    getTableColumns : function(component){
        var tableColumns = [
            {label: "Space Name", fieldName: "Name", type: "String", sortable: false},
            {label: "Type", fieldName: "TypeLabel", type: "String", sortable: false},
            {label: "Area", fieldName: "RentableArea__c", type: "number", typeAttributes: { minimumSignificantDigits: '3'}},
            {label: "Status", fieldName: "OccupancyStatus__c", type: "String", sortable: false}
        ];
        
        return tableColumns;
    },
    
    getSelectedSpaceArea : function(selectedSpaceList){
        var area = 0;
        
        for(var counter in selectedSpaceList){
            console.log("selectedSpaceList[counter].RentableArea__c : ", selectedSpaceList[counter].RentableArea__c)
            area += selectedSpaceList[counter].RentableArea__c
        }
        
        return area
    },
    
    getLostSpace : function(selectedSpaceList, newSpaceList){
        var newSpaceArea = 0.00;
        var lostSpaceArea = 0.00;
        var selectedSpaceArea = 0.00;
        
        for(var counter in selectedSpaceList){
            selectedSpaceArea += selectedSpaceList[counter].RentableArea__c;
        }
        
        for(var counter in newSpaceList){
            newSpaceArea += parseFloat(newSpaceList[counter].RentableArea__c);
        }
        
        if(selectedSpaceArea > newSpaceArea){
            lostSpaceArea = selectedSpaceArea - newSpaceArea;
        }
        
        console.log("newSpaceArea : ", newSpaceArea);
        console.log("lostSpaceArea : ", lostSpaceArea);
        console.log("selectedSpaceArea : ", selectedSpaceArea);
        
        return lostSpaceArea;
    },
    
    toggleModal : function(component, lostSpaceArea, modalMode){
        var modalCmp = component.find("custom-modal");
       	var modalBox = modalCmp.find("modalbox")
        var modalBackdrop = modalCmp.find("modalBackdrop")
        
        if(modalMode == "Lost Space"){
        	modalCmp.newLostSpace(lostSpaceArea)    
        }
        
        modalCmp.set("v.modalMode", modalMode)
        
        $A.util.removeClass(modalBox, "slds-fade-in-close") 
        $A.util.addClass(modalBox, "slds-fade-in-open")
        $A.util.removeClass(modalBackdrop, "slds-backdrop--close") 
        $A.util.addClass(modalBackdrop, "slds-backdrop--open")
    },
    
    showToast : function(component, state, title, message){
        var eventHandler = $A.get("e.c:ToastEvent")
        
        eventHandler.setParams({
            state : state,
            title : title,
            message : message
        })
        
        eventHandler.fire()
    },
    
    showToast : function(component, options) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams(options);
        toastEvent.fire();
    },    
    
    toggleSpinner : function(component){
    	var spinner = component.find("spinner")        
		$A.util.toggleClass(spinner, "slds-hide");
    },
    
    errorHandler : function(message) {
        var idxStack = message.indexOf("STACK TRACE:");
        var msg = idxStack != -1 ? message.substring(0, idxStack-1) : message;
        var idx = msg.indexOf("first error:");
        var errMsg = idx != -1 ? msg.substring(idx + 13, msg.length) : 'Something went wrong. Please contact your System Administrator.';
        
        while(errMsg.includes('&quot;')){
            errMsg = errMsg.replace('&quot;', '');
        }
        
        if(errMsg.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
            errMsg = errMsg.replace('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', '');
            var messages = errMsg.split(':');
            var valMsg = '';
            for(var i=0; i< messages.length - 1; i++){
                valMsg = valMsg + messages[i];
            }
            errMsg = valMsg;
        }
        
        return errMsg;
    }
})