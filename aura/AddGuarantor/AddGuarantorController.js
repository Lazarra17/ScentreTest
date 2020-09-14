({
	doInit : function(component, event, helper) {
		var flow = component.find("flow");
        var inputVariables = [
               {
                  name : "recordId",
                  type : "String",
                  value: component.get("v.oppRecordId")
               }
            ];
        flow.startFlow("CreateAffliation", inputVariables);
	},
    statusChange : function(component, event, helper) {
        if(event.getParam("status") === "FINISHED") {
            component.find("overlayLib").notifyClose();
        }
    }
})