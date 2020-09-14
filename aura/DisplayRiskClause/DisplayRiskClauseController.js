({
    doInit: function (component, event, helper) {
        helper.onDoInit(component, event, helper);
        helper.getHelpText(component)
    },
    
    gotoBack: function (component, event, helper) {
        helper.back(component, event, helper);
    }
})