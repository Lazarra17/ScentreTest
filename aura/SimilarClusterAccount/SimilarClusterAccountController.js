({
	doInit : function(component, event, helper) {
		var recId = component.get("v.recordId");
        var action = component.get("c.getSimilarAccountsByCluster");
        var category = component.get("c.getSimilarAccountsByCategory");
               action.setStorable();
        		category.setStorable();
        action.setParams({
    			recordId: recId
         });
        action.setCallback(this, function(response){
            var res = response.getReturnValue();
            console.log('res', res);
            component.set("v.SimilarAccountsCluster", res);
            
        });
        $A.enqueueAction(action);
        //Accounts by Category
        category.setParams({
    			recordId: recId
         });
        category.setCallback(this, function(response){
            var resc = response.getReturnValue();
            console.log('resc', resc);
            component.set("v.SimilarAccountsCategory", resc);
            
        });
        $A.enqueueAction(category);
 
    },
    
    navToRecord : function (component, event, helper) {
    var selectedItem = event.currentTarget;
    var recId = selectedItem.dataset.record;
    var navEvt = $A.get("e.force:navigateToSObject");
    navEvt.setParams({
        "recordId": recId
    });
    navEvt.fire();
}
})