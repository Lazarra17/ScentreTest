({
	getRelatedDetails : function(component) {
		let self = this;
		let action = component.get("c.getRelatedList");
        
        console.log("opportunity : ", JSON.parse(JSON.stringify(component.get("v.oppRecord"))));
        
        console.log(JSON.stringify(component.get("v.oppRecord")));
        
        action.setParams({
            "opportunity": component.get("v.oppRecord"),
            "productFamily": "Capital"
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            let res = response.getReturnValue();
            
            if (state === "SUCCESS" && res.status === "SUCCESS") {
                let returnValue = JSON.parse(res.returnValue);
                
                component.set("v.feesChargesWrapper", returnValue.feesChargesList);
                component.set("v.filteredFeesChargesWrapper", returnValue.feesChargesList);
                
                console.log("returnValue : ", returnValue);
                
                if($A.util.isEmpty(component.get("v.columns"))){
                	component.set("v.columns", self.createDataTableColumns(returnValue.isTotalPriceEditable));
                }
                
                self.calculateHelper(component)
            } else {
                console.log("response.getError() : ", response.getError());
            }
            component.set("v.isLoading", false);
        });
        
        $A.enqueueAction(action);
	},
	
	saveChangesHelper : function(component, feesCharges){
		let action = component.get("c.saveChanges");
        let self = this
        action.setParams({
            "opportunity": component.get("v.oppRecord"),
            feesChargesWrapperJSON : JSON.stringify(feesCharges),
            "productFamily": "Capital"
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            let res = response.getReturnValue();
            
            if (state === "SUCCESS" && res.status === "SUCCESS") {
                let returnValue = JSON.parse(res.returnValue);
                
                component.set("v.feesChargesWrapper", returnValue.feesChargesList);
                component.set("v.filteredFeesChargesWrapper", returnValue.feesChargesList);
                component.set("v.feesChargesWrapperTemp", [])
                
                console.log("returnValue : ", returnValue);
                $A.get('e.force:refreshView').fire();
                
                self.calculateHelper(component)
            } else {
                console.log("res.message : ", res.message);
                console.log("response.getError() : ", response.getError());
                
                let errorMessage = self.errorHandler(res.message);
                //self.showToast("Error!", errorMessage, "error");
				self.showToast(component, "error", "Error!", errorMessage);                
                console.log("errorMessage : ", errorMessage);
            }
            
            component.set("v.isLoading", false);
        });
        
        $A.enqueueAction(action);
	},
	
	createDataTableColumns : function(isTotalPriceEditable){
		let columns = [
			{ label: "Active", fieldName: "isActive", type: "boolean",  editable: isTotalPriceEditable},
            { label: "Item Name", fieldName: "productName", type: "text"},
            { label: "Total Price", fieldName: "totalPrice", type: "currency", editable: isTotalPriceEditable}
        ]
        
        console.log('columns : ', columns);
        
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
			console.log('dataTemp' , dataTemp);
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
	
	validateRequiredFields : function(requiredFieldList,  capitalList){
		let returnValue = {};
		
		returnValue.isValid = true;
		returnValue.errorObj = {};
		returnValue.errorObj.fields = [];
		returnValue.errorObj.message = [];
		
		for(let capital of capitalList){
			if(capital.isActive){
				for(let field of requiredFieldList){
					console.log("capital[field] : ", capital[field]);
					if(!capital[field]){
						returnValue.errorObj.title = "Required Field"
						returnValue.errorObj.fields.push(field);
						returnValue.errorObj.message.push("This is a required field.");
						
						returnValue.isValid = false;
					}
				}
			}
		}
		
		return returnValue;
	},
	
	calculateHelper : function(component){
    	let opportunity = component.get("v.oppRecord");
    	let totalCapitalCost = this.calculateTotalCapitalCost(opportunity);
    	let variance = this.calculateVariance(opportunity, totalCapitalCost)
    	
    	component.set("v.variance", variance);
    	component.set("v.totalCapitalCost", totalCapitalCost);
    },
	
	calculateTotalCapitalCost : function(opportunity){
		let totalDCCost = (opportunity.TotalDCCost__c) ? opportunity.TotalDCCost__c : 0;
		let totalLessor = (opportunity.TotalLessorWorksCost__c) ? opportunity.TotalLessorWorksCost__c : 0;
		let totalFitout = (opportunity.TotalFitoutContribution__c) ? opportunity.TotalFitoutContribution__c : 0;
		
		return totalDCCost + totalLessor + totalFitout
	},
	
	calculateVariance : function(opportunity, totalCapitalCost){
		let totalCapCostTemp = (totalCapitalCost) ? totalCapitalCost : 0;
		let spaceLatestBudgetedCapital = (opportunity.Space__c && opportunity.Space__r.LatestBudgetedCapital__c) ? opportunity.Space__r.LatestBudgetedCapital__c : 0;
	
		return totalCapCostTemp - spaceLatestBudgetedCapital
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
    },
	
	//throwTableError : function(component, rowErrorTitle, rowErrorMessages, rowErrorFields){
	throwTableError : function(component){	
		component.set('v.tableErrors', {
            table: {
                title: "Required Fields",
                messages: [
                    "Please fill all Total Price of selected Product"
                ]
            }
        });
	},
	
	/*showToast : function(title, message, type){
		var toast = $A.get("e.force:showToast");
		
        toast.setParams({
            "title": title,
            "message": message,
            "type" : type
        });
        
        toast.fire();
	},*/
	showToast : function(component, type, title, message){
        var toast = component.find("toast");
        
        toast.set("v.title", title);
        toast.set("v.state", type);
        toast.set("v.message", message);
        
        toast.showToast();
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
                } else {
                    component.set("v.columns", [
                        { label: "Active", fieldName: "isActive", type: "boolean",  editable: false},
                        { label: "Item Name", fieldName: "productName", type: "text"},
                        { label: "Total Price", fieldName: "totalPrice", type: "currency", editable: false}
                    ]);
                }
            } else {
                console.log(getReturn.message);
            }
        });
        $A.enqueueAction(action);
    }
})