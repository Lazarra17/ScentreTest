({
    doInit : function(component, event, helper) {
        helper.getClauseAndOptions(component, event, helper);
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
        helper.onEdit(component, event, helper);
    }
})