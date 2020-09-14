({
	getRelatedDetails : function(component) {
		let action = component.get("c.getRelatedList");
        
        console.log("opportunity : ", JSON.parse(JSON.stringify(component.get("v.oppRecord"))));
        
        action.setParams({
            "opportunity": component.get("v.oppRecord"),
            "productFamily": "Fees & Charges"
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            let res = response.getReturnValue();
            
            if (state === "SUCCESS" && res.status === "SUCCESS") {
                let returnValue = JSON.parse(res.returnValue);
                
                component.set("v.feesChargesWrapper", returnValue.feesChargesList);
                component.set("v.filteredFeesChargesWrapper", returnValue.feesChargesList);
                
                console.log("returnValue : ", returnValue);
            } else {
                console.log("response.getError() : ", response.getError());
            }
        });
        
        $A.enqueueAction(action);
	},
	
	saveChangesHelper : function(component, feesCharges){
		let action = component.get("c.saveChanges");
        let self = this
        action.setParams({
            "opportunity": component.get("v.oppRecord"),
            feesChargesWrapperJSON : JSON.stringify(feesCharges),
            "productFamily": "Fees & Charges"
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            let res = response.getReturnValue();
            component.set("v.isLoading", false);
            if (state === "SUCCESS" && res.status === "SUCCESS") {
                let returnValue = JSON.parse(res.returnValue);
                
                component.set("v.feesChargesWrapper", returnValue.feesChargesList);
                component.set("v.filteredFeesChargesWrapper", returnValue.feesChargesList);
                component.set("v.feesChargesWrapperTemp", [])
                
                $A.get('e.force:refreshView').fire();
                console.log("returnValue : ", returnValue);
            } else {
                console.log("res.message : ", res.message);
                console.log("response.getError() : ", response.getError());
            }
        });
        
        $A.enqueueAction(action);
	},
	
	createDataTableColumns : function(component){
        let columns = [];
        let isReadOnly = component.get("v.isReadOnly");
        if(isReadOnly) {
            columns = [
                { label: 'Active', fieldName: 'isActive', type: 'boolean',  editable: true},
                { label: 'Item Name', fieldName: 'productName', type: 'text'},
                { label: 'List Price', fieldName: 'listPrice', type: 'currency'},
                { label: 'Total Price', fieldName: 'totalPrice', type: 'currency', editable: true}
            ]
        } else {
            columns = [
                { label: 'Active', fieldName: 'isActive', type: 'boolean',  editable: false},
                { label: 'Item Name', fieldName: 'productName', type: 'text'},
                { label: 'List Price', fieldName: 'listPrice', type: 'currency'},
                { label: 'Total Price', fieldName: 'totalPrice', type: 'currency', editable: false}
            ]
        }
        return columns;
	},
	
	mergeDataChanges : function(feesCharges, draftValues){
		let mergeList = [];
		let fieldsToMerge = [
			"isActive",
			"totalPrice"
		]
		
		let dataMap = this.getDataMap(feesCharges);
		
		for(let i in draftValues){
			let draftValue = draftValues[i]
			let dataTemp = {};
			
			if(dataMap[draftValue.recordId] != undefined){
				dataTemp = dataMap[draftValue.recordId];
			} else {
				dataTemp.recordId = draftValue.recordId
			}
			
			console.log("dataTemp : ", dataTemp)
			
			for(let x in fieldsToMerge){
				let field = fieldsToMerge[x];
				 
				if(draftValue[field] != undefined){
					if(field === "totalPrice"){
						draftValue[field] = parseFloat(draftValue[field]);
					}
					
					dataTemp[field] = draftValue[field];
				}
			}
			mergeList.push(dataTemp);
			
			//dataMap[draftValue.recordId] = dataTemp;
		}
		
		return mergeList;
	},
	
	getDataMap : function(feesCharges){
		var obj = {};
		
		for(let val in feesCharges){
			obj[feesCharges[val].recordId] = feesCharges[val];
		}
		
		return obj;
	},
	verifyUserAccess : function(component) {
        var action = component.get("c.userHasEditAccess");
        action.setParams({
            opportunityId : component.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            if(state === "SUCCESS") {
                if(getReturn){
                    component.set("v.isReadOnly", getReturn);
                }
                component.set("v.columns", this.createDataTableColumns(component));
            } else {
                console.log(getReturn.message);
            }
        });
        $A.enqueueAction(action);
    }
	/*toggleToast : function(type, title, message){
		var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
        	"type": type
            "title": title,
            "message": message
        });
        toastEvent.fire();
	}*/
})