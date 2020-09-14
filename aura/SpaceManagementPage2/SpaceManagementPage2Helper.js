({
	goBack : function(component) {
		var eventHandler = component.getEvent("goBack");
        
        eventHandler.setParams({
            action : "previous"
        })
        
        eventHandler.fire()
	},
    
    createNewSpace : function(){
        var spaceTemp = {};
        spaceTemp.Name = "";
        spaceTemp.RentableArea__c = 0.00;
        spaceTemp.UsableArea__c = 0.00; //Neel - Added to populate the Usable Area same as Rentable Area
        spaceTemp.ReasonForChange__c = ""
        spaceTemp.Type__c = "1";
        
        return spaceTemp;
    },
    
    saveSpaces : function(component, newSpaceList){
        var eventHandler = component.getEvent("saveNewSpaces");
        
        eventHandler.setParams({
            spaceList : newSpaceList
        })
        console.log("INIT PAGE2 Helper Save"+  component.get("v.newSpaceList"));
        eventHandler.fire();
    },
    
    throwError : function(component, title, type, message){
        var eventHandler = component.getEvent("throwError");
        
        eventHandler.setParams({
            type : type,
            title : title,
            message : message
        })
        
        eventHandler.fire();
    },
    
    isAreaValid : function(selectedSpaceArea, newSpaceList){
        var validArea = true;
        var newSpacesArea = 0
        var lostSpaceExemption = parseFloat($A.get("$Label.c.SpaceReconfig_LostSpaceExemption"));
        
        console.log("$A.get($Label.c.SpaceReconfig_LostSpaceExemption) : ", $A.get("$Label.c.SpaceReconfig_LostSpaceExemption"));
        console.log("lostSpaceExemption-page2 : ", lostSpaceExemption);
        
        for(var counter in newSpaceList){
            newSpacesArea += parseFloat(newSpaceList[counter].RentableArea__c)
            newSpaceList[counter].UsableArea__c = newSpaceList[counter].RentableArea__c //Neel - Added to populate the Usable Area same as Rentable Area
        }
        
        if((selectedSpaceArea + lostSpaceExemption) < newSpacesArea){
            validArea = false;
        }
        if(newSpacesArea===0){
            validArea = false;
        }
        
        
        console.log("newSpacesArea : ", newSpacesArea)
        console.log("selectedSpaceArea : ", selectedSpaceArea)
        
        return validArea;
    },
    
    showToast : function(component, state, title, message){
        var eventHandler = $A.get("e.c:ToastEvent")
        
        eventHandler.setParams({
            state : state,
            title : title,
            message : message
        })
        
        eventHandler.fire()
    },
    
    areFieldsValid : function(component, elements){
        var isValid = true;
        var checkReason = false;
        
        for (var i in elements){
            console.log('elements : ', elements[i]);
            var elem = component.find(elements[i]);
            
            if (! $A.util.isEmpty(elem)){
                console.log('elem.length : ', elem.length)
                if(elem.length > 0){
                    for(var x in elem){
                        console.log('elem[x] : ', elem[x]);
                        if(!elem[x].get("v.validity").valid) {
                            elem[x].showHelpMessageIfInvalid();
                            isValid = false;
                        }
                    }
                }
                /*} else {
                    if(!elem.get("v.validity").valid) {
                        elem.showHelpMessageIfInvalid();
                        isValid = false;
                    }
                }*/
            }
        } 
        
        return isValid;
    }
})