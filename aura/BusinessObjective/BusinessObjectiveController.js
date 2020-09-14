({
    doInit : function(component, event, helper) {
        helper.verifyUserAccess(component);
    },
    savedetails : function (component, event, helper) {
        component.set("v.showSpinner", true);
        component.find('opptyobjectivedetail').saveRecord(function(saveResult) {
            if(saveResult.state ==="SUCCESS") {
             //   helper.showToast(component, "success", "Success!", "Business Objective information saved.");
                component.find('notifLib').showToast({
                    "title": "Success!",
                    "variant":"success",
                    "message": "Business Objective information saved.",
                });
                
             
            }else {
                var errMsg = "";
                if(saveResult.error != null && saveResult.error != ''){
                    for (var i = 0; i < saveResult.error.length; i++) {
                        errMsg += saveResult.error[i].message + "\n";
                        console.log('ERROR MESSAGE: ' + errMsg);
                    }
                    component.find('notifLib').showToast({
                    "title": "Failed!",
                    "variant":"error",
                    "message": saveResult.state + " " + errMsg,
               		 });
                }
                
            }
            component.set("v.showSpinner", false);
        });
        }
})