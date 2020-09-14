({
    doInit : function(component, event, helper) {
        helper.getTasks(component);
    },
    toggleCheckBox : function(component, event, helper) {
        helper.toggleCheckbox(component,event);
    },
    toggleButton : function(component, event, helper) {
        if(event.getParam("value") == "delete") {
            helper.deleteTask(component, event);
        } else {
            var modalBody;
            $A.createComponent("c:EditTaskModal", {
                "taskId" : event.getSource().get("v.name")
            },
                               function(content, status) {
                                   if (status === "SUCCESS") {
                                       modalBody = content;
                                       component.find('overlayLib').showCustomModal({
                                           header: "Edit Task",
                                           body: modalBody, 
                                           showCloseButton: true,
                                           closeCallback: function() {
                                               $A.get('e.force:refreshView').fire();
                                               helper.getTasks(component);
                                           }
                                       })
                                   }                               
                               });
        }
    }
})