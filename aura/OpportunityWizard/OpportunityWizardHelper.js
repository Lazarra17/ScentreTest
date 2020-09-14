({
	createComponent : function(component, componentName) {
        var self = this;
        
        console.log("CREATE COMPONENT");
        
		$A.createComponent(
            componentName,
            {
                "aura:id": "currentComponent",
                "recordId": component.get("v.recordId")
            },
            function(newComponent, status, errorMessage){
                self.toggleSpinner(component, "hide");
                
                console.log("status : ", status);
                
                //Add the new button to the body array
                if (status === "SUCCESS") {
                    var body = [];
                    
                    body.push(newComponent);
                    
                    component.set("v.body", body);
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                    // Show offline error
                }
                else if (status === "ERROR") {
                    console.log("Error: " + errorMessage);
                    // Show error message
                }
            }
        );
	},
    
    toggleSpinner : function(component, action){
    	if(action === "show"){
            component.set("v.isLoading", true);
        } else if(action === "hide"){
            component.set("v.isLoading", false);
        }
    }
})