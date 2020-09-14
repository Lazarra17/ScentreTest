({
 
    // function call on component Load
    doInit: function(component, event, helper) {
        // create a Default RowItem [Contact Instance] on first time Component Load
        // by call this helper function  
        helper.createOppoLineItemData(component, event);
    },
 
    // function for save the Records 
    Save: function(component, event, helper) {
        // call the apex class method for save the Contact List
        // with pass the contact List attribute to method param.  
        var action = component.get("c.saveNonStandardOppoLineItems");
        action.setParams({
            "listOppoLineItem": component.get("v.oppoLineItemList"),
            "oppoId": component.get("v.recordId"),
            "cpiType" : component.get("v.cpiType"),
            "reviewCode" : component.get("v.reviewCode"),
            "reviewDescription" : component.get("v.reviewDescription")
        });
        // set call back 
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log(state);
            if (state === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "The products are added"
                });
                toastEvent.fire();
            } else {
                let errors = response.getError();
                console.log(errors);                }
        });
        // enqueue the server side action  
        $A.enqueueAction(action);
    },
 
    // function for create new object Row in Contact List 
    addNewRow: function(component, event, helper) {
        // call the comman "createObjectData" helper method for add new Object Row to List  
        helper.createObjectData(component, event);
    },
 
    // function for delete the row 
    removeDeletedRow: function(component, event, helper) {
        // get the selected row Index for delete, from Lightning Event Attribute  
        var index = event.getParam("indexVar");
        // get the all List (contactList attribute) and remove the Object Element Using splice method    
        var AllRowsList = component.get("v.contactList");
        AllRowsList.splice(index, 1);
        // set the contactList after remove selected row element  
        component.set("v.contactList", AllRowsList);
    },
})