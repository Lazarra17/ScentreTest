({
    getRiskOpportunityClause : function(component){
        let self = this;
        let actionHandler = component.get("c.getDetails");
        
        actionHandler.setParams({
            recordID : component.get("v.recordId"),
            sourceName : "Risktab"
        });
        
        actionHandler.setCallback(this, function(response){
            let res = response.getReturnValue();
            
            if(res.status.toUpperCase() === "SUCCESS"){
                component.set("v.opportunityClauseMaster", JSON.parse(res.returnValue));
                component.set("v.filteredOpportunityClause", JSON.parse(res.returnValue));
                
                console.log("res.returnValue : ", res.returnValue);
                
                self.getEditAccess(component);
            } else {
                console.log("ERROR : ", res.message);
                console.log("ERROR : ", response.getError());
            }
        })
        
        $A.enqueueAction(actionHandler);
    },
    
    updateOppClause : function(component, draftValues){
        var self = this;
        var actionHandler = component.get("c.updateOpportunityClause");
        console.log("draftValues : ", draftValues)
        actionHandler.setParams({
            clauseWrapperJSON : JSON.stringify(draftValues)
        })
        
        actionHandler.setCallback(this, function(response){
            var res = response.getReturnValue();
            component.set("v.isLoading", false);
            
            if(res.status.toUpperCase() === "SUCCESS" ){
                component.set("v.opportunityClauseTemp", []);
                self.getRiskOpportunityClause(component);
            } else {
                console.log("ERROR-UPDATE : ", res.message);
                
                res.message =  self.errorHandler(res.message);
                self.showToast("Error!", res.message, "error");
            }
        })
        
        $A.enqueueAction(actionHandler)
    },
    
    getEditAccess : function(component){
        let self = this;
        let actionHandler = component.get("c.isColumnEditable");
        
        actionHandler.setParams({
            opportunity : component.get("v.oppRecord")
        });
        
        actionHandler.setCallback(this, function(response){
            if(response.getState() === "SUCCESS"){
                self.setTableColumns(component, response.getReturnValue());
            } else {
                self.setTableColumns(componnt, false);
            }
            
            component.set("v.isLoading", false);
        })
        
        $A.enqueueAction(actionHandler);
    },
    
    setTableColumns : function(component, isUpdatable) {
        let columns = [
            {label: "Name", fieldName: "clauseName", type: "text", fixedWidth: 200},
            {label: "Approved", fieldName: "approved", type: "boolean", fixedWidth: 90},
            {label: 'High Risk Clause?', fieldName: 'highRiskClause', type: 'boolean', fixedWidth: 150},
			{label: 'Risk Clause?', fieldName: 'riskApplies', type: 'boolean', fixedWidth: 115},
            {label: "Reason", fieldName: "reasonRecommendation", type: "text", editable: isUpdatable,}
        ]
        
        console.log('columns : ', columns);
        
        component.set("v.columns", columns);
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
    
    showToast : function(title, message, type){
        var toast = $A.get("e.force:showToast");
        
        toast.setParams({
            "title": title,
            "message": message,
            "type" : type
        });
        
        toast.fire();
    }
})