({
    doInit : function(cmp){
        var action = cmp.get("c.getFieldsToShow");
        action.setParams({
            recordId : cmp.get("v.recordId") 
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            var sectionVsFieldsMap = [];
            if(state == 'SUCCESS'){
                
                var returnedMap = response.getReturnValue();
                for(var key in returnedMap){
                    sectionVsFieldsMap.push({value:returnedMap[key], key: key})
                }
                cmp.set("v.fieldsToShow", sectionVsFieldsMap);
                cmp.set("v.showSpinner", false);
            }
        });
        
        var action1 = cmp.get("c.getCaseRecordType");
        action1.setCallback(this, function(response){
            var state = response.getState();
            
            if(state == 'SUCCESS'){
                var returnData = response.getReturnValue();
                cmp.set("v.caseRecordTypeId", returnData); 
            }
        });
                
        var action3 = cmp.get("c.isCaseLocked");
        action3.setParams({
            caseId : cmp.get("v.recordId") 
        });
        action3.setCallback(this, function(response){
            var state = response.getState();            
            if(state == 'SUCCESS'){
                var caseLocked = response.getReturnValue();
                
                cmp.set("v.caseLocked", caseLocked);
            }
        });
        
        $A.enqueueAction(action);
        $A.enqueueAction(action1);
        $A.enqueueAction(action3);
    },
    
    toggleSection : function(cmp, event){
        var cmpTarget = cmp.find("section1");
        $A.util.toggleClass(cmpTarget, 'slds-is-open');
        
        var iconName = cmp.get("v.section1iconName");
        if(iconName === "utility:chevrondown"){
            cmp.set("v.section1iconName", "utility:chevronright");
        }else{
            cmp.set("v.section1iconName", "utility:chevrondown");
        }
    },
    
    changeMode : function(cmp, event){
        cmp.set("v.showSpinner", true);
        cmp.set("v.isViewModeParent", false);
        
    },
    
    handleSave : function(cmp, event){
        cmp.set("v.showSpinner", true); 
        
        var isReqFieldBlank;
        
        var isCaseLocked = cmp.get("v.caseLocked");
        var fields = event.getParam("fields");
        console.log('isCaseLocked 1: '+isCaseLocked);
        /*if(isCaseLocked){
            console.log('isCaseLocked 2: '+isCaseLocked);
            let toast = cmp.find("toastRent");
            toast.set("v.title", "Failed");
            toast.set("v.state", "error!");
            toast.set("v.message", "This recod is locked. If you need to edit it, contact your admin.");
            toast.set("v.duration", 9000);
            
            toast.showToast();
            return;
        }else */if(!isReqFieldBlank){
            console.log('isCaseLocked 3: '+isCaseLocked);
            cmp.set("v.showSpinner", true);
            
            event.preventDefault();
            
            fields["Type"] = cmp.get("v.typeValue");
            fields["SubType__c"] = cmp.get("v.subtypeValue");
            
            cmp.find("caseForm").submit(fields);
        	//cmp.set("v.showSpinner", false); 
        }
    },
    
    handleError : function(cmp, event){
        var errorsOccured = event.getParam("error");        
        var returnedDetails = event.getParams("detail");
		
        if(errorsOccured.status == '400'){
            var errorMessage = returnedDetails.detail;
            let toast = cmp.find("toastRent");
            toast.set("v.title", "Failed");
            toast.set("v.state", "error");
            toast.set("v.message", errorMessage);
            toast.set("v.duration", 9000);
            
            toast.showToast();
            cmp.set("v.showSpinner", false);
        }
    },
    
    handleSuccess : function(cmp, event){
        let toast = cmp.find("toastRent");
            
        toast.set("v.title", "Success");
        toast.set("v.state", "success");
        toast.set("v.message", 'Data saved successfully');
        toast.set("v.duration", 9000);
        
        toast.showToast();
        
        $A.get('e.force:refreshView').fire();
        cmp.set("v.isViewModeParent", true);
        cmp.set("v.showSpinner", false);    
    },
    
    handleReset : function(cmp, event){
        cmp.set("v.isViewModeParent", true);
    },
    
    handleOnLoad : function(cmp, event){
    	cmp.set("v.showSpinner", false);
	},
    
    setTypeValues : function(cmp, event){
        var newTypeValue = event.getParam("typeValue");
        var newSubtypeValue = event.getParam("subtypeValue");
        
        cmp.set("v.typeValue", newTypeValue);
        cmp.set("v.subtypeValue", newSubtypeValue);
    },
    
    showToast : function(component, type, title, message){
        let toast = component.find("toastRent");
        
        toast.set("v.title", title);
        toast.set("v.state", type);
        toast.set("v.message", message);
        
        toast.showToast();
    }
})