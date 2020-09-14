({
    getRelatedList: function(component){
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        console.log(userId);
        var action = component.get("c.getUserAccessibility");
        action.setParams({ 
            "caseId" : component.get("v.recordId"),
            "currentUserId": userId
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
			var res = response.getReturnValue();
            
            if(state === "SUCCESS"){
                console.log('userId: '+userId);
                console.log('Apex LoggedIn UserId: '+res.Success_Message);
                
                console.log('res.Is_Files_Accessible: '+res.Is_Files_Accessible);
                if(res.Is_Files_Accessible == 'YES'){
                    
                    component.set("v.showFiles", true);
                    this.getFilesRelatedList(component);
                    
                }
                console.log('res.Is_Notes_Accessible: '+res.Is_Notes_Accessible);
                if(res.Is_Notes_Accessible == 'YES'){
                    
                    component.set("v.showNotes", true);
                    this.getNotesRelatedList(component);
                    
                }
                
                if(res.Exception_Message !== null){
                    
                 }else{
                    component.set("v.showError", true);
                    component.set("v.recordError", res.Exception_Message);
                }
                
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.set("v.showError", true);
                        component.set("v.recordError", errors[0].message);
                    }
                } else {
                    component.set("v.showError", true);
                    component.set("v.recordError", "Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    
	getFilesRelatedList : function(component) {
		var action = component.get("c.getRelatedFiles");
        action.setParams({ 
            "caseId" : component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS"){
                
                var filesRelatedList = response.getReturnValue();
                for(var key in filesRelatedList){
                    component.set("v.totalFiles", key);
                	component.set("v.FilesRelatedList", filesRelatedList[key]);
                    if(filesRelatedList[key].length > 0){
                    	component.set("v.hasFiles", true);
                    }
                    else{
                        component.set("v.hasFiles", false);
                    }
                    
                    console.log('key: '+key);
                    console.log('Detail: '+filesRelatedList[key]);
                }
                
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.set("v.showErrorInFiles", true);
                        component.set("v.filesError", errors[0].message);
                    }
                } else {
                    component.set("v.showErrorInFiles", true);
                    component.set("v.filesError", "Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
	},
    
    getNotesRelatedList : function(component) {
		var action = component.get("c.getRelatedNotes");
        action.setParams({ 
            "caseId" : component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS"){
                
                var notesRelatedList = response.getReturnValue();
                for(var key in notesRelatedList){
                    component.set("v.totalNotes", key);
                	component.set("v.NotesRelatedList", notesRelatedList[key]);
                    if(notesRelatedList[key].length > 0){
                    	component.set("v.hasNotes", true);
                    }
                    else{
                        component.set("v.hasNotes", false);
                    }
                    
                    console.log('key: '+key);
                    console.log('Detail: '+notesRelatedList[key]);
                }
                
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.set("v.showErrorInNotes", true);
                        component.set("v.notesError", errors[0].message);
                    }
                } else {
                    component.set("v.showErrorInNotes", true);
                    component.set("v.notesError", "Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
	},
    
    gotoFilesRelatedList : function (component, event) {
        var relatedListEvent = $A.get("e.force:navigateToRelatedList");
        relatedListEvent.setParams({
            "relatedListId": "AttachedContentDocuments",
            "parentRecordId": component.get("v.recordId")
        });
        relatedListEvent.fire();
    },
    
    gotoNotesRelatedList : function (component, event) {
        var relatedListEvent = $A.get("e.force:navigateToRelatedList");
        relatedListEvent.setParams({
            "relatedListId": "AttachedContentNotes",
            "parentRecordId": component.get("v.recordId")
        });
        relatedListEvent.fire();
    },
    
    showToast : function(component, state, title, message){
        var eventHandler = $A.get("e.c:ToastEvent");
        
        eventHandler.setParams({
            state : state,
            title : title,
            message : message
        });
        
        eventHandler.fire();
    }
})