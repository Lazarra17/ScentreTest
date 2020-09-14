({
	getTasks : function(component) {
		var action = component.get("c.getTasksOfOpp");
        action.setParams({
            "oppId" : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            if(state === "SUCCESS" && getReturn.status === "SUCCESS") {
                var retVal;
                if(getReturn.returnValue){
                 	retVal = JSON.parse(getReturn.returnValue);
                    component.set("v.userAlias", getReturn.message);
                    component.set("v.tasksByStageList", retVal.allTaskList);
                    component.set("v.adhocTasksList", retVal.adhocTaskList);
                }
            } else {
                console.log(getReturn.message);
            }
        });
        $A.enqueueAction(action);
	},
    toggleCheckbox : function(component, event) {
        var action = component.get("c.updateTaskStatus");
        
        action.setParams({
            "taskId" : event.getSource().get("v.name")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            if(state === "SUCCESS" && getReturn.status === "SUCCESS") {
                console.log(getReturn.status);
                $A.get('e.force:refreshView').fire();
                this.getTasks(component);
            } else {
                event.getSource().set("v.checked", false);
                let errorMessage = this.errorHandler(getReturn.message);
                this.showToast(component, "error", "Error! Cannot Save Changes, Please Fix below Errors.", errorMessage);
            }
        });
        $A.enqueueAction(action);
    },
    deleteTask : function(component, event) {
        var action = component.get("c.deleteTask");
        action.setParams({
            "taskId" : event.getSource().get("v.name")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            if(state === "SUCCESS" && getReturn.status === "SUCCESS") {
                console.log(getReturn.status);
                this.getTasks(component);
            }
        });
        $A.enqueueAction(action);
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
    },
    showToast : function(component, type, title, message){
        var toast = component.find("toast");
        
        toast.set("v.title", title);
        toast.set("v.state", type);
        toast.set("v.message", message);
        
        toast.showToast();
    }
})