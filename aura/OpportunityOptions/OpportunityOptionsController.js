({
    doInit : function(component, event, helper) {
        var actions = [
            { label: 'Edit', name: 'edit' },
            { label: 'Delete', name: 'delete' }
        ];
        component.set('v.oppLineItemColumnList',  [{ type: 'action', typeAttributes: { rowActions: actions }},
                                                   {label: 'Option Name', fieldName: 'ProductName__c', type: 'text'},
                                                   {label: 'Options Term', fieldName: 'OptionsTerm__c', type: 'number', cellAttributes: { alignment: 'left' }},
                                                   {label: 'Description', fieldName: 'Description', type: 'text'}]);
        helper.getOpportunityLineItems(component);
        helper.verifyUserAccess(component);
    },
    toggleModal : function(component, event, helper) {
         var modalBody;
        $A.createComponent("c:AddOptionsModal", {
            "oppRecordId": component.get('v.recordId'),
            "pricebookEntryId": component.get('v.optionPBentryRecordId'),
            "product2Id": component.get('v.optionProductRecordId')
        },
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: "Add Options",
                                       body: modalBody, 
                                       showCloseButton: true,
                                       closeCallback: function() {
                                           helper.getOpportunityLineItems(component);
                                       }
                                   })
                               }                               
                           });
    },
    

    
    handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'edit':
                var modalBody;
                $A.createComponent("c:ViewOpportunityOptionsModal", {
                    "optionsId": row.Id
                },
                                   function(content, status) {
                                       if (status === "SUCCESS") {
                                           modalBody = content;
                                           component.find('overlayLib').showCustomModal({
                                               header: "Edit Option",
                                               body: modalBody, 
                                               showCloseButton: true,
                                               closeCallback: function() {
                                                   helper.getOpportunityLineItems(component);
                                               }
                                           })
                                       }                               
                                   });
                break;
            case 'delete':
                helper.removeOpportunity(component, row)
                break;
        }
    }
})