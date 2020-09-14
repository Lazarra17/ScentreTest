({
	getColumns : function(component){
        component.set("v.columns", [
            {label: "Opportunity name", fieldName: "Name", type: "text"},
            {label: "Proposed Rent Date", fieldName: "ProposedRentCommencementDate__c", type: "date", cellAttributes: { alignment: 'center' }}
        ]);
    },
    
    filterOpportunityHelper : function(component){
        let filteredOppList = [];
        let rentDateRange = component.get("v.rentDateRange")
        let oppMasterList = component.get("v.opportunityMasterList");
        
        if(this.checkDates(component)){
            for(let opp of oppMasterList){
                if(!$A.util.isEmpty(rentDateRange.fromDate)){
                    if(opp.ProposedRentCommencementDate__c >= rentDateRange.fromDate){
                        if(!$A.util.isEmpty(rentDateRange.toDate)){
                            if(opp.ProposedRentCommencementDate__c <= rentDateRange.toDate){
                                filteredOppList.push(opp);
                            }
                        } else {
                            filteredOppList.push(opp);
                        }
                    }
                } else if(!$A.util.isEmpty(rentDateRange.toDate && opp.ProposedRentCommencementDate__c <= rentDateRange.toDate)){
                    filteredOppList.push(opp);
                }
            }
            
            component.set("v.filterOpportunityList", filteredOppList);
            
            if($A.util.isEmpty(filteredOppList)){
                this.showToast(component, "warning", "No Opportunities", "No Opportunities for refresh");
            }
        } else {
            component.set("v.filterOpportunityList", []);
        }
        
        this.toggleSpinner(component, "hide");
    },
    
    checkDates : function(component){
        let isValid = true;
        let rentDateRange = component.get("v.rentDateRange")
        
        if(!$A.util.isEmpty(rentDateRange)){
            if(!$A.util.isEmpty(rentDateRange.fromDate) && !$A.util.isEmpty(rentDateRange.toDate) 
                      && rentDateRange.fromDate > rentDateRange.toDate){
                isValid = false;
                this.showToast(component, "error", "Error!", "Please check date range")
            } else if($A.util.isEmpty(rentDateRange.fromDate) && $A.util.isEmpty(rentDateRange.toDate)){
                isValid = false;
            }
        }
                
        return isValid;
    },
    
    getOpportunityHelper : function(component) {
        let self = this;
		let propertyId = component.get("v.recordId")
        let actionHandler = component.get("c.getOpportunities");
        
        actionHandler.setParams({
            propertyId : propertyId
        })
        
        actionHandler.setCallback(this, function(response){
            let res = response.getReturnValue();
            
            if(res.status === 'SUCCESS'){
                //component.set("v.filterOpportunityList", JSON.parse(res.returnValue));
                component.set("v.opportunityMasterList", JSON.parse(res.returnValue));
            }
            
            self.toggleSpinner(component, "hide");
        })
        
        $A.enqueueAction(actionHandler);
	},
    
    refreshOppLineItemHelper : function(component){
        let self = this;
        let opportunityList = component.get("v.filterOpportunityList");
        let actionHandler = component.get("c.refreshOutgoings");
        
        actionHandler.setParams({
            opportunityListJSON : JSON.stringify(opportunityList)
        })
        
        actionHandler.setCallback(this, function(response){
            console.log(response.getState());
			let batchId;
            
            if(response.getState() === "SUCCESS"){
				batchId = response.getReturnValue();
				self.isBatchCompleteHelper(component, batchId);
            }
        })
        
        $A.enqueueAction(actionHandler)
    },
	
	isBatchCompleteHelper : function(component, batchId){
		let self = this;
		let actionHandler = component.get("c.isBatchComplete");
        
        actionHandler.setParams({
            batchId : batchId
        })
        
        actionHandler.setCallback(this, function(response){
            console.log(response.getState());
            
            if(response.getState() === "SUCCESS"){
				if(response.getReturnValue()){
					self.toggleSpinner(component, "hide");
					self.showToast(component, "success", "Success!", "Opportuny Products successfully refreshed!");
				} else {
					self.isBatchCompleteHelper(component, batchId);
				}
            }
        })
        
        $A.enqueueAction(actionHandler)
	},
    
    showToast : function(component, state, title, message){
        let toast = component.find("toast");
        
        toast.set("v.state", state);
        toast.set("v.title", title);
        toast.set("v.message", message);
        
        toast.showToast();
    },
    
    toggleSpinner : function(component, action){
        let spinner = component.find("spinner");
        
        if(action === "show"){
            $A.util.removeClass(spinner, "slds-hide")
        } else if(action === "hide"){
            $A.util.addClass(spinner, "slds-hide")
        }
    }
})