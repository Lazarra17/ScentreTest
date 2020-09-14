({
	doInit : function(component, event, helper) {
        helper.getRelatedList(component);
	},
  	
    handleUploadFinished: function(component,event,helper){
        helper.showToast(component, 'SUCCESS', 'File(s) Uploaded successfully','');
        helper.getRelatedList(component);
    },
    
    addNotes: function(component,event,helper){
        component.set("v.isModalOpen", true);
    },
    
    closeModal: function(component,event,helper){
    	component.set("v.isModalOpen", false);
	},
    
    addFiles: function(component,event,helper){
        helper.gotoFilesRelatedList(component, event);
    },
    
    viewAllFiles: function(component,event,helper){
        helper.gotoFilesRelatedList(component, event);
    },
    
    viewAllNotes: function(component,event,helper){
        helper.gotoNotesRelatedList(component, event);
    },
    
    saveNote: function(component,event,helper){
        component.set("v.showSpinner", true);
        var newNote = component.get("v.note");
        var action = component.get("c.createNewNote");
        action.setParams({
            "noteRec" : newNote,
            "caseId" : component.get("v.recordId")
        });
        
        action.setCallback(this, function(response){
            component.set("v.showSpinner", false);
            var state = response.getState();
            var res = response.getReturnValue();
            
            if(state === "SUCCESS"){
                if(res.Success_Message == 'New Note Created Successfully'){
                    helper.showToast(component, 'SUCCESS', res.Success_Message ,'');
                    var note = {'sobjectType': 'ContentNote',
                                        'Title': '',
                                        'Content': ''
                                       };
                    component.set("v.note",note);
                    helper.getRelatedList(component);
                }
                else{
                    helper.showToast(component, 'EXCEPTION', res.Success_Message ,'');
                }
            } 
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
               			 helper.showToast(component, 'ERROR', 'Note Cannot be Created',errors[0].message);
                    }
                } else {
                    helper.showToast(component, 'ERROR', 'UNKNOWN ERROR','');
                }
            }
        });
        
        $A.enqueueAction(action);
        component.set("v.isModalOpen", false);
    }
    
})