({
    doInitHelper : function(component,event){ 
        var action = component.get("c.getSelectedClauses");
        action.setParams ({oppId : component.get("v.recordId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            var res = response.getReturnValue();
            if (state === "SUCCESS"){
                var returnValue = JSON.parse(res.returnValue);
                if(returnValue.opportunityClauseList.length > 0){
                    component.set("v.listOfSelectedClauses", returnValue.opportunityClauseList);
                    var pageSize = component.get("v.pageSize");
                    var totalRecordsList = returnValue.opportunityClauseList
                    var totalLength = totalRecordsList.length ;
                    component.set("v.totalRecordsCount", totalLength);
                    component.set("v.startPage",0);
                    component.set("v.endPage",pageSize-1);
                    
                    var PaginationLst = [];
                    for(var i=0; i < pageSize; i++){
                        if(component.get("v.listOfSelectedClauses").length > i){
                            PaginationLst.push(returnValue.opportunityClauseList[i]);    
                        } 
                    }
                    component.set('v.listOfPaginatedClauses', PaginationLst);
                    component.set("v.selectedCount" , 0);
                    component.set("v.totalPagesCount", Math.ceil(totalLength / pageSize));    
                }else{
                    component.set("v.noRecordsFound" , true);
                } 
            }
            else{
                alert('Error...');
            }
        });
        $A.enqueueAction(action);  
    }, 
    next : function(component, event, clauseList, end, start, pageSize){
        var paginatedClauseList = [];
        var counter = 0;
        for(var i = end + 1; i < end + pageSize + 1; i++){
            if(clauseList.length > i){ 
                paginatedClauseList.push(clauseList[i]);  
            }
            counter ++ ;
        }
        start = start + counter;
        end = end + counter;
        component.set("v.startPage",start);
        component.set("v.endPage",end);
        component.set('v.listOfPaginatedClauses', paginatedClauseList);
    },  
    previous : function(component, event, clauseList, end, start, pageSize){
        var paginatedClauseList = [];
        var counter = 0;
        for(var i= start-pageSize; i < start ; i++){
            if(i > -1){
                paginatedClauseList.push(clauseList[i]); 
                counter ++;
            }else{
                start++;
            }
        }
        start = start - counter;
        end = end - counter;
        component.set("v.startPage",start);
        component.set("v.endPage",end);
        component.set('v.listOfPaginatedClauses', paginatedClauseList);
    },
})