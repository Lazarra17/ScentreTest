({
    doInit: function(component, event, helper) {
        helper.getPicklistValues(component, event, helper);
    },
    onSubmit : function(component, event, helper) {
       component.set("v.showSpinner", true);
       helper.updateOpptyRecordTest(component, event, helper);
   },
    stageChanged: function(component, event, helper){
        var stagePicklist = component.find('stage').get('v.value');
        var reasonPicklist = component.find('reason');
        if(stagePicklist === "Closed - Cancelled"){
            component.set('v.disabledPicklist', false);
        }
        else{
            component.set('v.disabledPicklist', true);
            reasonPicklist.set("v.value",null);
        }
    },
    handleSaveRecord: function(component, event, helper) {
        alert('=========');
        //helper.updateOpptyRecord(component, event, helper);
    },
    errorSaving : function(component, event, helper) {
		var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Error!',
            message:'Updating Opportunity Failed',
            messageTemplate: 'Mode is pester ,duration is 5sec and Message is overrriden',
            duration:' 5000',
            key: 'info_alt',
            type: 'error',
            mode: 'pester'
        });
        toastEvent.fire();
        var payload = event.getParams().error;
        console.log('Error==> ' + JSON.stringify(payload));
        
        component.set("v.showSpinner", false);
	},
    successSaving : function(component, event, helper) {
		var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Success',
            message: 'Opportunity Updated',
            messageTemplate: 'Record {0} created! See it {1}!',
            duration:' 5000',
            key: 'info_alt',
            type: 'success',
            mode: 'pester'
        });
        toastEvent.fire();
        component.set("v.showSpinner", false);
	},
        onSave : function(component, event, helper) {
        /*if(component.find("keydatesComponent")) {
            var opptykeydates = component.find("keydatesComponent");
            opptykeydates.savekeydates();
        }*/
    }
})