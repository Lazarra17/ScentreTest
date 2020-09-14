({
    getPicklistValues : function(component, event, helper){
        var action = component.get("c.getPicklistValues");
        action.setCallback(this, function(response) {
            console.log('before1st==> ' + response);
            if (response.getState() === "SUCCESS") {
                //console.log(response.getReturnValue());
                var ss = response.getReturnValue().returnValue;
                var respo = JSON.parse(response.getReturnValue().returnValue);
                var stagePicklistValues = respo.opportunityStages;//response.getReturnValue().opportunityStages;
                var reasonPicklistValues = respo.reasonPicklist;//response.getReturnValue().reasonPicklist;
                var stagePicklist = []; 
                var reasonPicklist = [];
                console.log(stagePicklistValues);
                if (stagePicklistValues != undefined) {
                    stagePicklist.push({
                        label: "--- None ---",
                        value: ""
                    }); 
                    for (var i = 0; i < stagePicklistValues.length; i++) {
                        stagePicklist.push({
                            label: stagePicklistValues[i],
                            value: stagePicklistValues[i]
                        });
                    }
                }
                if (reasonPicklistValues != undefined) {
                    reasonPicklist.push({
                        label: "--- None ---",
                        value: ""
                    });   
                    for (var i = 0; i < reasonPicklistValues.length; i++) {
                        reasonPicklist.push({
                            label: reasonPicklistValues[i],
                            value: reasonPicklistValues[i]
                        });
                    }
                }
                
                
                console.log("STAGE NAME " + stagePicklist);
                component.set("v.stageOptions", stagePicklist);
                
                console.log("REASON FOR CLOSURE " + reasonPicklist);
                component.set("v.reasonOptions", reasonPicklist);
                
            }
        });
        $A.enqueueAction(action);
    }, 
    updateOpptyRecordTest : function(component, event, helper) {
       event.preventDefault();
       
       const eventFields = event.getParam("fields");
       component.set('v.showSpinner', true);
       const action = component.get('c.unlockOpportunityRec');
       
       var stagePicklist = component.find('StageName').get('v.value');
       action.setParams({
           opportunityId : component.get('v.recordId'),
           stageName : stagePicklist
           
       });
       
       action.setCallback(this, function(response) {
           
           const state = response.getState();
           const apexReturnValue = JSON.parse(response.getReturnValue().returnValue);
           if (state === 'SUCCESS') {
               component.set('v.isLocked', apexReturnValue.lockedOpp);
               component.find('recordEditorForm').submit(eventFields);
               
           } else {
               helper.errorMessage();
           }
       });
       $A.enqueueAction(action);
   },
    updateOpptyRecord: function(component, event, helper){
        var action = component.get("c.unlockOpportunityRec");
        var stagePicklist = component.find('StageName').get('v.value');
        action.setParams({
            opportunityId : component.get('v.recordId'),
            stageName : stagePicklist
            
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log(response.getReturnValue());
            //var getReturn = response.getReturnValue().isUnlocked;
            //var respo = JSON.parse(response.getReturnValue().returnValue);
            //console.log('Test=> ' +respo);
            console.log("Helper.state: "+state);
            if(state === "SUCCESS"){
                //if(respo.isUnlocked){
                    console.log("Unlocked record");
                
                component.find("recordEditor").saveRecord($A.getCallback(function(saveResult) {
                    	console.log("saveResult.state: "+saveResult.state);
                        if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                            
                            console.log("Save completed successfully.");
                            helper.lockOpportunityRecord(component, event, helper);
                        } else if (saveResult.state === "INCOMPLETE") {
                            console.log("User is offline, device doesn't support drafts.");
                        } else if (saveResult.state === "ERROR") {
                            console.log('Problem saving record, error: ' + 
                                        JSON.stringify(saveResult.error));
                        } else {
                            console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
                        }
                    })); 
                
                /*   
                window.setTimeout(
                        $A.getCallback(function() {
                            helper.lockOpportunityRecord(component, event, helper);
                        }), 2000
                    );
                    
                   */ 
                                
               // }
            } else {
                console.log('Show error here');
           }
            
        });
        $A.enqueueAction(action);
        
    },
    lockOpportunityRecord: function(component, event, helper){
        //alert(component.get('v.recordId'));
        var action = component.get("c.lockOpportunity");
        
        action.setParams({
            oppId : component.get('v.recordId'),
            
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            //var returnVal = response.getReturnValue().lockedOpp;
            if(state === "SUCCESS"){
                $A.get('e.force:refreshView').fire();
                console.log('Locked Opportunity');
                component.set("v.showSpinner", false);
                
            } else {
                console.log('Show error toast here');
            }
            
        });
        $A.enqueueAction(action);
        
    }
    
})