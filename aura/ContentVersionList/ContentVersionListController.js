({
	init : function(component, event, helper) {
        helper.getRelatedfiles(component);
	},
    
    handleSave : function(component, event, helper){
    	component.set("v.isLoading", true);
        helper.updateContentVersion(component)
    },
    
    getDocTypeList: function(component, event, helper) {
        let cVersionId = event.getSource().get("v.name");
        helper.getDocTypePicklist(component, cVersionId);
    },
    handleCancel : function(component, event, helper){
        component.set("v.contentversionWrapperTemp", []);
    }
})