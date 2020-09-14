({
    doInit : function(component, event, helper) {
        helper.getClauseAndOptions(component, event, helper);
        helper.checkIfEnableClauseEditUpdate(component, event, helper);
        
    },
    search : function(component, event, helper) {
        helper.searchClause(component, event, helper);
    },
    changeIsSelectedTrue : function(component, event, helper) {
        component.set("v.idToggled", event.getSource().get("v.name"));
        helper.trueIsSelected(component, event, helper);
    },
    changeIsSelectedFalse : function(component, event, helper) {
        component.set("v.idToggled", event.getSource().get("v.name"));
        helper.falseIsSelected(component, event, helper);
    },
    save : function(component, event, helper) {
        helper.onSave(component, event, helper);
    },
    edit : function(component, event, helper) {
       if(event.getSource().get("v.name")!==undefined){
            component.set("v.oppClauseId", event.getSource().get("v.name"));
        }
        helper.onEdit(component, event, helper);
    },
    delete : function(component, event, helper) {
    	component.set("v.oppClauseId", event.getSource().get("v.name"));
    	helper.onDelete(component, event, helper);
	},
 	closeModal : function (component, event, helper) {
    	$A.get("e.force:closeQuickAction").fire();
    	$A.get('e.force:refreshView').fire();
	},
    handleSaveSuccess : function(component, event, helper) {
        helper.getUpdates(component, event, helper);
    }
})