({
    doInit : function(cmp){},
    
    toggleSection : function(cmp, event){
        var cmpTarget = cmp.find("section");
        $A.util.toggleClass(cmpTarget, 'slds-is-open');
        
        var iconName = cmp.get("v.section1iconName");
        if(iconName === "utility:chevrondown"){
            cmp.set("v.section1iconName", "utility:chevronright");
        }else{
            cmp.set("v.section1iconName", "utility:chevrondown");
        }
    },
    
    inlineEditName : function(cmp, event){
        var cmpEvent = cmp.getEvent("changeMode");
        cmpEvent.setParams({
            "caseMode" : false
        });
        cmpEvent.fire();
    },
    
    fieldChanged : function(cmp, event){
        //console.log('fieldChanged: '+event);
        var ctarget = event.currentTarget;
        console.log(JSON.stringify(event));
        console.log('event.currentTarget: '+event.currentTarget);
        console.log('event.getSource(): '+event.getSource());    	
        //var id_str = ctarget.dataset.value;
        //console.log('id_str: '+id_str);
    }
})