({
	doInit : function(component, event, helper) {
		helper.getAffiliationList(component);
        helper.verifyUserAccess(component);
        component.set("v.column", [
            { label: "Active", fieldName: "isActive", type: "boolean",  editable: true},
            { label: "Type", fieldName: "affType", type: "text"},
            { label: "Name", fieldName: "affName", type: "text"},
            { label: "Address", fieldName: "affAddress", type: "text"}
        ]);
	},
    closeSpinner : function(component, event, helper) {
        component.set("v.showSpinner", false);
    },
    errorSaving : function(component, event, helper) {
        component.set("v.showSpinner", false);
        var errors = event.getParams();
       	console.log("errors : ", JSON.stringify(errors));
        
	},
    successSaving : function(component, event, helper) {
        let doCreateRCA = component.get("v.doCreateRCA");
        let updatedOpp = event.getParams().response; 
		/*var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Success',
            message: 'Opportunity Updated',
            messageTemplate: 'Record {0} created! See it {1}!',
            duration:' 5000',
            key: 'info_alt',
            type: 'success',
            mode: 'pester'
        });
        toastEvent.fire();*/
         helper.showToast(component, "success", "Success!", "Opportunity Updated");
        
        console.log("doCreateRCA : ", doCreateRCA);
        
        if(doCreateRCA){
            helper.createRCAOppClauseHelper(component, updatedOpp.fields);
        } else {
            component.set("v.showSpinner", false);
        }
	},
    handleSave : function(component, event, helper) {
        let object = helper.getChanges(component, event);
        helper.saveAffiliationList(component, object);
    },
    onSubmit : function(component, event, helper) {
        component.set("v.showSpinner", true);
        let oppRecordMaster = component.get("v.oppRecord");
        let oppRecordEditForm = event.getParam("fields");
        
        component.set("v.doCreateRCA", false);
        
        if(oppRecordMaster != null && oppRecordMaster != '') {
            if(oppRecordMaster.SecurityDeposit__c != oppRecordEditForm.SecurityDeposit__c 
               || oppRecordMaster.SecurityDepositDays__c != oppRecordEditForm.SecurityDepositDays__c 
               || oppRecordMaster.SecurityDepositWeeks__c != oppRecordEditForm.SecurityDepositWeeks__c
               || oppRecordMaster.SecurityDepositMonths__c != oppRecordEditForm.SecurityDepositMonths__c){
                component.set("v.doCreateRCA", true);
            }
        }
        
        console.log("doCreateRCA", component.get("v.doCreateRCA"));
       	console.log("oppRecordMaster", JSON.parse(JSON.stringify(oppRecordMaster)));
        console.log("oppRecordEditForm", JSON.parse(JSON.stringify(oppRecordEditForm)));
    },
    toggleModal : function(component, event, helper) {
        var modalBody;
        console.log(event.getSource().get("v.name"));
        $A.createComponent("c:AddGuarantor", {
            "oppRecordId": component.get('v.recordId')
        },
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: "Add Guarantor",
                                       body: modalBody, 
                                       showCloseButton: true,
                                       closeCallback: function() {
                                           $A.get('e.force:refreshView').fire();
                                           helper.getAffiliationList(component);
                                           component.set("v.column", [
                                               { label: "Active", fieldName: "isActive", type: "boolean",  editable: true},
                                               { label: "Type", fieldName: "affType", type: "text"},
                                               { label: "Name", fieldName: "affName", type: "text"},
                                               { label: "Address", fieldName: "affAddress", type: "text"}
                                           ]);
                                       }
                                   })
                               }                               
                           });
    }
})