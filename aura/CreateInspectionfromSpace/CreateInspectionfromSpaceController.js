({
    doInit: function(component, event, helper) {
        
        //added below code (action) to implement RPP-10876
        var action = component.get("c.isIRCaseRaisedEarlier");
        
        action.setParams ({
            spaceId : component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            var res = response.getReturnValue();
            if(res == true){
                component.set("v.newIRCondition",true);
            }else{
                helper.fetchSpaceDetails(component, event);
                component.set("v.newIRConditionCheck",true);
            }
        });
        $A.enqueueAction(action);
    },
    
    
    
    SaveinspectionRecord: function(component, event, helper) {
        component.find("caseRecordCreator").saveRecord(function(saveResult) {
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                //added below code to implement RPP-10876
                debugger;
                component.set("v.caseId", saveResult.recordId);
                var name = component.get("v.optionSelect");
                console.log(name);
                console.log(component.find("options"));
                var selectedReasonOption =  component.get("v.selectedReason");
                console.log(selectedReasonOption);
		        if(selectedReasonOption ==='Other'){
                //var check = component.get("v.showText");
                //if(check == true){
                	//console.log(component.find("enterText"));
                    var text = component.get("v.otherReasonDescription");
                    console.log(text);
                }
                var action = component.get("c.getselectOptions");
                action.setParams ({
                    "caseId": component.get("v.caseId"),
                    "reason": name, 
                    "description": text
                    
                });
                
                action.setCallback(this, function(a) {
                    var state = a.getState();
                    if (state === "SUCCESS") {
                        
                    }else{
                        console.log("Failed");
                    }
                });
                $A.enqueueAction(action);
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Saved",
                    "message": "Inspection Report is created.",
                    "type" : "success"
                });
                $A.get("e.force:closeQuickAction").fire();
                resultsToast.fire();
            }else if (saveResult.state === "ERROR") {
                console.log('Problem saving Inspection, error: ' + JSON.stringify(saveResult.error));
                var errMsg = "";
                for (var i = 0; i < saveResult.error.length; i++) {
                    errMsg += saveResult.error[i].message + "\n";
                    console.log('ERROR MESSAGE: ' + errMsg);
                }
                component.set("v.newcaseError", errMsg);
            }
        });
        $A.get('e.force:refreshView').fire();
        
        
        
    },
    
    //added below function to implement RPP-10876
    closeModel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    
    //added below function to implement RPP-10876
    yesCreate: function(component, event, helper) {
        component.set("v.newIRCondition", false);
        component.set("v.reasonPicklist", true);
    },
    
    //added below function to implement RPP-10876
    onReasonSelection: function(component, event, helper) {
        var name = component.find("options").get("v.value");
        component.set("v.selectedReason", name);
        if(name === 'Other'){
            $A.util.removeClass(component.find("reasonTextBox"), "slds-hide");
            $A.util.addClass(component.find("reasonTextBox"), "slds-show");
            //component.set("v.showText","slds-show");
        }else{
            $A.util.removeClass(component.find("reasonTextBox"), "slds-show");
            $A.util.addClass(component.find("reasonTextBox"), "slds-hide");
            $A.util.removeClass(component.find("otherReasonErrorMsg"), "slds-show");
            $A.util.addClass(component.find("otherReasonErrorMsg"), "slds-hide");
            //component.set("v.showText","slds-hide");
            //component.set("v.showMsg", "slds-hide");
        }
    },
    
    //added below function to implement RPP-10876
    okCreate:function(component, event, helper) {
        var name =  component.find("options").get("v.value");
        var enterdText= component.find("enterText").get("v.value");
        
        if(name == '' || name == null || name == undefined){
            $A.util.removeClass(component.find("reasonErrorMsg"), "slds-hide");
            $A.util.addClass(component.find("reasonErrorMsg"), "slds-show");
            
        }else if(name ==='Other'){
            if(enterdText.trim() == "" || enterdText === null || enterdText == undefined){
                component.set("v.reasonPicklist", true);  
                component.set("v.newIRConditionCheck", false);
                //component.set("v.showMsg", "slds-show");
                $A.util.removeClass(component.find("otherReasonErrorMsg"), "slds-hide");
            	$A.util.addClass(component.find("otherReasonErrorMsg"), "slds-show");
				
            }else{
                component.set("v.optionSelect", name);
                //component.set("v.showMsg", "slds-hide");
                //component.set("v.showText","slds-hide");
                $A.util.removeClass(component.find("reasonTextBox"), "slds-show");
                $A.util.addClass(component.find("reasonTextBox"), "slds-hide");
                $A.util.removeClass(component.find("otherReasonErrorMsg"), "slds-show");
                $A.util.addClass(component.find("otherReasonErrorMsg"), "slds-hide");
                component.set("v.enterTextSelect",enterdText );
                component.set("v.reasonPicklist", false);  
                component.set("v.newIRConditionCheck", true);
                component.set("v.otherReasonDescription", enterdText);
                helper.fetchSpaceDetails(component, event);
            }
        }
        else{
            component.set("v.optionSelect", name);
            //component.set("v.showMsg", "slds-hide");
            //component.set("v.showText","slds-hide");
            $A.util.removeClass(component.find("reasonTextBox"), "slds-show");
            $A.util.addClass(component.find("reasonTextBox"), "slds-hide");
            $A.util.removeClass(component.find("otherReasonErrorMsg"), "slds-show");
            $A.util.addClass(component.find("otherReasonErrorMsg"), "slds-hide");
            component.set("v.enterTextSelect",enterdText );
            component.set("v.reasonPicklist", false);  
            component.set("v.newIRConditionCheck", true);
            component.set("v.otherReasonDescription", enterdText);
            helper.fetchSpaceDetails(component, event);
        }
    },
    
    
    //added below function to implement RPP-10876
    closeMode:function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})