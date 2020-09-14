({
	doInit : function(component, event, helper) {
		var recId = component.get("v.recordId");
        var action = component.get("c.getAvgRentByCluster");
        var actionSQM = component.get("c.getAvgSQMRentByCluster");
        var category = component.get("c.getAvgRentByCategory");
               action.setStorable();
        		actionSQM.setStorable();
        		category.setStorable();
        		action.setParams({
    			recordId: recId
         });
        actionSQM.setParams({
    			recordId: recId
         });
        action.setCallback(this, function(response){
            var res = response.getReturnValue();
            console.log('res', res);
            component.set("v.SimilarAccountsRentCluster", res);
            
        });
        actionSQM.setCallback(this, function(response){
            var resSQM = response.getReturnValue();
            console.log('res', resSQM);
            component.set("v.SimilarAccountsSQMRentCluster", resSQM);
            
        });
        $A.enqueueAction(action);
         $A.enqueueAction(actionSQM);
        }
})