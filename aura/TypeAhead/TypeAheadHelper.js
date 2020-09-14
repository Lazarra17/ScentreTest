({
    itemSelected : function(component, event, helper) {
        if(typeof(event.target.getAttribute) == 'undefined') {
            return;
        }
        var target = event.target;
        console.log(target);
        
        var SelIndex = helper.getIndexFrmParent(target,helper,"data-selectedIndex");
        console.log(SelIndex);
        if(SelIndex){
            var serverResult = component.get("v.server_result");
            console.log(serverResult);
            var selItem = serverResult[SelIndex];
            console.log(selItem);
            var selItemVal;
            if(selItem != null){
                selItemVal = selItem.val;
            }else{
                selItemVal = null;
                component.set("v.isDisabled", true);
            }
            component.set("v.selItem",selItem);
            component.set("v.server_result",null);
            console.log('selItemVal === '+selItemVal);
            if(selItemVal){
                
                //console.log("selected...................../////");
                console.log(component.get("v.selItem"));
                component.set("v.last_ServerResult",serverResult);
            }             
        }
    }, 
    
    serverCall : function(component, event, helper) {  
        var target = event.target;  
        var searchText = target.value;
        component.set("v.searchText",searchText);
        if(searchText == ''){
            helper.clearDropdown(component, event);
            return;
        }
        
        var last_SearchText = component.get("v.last_SearchText");
        //Escape button pressed 
        if (event.keyCode == 27 || !searchText.trim()) { 
            helper.clearSelection(component, event, helper);
        }else if(searchText.trim() != last_SearchText ){ 
            //Save server call, if last text not changed
            var objectName = component.get("v.objectName");
            var field_API_text = component.get("v.field_API_text");
            var field_API_val = component.get("v.field_API_val");
            var field_API_search = component.get("v.field_API_search");
            var limit = component.get("v.limit");
            var condStr = component.get("v.conditionStr");
            var allowToCreateNew = component.get("v.allowToCreateNew");
            var action = component.get('c.searchDB');
            action.setStorable();
            
            action.setParams({
                objectName : objectName,
                fld_API_Text : field_API_text,
                fld_API_Val : field_API_val,
                lim : limit, 
                fld_API_Search : field_API_search,
                searchText : searchText,
                conditionStr : condStr,
                allowToCreateNew : allowToCreateNew
            });
            
            action.setCallback(this,function(a){
                this.handleResponse(a,component,helper);
            });
            
            component.set("v.last_SearchText",searchText.trim());
            //console.log('Server call made');
            $A.enqueueAction(action); 
        }else if(searchText && last_SearchText && searchText.trim() == last_SearchText.trim()){ 
            component.set("v.server_result",component.get("v.last_ServerResult"));
        }         
    },
    
    handleResponse : function (res,component,helper){
        if (res.getState() === 'SUCCESS') {
            var retObj = JSON.parse(res.getReturnValue());
            if(retObj.length <= 0){
                var noResult = JSON.parse('[{"text":"No Results Found"}]');
                component.set("v.server_result",noResult); 
                component.set("v.last_ServerResult",noResult);
            }else{
                component.set("v.server_result",retObj); 
                component.set("v.last_ServerResult",retObj);
            }  
        }else if (res.getState() === 'ERROR'){
            var errors = res.getError();
            if (errors) {
                if (errors[0] && errors[0].message) {
                    alert(errors[0].message);
                }
            } 
        }
    },
    
    getIndexFrmParent : function(target,helper,attributeToFind){
        //User can click on any child element, so traverse till intended parent found
        var SelIndex = target.getAttribute(attributeToFind);
        while(!SelIndex){
            target = target.parentNode;
            SelIndex = helper.getIndexFrmParent(target,helper,attributeToFind);
        }
        return SelIndex;
    },
    
    clearSelection: function(component, event, helper){
        var data = component.get("v.selItem");
        component.set("v.selItem",null);
        component.set("v.server_result",null);
        component.set('v.searchText','');
    },
    
    clearDropdown : function(component, event){
        component.set("v.selItem",null);
        component.set("v.server_result",null);
        component.set('v.searchText','');
    }
})