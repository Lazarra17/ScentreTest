({
    getRelatedfiles : function(component) {
        let action = component.get("c.getallfiles");        
        action.setParams({
            "recordId": component.get("v.recordId")         
        });
        action.setCallback(this, function(response) {
            let state = response.getState();
            let res = response.getReturnValue();
            
            if (state === "SUCCESS" && res.status === "SUCCESS") {
                let returnValue = JSON.parse(res.returnValue);                
                component.set("v.contentversionWrapper", returnValue);
                component.set("v.contentversionWrapperTemp", JSON.parse(res.returnValue));
                
                console.log("returnValue : ", returnValue);
            } else {
                console.log("response.getError() : ", response.getError());
            }
            component.set("v.isLoading", false);
        });
        
        $A.enqueueAction(action);
    },
    
    updateContentVersion : function(component){
        let self = this;
        let cVersionList = [];
        let contentVersionWrapper = component.get("v.contentversionWrapper"); 
        let action = component.get("c.updateContentVersion");
        console.log(contentVersionWrapper);
        let cVersionDetailWrap = Object.values(self.getContentVersionMap(contentVersionWrapper.contentVersionList))
        
        for(let cVersion of cVersionDetailWrap){
            cVersionList.push(cVersion.contentVersion);
        }
        
        cVersionList = self.getUpdatedFile(component, cVersionList);
        
        console.log("cVersionList : ", cVersionList);
        
        action.setParams({
            recordId : component.get("v.recordId"),
            contentVersionJSON : JSON.stringify(cVersionList)
        })
        
        action.setCallback(this, function(response){
            let res = response.getReturnValue();
            
            if(res.status === "SUCCESS" && response.getState() === "SUCCESS"){
                let returnValue = JSON.parse(res.returnValue);                
                component.set("v.contentversionWrapper", returnValue);
                component.set("v.contentversionWrapperTemp", JSON.parse(res.returnValue));
                
                self.showToast("Success!", "Files successfully updated.", "success");
            } else {
                let errorMessage = self.errorHandler(res.message);
                console.log('errorMessage', errorMessage);
                //self.showToast("Update opportunity failed", errorMessage, errorMessage);
                self.showToast("Opportunity update failed", errorMessage, errorMessage);
                //console.log("error update : ", res.message);
            }
            $A.get('e.force:refreshView').fire();
            component.set("v.isLoading", false);
        });
        $A.enqueueAction(action)
    },
    
    getUpdatedFile : function(component, contentVersionList){
        let oldCVersion;
        let updatedContentVersionList = [];
        let oldContentVersionWrap = component.get("v.contentversionWrapperTemp"); 
        
        let oldContentVersionMap = this.getContentVersionMap(oldContentVersionWrap.contentVersionList);
        
        for(var cVersion of contentVersionList){
            oldCVersion = oldContentVersionMap[cVersion.Id].contentVersion;
            
            console.log("cVersion : ", cVersion);
            console.log("oldCVersion : ", oldCVersion);
            
            if(cVersion.FinalVersion__c !== oldCVersion.FinalVersion__c 
               || (cVersion.DocumentType__c !== oldCVersion.DocumentType__c)
               || (cVersion.DocumentCategory__c !== oldCVersion.DocumentCategory__c)){
                updatedContentVersionList.push(cVersion);
            } 
        }
        
        console.log("updatedContentVersionList : ", updatedContentVersionList);
        
        return updatedContentVersionList;
    },
    
    getDocTypePicklist : function(component, cVersionId){
        let cVersionWrapper = component.get("v.contentversionWrapper");
        let cVersionMap = this.getContentVersionMap(cVersionWrapper.contentVersionList);
        
        cVersionWrapper.contentVersionList = [];
        cVersionMap[cVersionId].docTypePicklistValue = cVersionWrapper.documentTypeListMap[cVersionMap[cVersionId].contentVersion.DocumentCategory__c];
        cVersionMap[cVersionId].contentVersion.DocumentType__c = "";
        cVersionWrapper.contentVersionList = Object.values(cVersionMap);
        component.set("v.contentversionWrapper", cVersionWrapper)
    },
    
    getContentVersionMap : function(cVersionList){
        let cVersionMap = {};       
        for(let cVersion of cVersionList){
            cVersionMap[cVersion.contentVersion.Id] = cVersion;
        }        
        return cVersionMap;
    },
    
    showToast : function(title, message, type){
        var toast = $A.get("e.force:showToast");       
        toast.setParams({
            "title": title,
            "message": message,
            "type" : type
        });
        toast.fire();
    },
    errorHandler : function(message) {
        var idxStack = message.indexOf("STACK TRACE:");
        var msg = idxStack != -1 ? message.substring(0, idxStack-1) : message;
        var idx = msg.indexOf("first error:");
        var errMsg = idx != -1 ? msg.substring(idx + 13, msg.length) : 'Something went wrong. Please contact your System Administrator.';
        
        while(errMsg.includes('&quot;')){
            errMsg = errMsg.replace('&quot;', '');
        }
        
        if(errMsg.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
            errMsg = errMsg.replace('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', '');
            var messages = errMsg.split(':');
            var valMsg = '';
            for(var i=0; i< messages.length - 1; i++){
                valMsg = valMsg + messages[i];
            }
            errMsg = valMsg;
        }
        return errMsg;
    }
})