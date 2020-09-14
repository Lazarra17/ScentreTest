({
    doInit: function(component, event, helper) {
        helper.doInitHelper(component, event);
    },
    
    navigation: function(component, event, helper) {
        var clauseList = component.get("v.listOfSelectedClauses");
        var end = component.get("v.endPage");
        var start = component.get("v.startPage");
        var pageSize = component.get("v.pageSize");
        var clickedNav = event.getSource().get("v.name");
        if (clickedNav == 'next') {
            component.set("v.currentPage", component.get("v.currentPage") + 1);
            helper.next(component, event, clauseList, end, start, pageSize);
        }
        else if (clickedNav == 'previous') {
            component.set("v.currentPage", component.get("v.currentPage") - 1);
            helper.previous(component, event, clauseList, end, start, pageSize);
        }
    }
    
})