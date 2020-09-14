({
    createObjectData: function(component, event) {
        // get the contactList from component and add(push) New Object to List  
        var RowItemList = component.get("v.contactList");
        RowItemList.push({
            'sobjectType': 'Contact',
            'FirstName': '',
            'LastName': '',
            'Phone': ''
        });
        // set the updated list to attribute (contactList) again    
        component.set("v.contactList", RowItemList);
    },
    createOppoLineItemData: function(component, event) {
        // get the oppoItemList from component and add(push) New Object to List  
        console.log('Record Id', component.get("v.recordId"));
        let recordId = component.get("v.recordId");
        var action = component.get("c.checkYears");
        action.setParams({
            "opportunityId": recordId
        });
        // set call back 
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let years = response.getReturnValue();
                // Get values
                var oppoItemList = component.get("v.oppoLineItemList");
                for (let i=0; i<years; i++) {
                	oppoItemList.push({
                        'sobjectType': 'OpportunityLineItem',
                        'RentReviewType__c': '',
                        'RentReviewValue__c': ''
                    });   
                }
                // set the updated list to attribute (contactList) again    
                component.set("v.oppoLineItemList", oppoItemList);
            }
        });
        // enqueue the server side action  
        $A.enqueueAction(action);
    },
    // helper function for check if first Name is not null/blank on save  
    validateRequired: function(component, event) {
        var isValid = true;
        var allContactRows = component.get("v.contactList");
        for (var indexVar = 0; indexVar < allContactRows.length; indexVar++) {
            if (allContactRows[indexVar].FirstName == '') {
                isValid = false;
                alert('First Name Can\'t be Blank on Row Number ' + (indexVar + 1));
            }
        }
        return isValid;
    },
})