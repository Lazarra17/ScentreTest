({
	getSelectedSpace : function(component, event, helper) {        
        component.set("v.selectedSpaceList", event.getParams().selectedRows);
        console.log(JSON.parse(JSON.stringify(event.getParams().selectedRows)));
	},
    
    next : function(component, event, helper){
        var selectedSpaceList = component.get("v.selectedSpaceList")
        
        if(!$A.util.isEmpty(selectedSpaceList)){
         	helper.pushSelectedSpace(component, selectedSpaceList);   
        } else {
            helper.throwError(component, "Error!", "error", "Please select Space/s to merge or split")
        }
    },
    
    catchSearchResult : function(component, event, helper){
        var searchResult = event.getParams().searchResult
        
        component.set("v.filteredSpaceList", searchResult)
        component.set("v.selectedRows", component.get("v.selectedSpaceList"))
    }
})