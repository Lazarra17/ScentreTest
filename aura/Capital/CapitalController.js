({
    getTableRecords : function(component, event, helper) {
        helper.getRelatedDetails(component);
        helper.verifyUserAccess(component);
    },
    
    catchSearchResult : function(component, event, helper){
        let searchResult = event.getParams().searchResult
        component.set("v.filteredFeesChargesWrapper", searchResult)
    },
    
    calculate : function(component, event, helper){
    	helper.calculateHelper(component)
    },
    
    handleSave : function(component, event, helper){
    	let draftValues = component.get("v.feesChargesWrapperTemp");
		let feesChargesList = component.get("v.feesChargesWrapper");
		
		let requiredFieldList = [
			"totalPrice"
		];
		
		component.set("v.tableErrors", {});
		component.set("v.isLoading", true);
		var returnValue = helper.validateRequiredFields(requiredFieldList, draftValues)
		
		console.log("draftValues : ", draftValues);
		console.log("returnValue : ", returnValue);
		
		if(returnValue.isValid){
			feesChargesList = helper.mergeDataChanges(feesChargesList, draftValues);
			helper.saveChangesHelper(component, feesChargesList);
		} else {
			component.set("v.isLoading", false);
			//helper.showToast("Required Fields", "Please fill all Total Price of selected Product", "error");
            helper.showToast(component, "error", "Required Fields", "Please fill all Total Price of selected Product.");
			helper.throwTableError(component);
		}
		//component.set("v.feesChargesWrapper", feesChargesList);
		console.log("feesChargesList : ", feesChargesList)
    },
    
    handleEditCell: function(component, event, helper) {
    	let draftValues = event.getParam("draftValues");    	
		let feesChargesTemp = component.get("v.feesChargesWrapperTemp");
		
		let dataMap = helper.getDataMap(feesChargesTemp);
		let updateFeesCharges = helper.mergeDataChanges(feesChargesTemp, draftValues);
		
		for(let x in updateFeesCharges){
			let temp = updateFeesCharges[x];
			dataMap[temp.recordId] = temp;
		}
		
		component.set("v.feesChargesWrapperTemp", Object.values(dataMap));
		
		console.log("Object.values(dataMap) : ", Object.values(dataMap))
	},
	
	handleCancel : function(component, event, helper){
		component.set("v.feesChargesWrapperTemp", [])
	}
})