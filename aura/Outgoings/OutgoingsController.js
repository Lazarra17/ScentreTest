({
    init : function(component, event, helper) {
        component.set('v.draftValues', []);
        helper.getData(component);
        helper.verifyUserAccess(component);
    },
    areaChange : function(component, event, helper) {
        var inputArea = component.get("v.recoverableArea");
        var action = component.get("c.getPriceList");
        
        //Need to move to helper
        if (inputArea > 0) {
            action.setParams({
                "opportunityId": component.get("v.recordId")
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    
                    var priceData = [];
                    var conts = response.getReturnValue();
                    for(var key in conts){
                        var product = {};
                        product.productName = key;
                        product.rentPerSqm = conts[key];
                        
                        var priceNotRounded = conts[key] * inputArea;
                        product.price = priceNotRounded.toFixed(2);
                        
                        priceData.push(product);
                    }
                    component.set("v.priceData", priceData);
                    
                } else {
                    
                }
            });           
            $A.enqueueAction(action);	
        }
    },
    
    refreshOutgoingsCtrl : function(component, event, helper){
        component.set("v.isShow", true);
        helper.refreshOutgoingsHelper(component);
    },
    
    handleCancel: function(cmp, event, helper) {
        helper.clearDraftValuesLS();
    },
    handleEditCell: function(cmp, event, helper) {
        helper.handleEditCell(cmp, event);
    },
    handleSave: function(cmp, event, helper) {
        
        var draftValues = event.getParam('draftValues');
        cmp.set("v.isShow", true);
        helper.saveChanges(cmp, draftValues);
        helper.getData(cmp);
        $A.get('e.force:refreshView').fire();
    },
    updatearea: function(cmp, event, helper) {
       	var draftValues = cmp.get("v.mydata");
        
        cmp.set("v.isShow", true);
        
        helper.updateQuantity(cmp, draftValues);
        $A.get("e.force:refreshView").fire();
    } 
})