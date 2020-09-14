({
    doInit : function(component, event, helper) {
        component.set("v.showSpinner", true);
        helper.getClauseTypePicklistValues(component);
        helper.getDocLocPicklistValues(component);
        helper.getApplicableStatePicklistValues(component);
        helper.getOpportunityClauseWrapper(component);
        helper.onStateChange(component);
        helper.verifyUser(component);
        component.set("v.showSpinner", false);
    },
    onStateChange : function(component,event,helper){
        helper.onStateChange(component);
    },
    checkClause : function(component, event, helper) {
        var displayClauseList = component.get("v.displayClauseList");
        var index = event.getSource().get("v.name");
        var selectedClauseList = component.get("v.selectedClauseList");
        selectedClauseList.push(displayClauseList[index]);
        displayClauseList.splice(index, 1);
        component.set("v.selectedClauseList", selectedClauseList);
        component.set("v.displayClauseList", displayClauseList);
    },
    uncheckClause : function(component, event, helper) {
        var displayClauseList = component.get("v.displayClauseList");
        var index = event.getSource().get("v.name");
        var selectedClauseList = component.get("v.selectedClauseList");
        displayClauseList.push(selectedClauseList[index]);
        selectedClauseList.splice(index, 1);
        component.set("v.selectedClauseList", selectedClauseList);
        component.set("v.displayClauseList", displayClauseList);
    },
    search : function(component, event, helper) {
        helper.helperSearch(component);
    },
    onSave : function(component, event, helper) {
        component.set("v.showSpinner", true);
        helper.onStateChange(component);
        helper.saveSelectedClauseList(component);
    },
    onDelete : function(component, event, helper) {
        component.set("v.showSpinner", true);
        helper.deleteOpportunityClause(component, event);
    },
    onEdit : function(component, event, helper) {
        var modalBody;
        $A.createComponent("c:EditRecordModal", {
            "recordId" : event.getSource().get("v.name")
        },
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: "Edit Opportunity Clause",
                                       body: modalBody, 
                                       showCloseButton: true,
                                       closeCallback: function() {
                                           helper.getOpportunityClauseWrapper(component);
                                       }
                                   })
                               }                               
                           });
    },
    onClose : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})