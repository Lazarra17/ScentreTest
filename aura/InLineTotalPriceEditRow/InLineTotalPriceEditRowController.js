({
    inlineEditListPrice : function(component,event,helper){   
        component.set("v.totalPriceEditMode", true); 
        setTimeout(function(){ 
            component.find("inputId").focus();
        }, 100);
    },
    closeListPriceBox : function (component, event, helper) { 
        component.set("v.totalPriceEditMode", false);   
    }, 
    changeToggleValue : function(component, event, helper) {
        component.set("v.idToggled", event.getSource().get("v.name"));
        var sample = event.getSource().get("v.name");
        
    },
    
    toggleOnChange : function(component, event, helper) {
        alert(component.get('v.feesChargesWrappers').productName);
    }
})