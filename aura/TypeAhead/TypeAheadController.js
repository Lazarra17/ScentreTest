({
    itemSelected : function(component, event, helper) {
        helper.itemSelected(component, event, helper);
    }, 
    serverCall :  function(component, event, helper) {
        helper.serverCall(component, event, helper);
    },
    clearSelection : function(component, event, helper){
        helper.clearSelection(component, event, helper);
    },
    
    clearDropdown : function(component, event, helper){
        helper.clearDropdown(component, event);
    },
    
    showBlankError : function(component, event, helper){
        if(component.get("v.blankError") == true){
            var inputBox=component.find("inputBox");
            $A.util.addClass(inputBox, 'blankError'); 
            document.getElementById("combobox-unique-id").focus(); 
        }
    },
    
    selItemChanged : function(component, event, helper){
        if(component.get("v.selItem")==''){
            component.set("v.searchText",'');
        }
    }
})