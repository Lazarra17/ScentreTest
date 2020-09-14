({
	search : function(component, event, helper) {
        var recordTemp;
        var searchFieldTemp;
        var searchResult = [];
		var searchList = component.get("v.searchList")
        var searchFieldList = component.get("v.searchFieldList")
        var searchString = event.getSource().get("v.value").toString().toLowerCase()
        
        console.log("searchString : ", searchString)
        console.log("searchList :", searchList)
        console.log("searchFieldList: ", searchFieldList)
        
        if(!$A.util.isEmpty(searchString)){
            for(var x in searchList){
                recordTemp = searchList[x]
                
                for(var i in searchFieldList){
                    searchFieldTemp = searchFieldList[i]
                 	if(recordTemp[searchFieldTemp].toLowerCase() == searchString || recordTemp[searchFieldTemp].toLowerCase().search(searchString) > -1){
                        searchResult.push(recordTemp)
                    }   
                }
            }
        } else {
            searchResult = searchList;
        }
        
        helper.pushSearchResult(component, searchResult);
	}
})