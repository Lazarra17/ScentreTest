({
	fetchSpaceDetails : function(component, event) {
		var action = component.get("c.getspacedetails");
        action.setParams ({spaceId : component.get("v.recordId")});
        action.setCallback(this, function(response) {
            var res = response.getReturnValue();
            var wrapperdetails=JSON.parse(res.returnValue); 
            component.find("caseRecordCreator").getNewRecord(
                "Case", 
                wrapperdetails.recordTypeId,
                false,    
                $A.getCallback(function() {
                    var rec = component.get("v.newtargetcaseRecord");
                    var error = component.get("v.newContactError");
                    component.set("v.newcaseRecord.Subject",wrapperdetails.subject);
                    component.set("v.newcaseRecord.Status","Scheduled");
                    component.set("v.newcaseRecord.Priority","High");
                    component.set("v.newcaseRecord.DueDate__c",wrapperdetails.dueDate);
                    
                    if(wrapperdetails.spaceRecord.CurrentLease__c!==null&&wrapperdetails.spaceRecord.CurrentLease__c!==undefined){
                        component.set("v.newcaseRecord.Contract__c",wrapperdetails.spaceRecord.CurrentLease__c);
                        component.set("v.newcaseRecord.AccountId",wrapperdetails.spaceRecord.CurrentLease__r.Account__c);
                        component.set("v.newcaseRecord.Opportunity__c",wrapperdetails.spaceRecord.CurrentLease__r.Opportunity__c);
                    }
                    
                    component.set("v.newcaseRecord.Space__c",wrapperdetails.spaceRecord.Id);
                    
                    component.set("v.newcaseRecord.OwnerId",wrapperdetails.ownerId);                    
                })
            );
            
        });
        $A.enqueueAction(action); 
	}
})