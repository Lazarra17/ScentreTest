({
	inlineEditListPrice : function(component,event,helper){   
        component.set("v.listPriceEditMode", true); 
        setTimeout(function(){ 
            component.find("inputId").focus();
        }, 100);
    },
    closeListPriceBox : function (component, event, helper) { 
        component.set("v.listPriceEditMode", false);   
    }, 
    changeToggleValue : function(component, event, helper) {
        component.set("v.idToggled", event.getSource().get("v.name"));
        var sample = event.getSource().get("v.name");
        alert(sample);
    }
})