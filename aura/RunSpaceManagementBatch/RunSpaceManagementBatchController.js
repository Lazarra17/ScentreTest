({
	init : function(component, event, helper) {
		helper.checkBatchStatus(component,false);
	},
    
    showComponent: function(component){
        component.set('v.showComponent',true);
    },
    
    processBatch : function(component,event,helper){
        component.set('v.message','');
        component.set('v.showComponent',true);
    	helper.processBatch(component);
	},
    
    checkStatus : function(component, event, helper) {
        component.set('v.showComponent',true);
		helper.checkBatchStatus(component,false);
    }
})