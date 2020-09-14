({
	pushSearchResult : function(component, searchResult) {
		var eventHandler = component.getEvent("searchResult");
        
        eventHandler.setParams({
            searchResult : searchResult
        })
        
        eventHandler.fire()
	}
})