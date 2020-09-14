({
    doInit : function(component, event, helper){
        var spaceTemp = {};
        var spaceList = [];
        
        spaceTemp = helper.createNewSpace()
        spaceList.push(spaceTemp)
        
        component.set("v.newSpaceList", spaceList);
    },
    
    checkType : function(component, event, helper){
        var spaceList = component.get("v.newSpaceList")
        var type = event.getSource().get("v.value")
        var index = event.getSource().get("v.title")
        
        if(type !== "20" && type !== "21" && type !== "22" ){
            spaceList[index].ReasonForChange__c = "";
        } 
        
        component.set("v.newSpaceList", spaceList)
    },
    
    addRemoveSpace : function(component, event, helper){        
        var spaceTemp = {};
        var spaceListLength = 0;
        var mode = component.get("v.mode");
        var spaceList = component.get("v.newSpaceList");
        var numberOfSpace = component.get("v.numberOfSpace");
        
        if($A.util.isEmpty(numberOfSpace) || numberOfSpace == 0){
            spaceList = [];
            
            numberOfSpace = 1;
            component.set("v.numberOfSpace", numberOfSpace);
            
            helper.showToast(component, "warning", "Info", "You must create atleast " + numberOfSpace + " Space/s")
        } 
        
        if(!$A.util.isEmpty(spaceList)){
            spaceListLength = spaceList.length;
        }
        
        if(spaceListLength > numberOfSpace){
            spaceList.splice((numberOfSpace - 1), spaceListLength - numberOfSpace);
        } else if(spaceListLength < numberOfSpace){
            for(var counter = 0; counter < (numberOfSpace - spaceListLength); counter++){
                spaceTemp = helper.createNewSpace()
                spaceList.push(spaceTemp);
            }
        }
        
        console.log("newSpaceList : ", spaceList)
        component.set("v.newSpaceList", spaceList);
    },
    
    save : function(component, event, helper){
        var newSpaceList = component.get("v.newSpaceList")
        var selectedSpaceArea = component.get("v.selectedSpaceArea")
        
        var elements = [
            "spaceName",
            "area",
            "type",
            "numberOfSpace",
            "reasonForChange"
        ];
        
        if(helper.isAreaValid(selectedSpaceArea, newSpaceList)){
            if(helper.areFieldsValid(component, elements)){
                helper.saveSpaces(component, newSpaceList)      
            } else {
                helper.showToast(component, "error", "Error!", "Please make sure fields are populated correctly below.");
            }
        } else {
            helper.showToast(component, "error", "Invalid Area", "Total Area must be equal or less than to total Area of selected Spaces and cannot be 0.");
        }
    },
    
    previous : function(component, event, helper) {
        helper.goBack(component);
    },
})