({
	init : function(component, event, helper) {
        console.log('recordIdInPriceList', component.get("v.usableArea"));
        var usableA = component.get("v.usableArea");
		var action = component.get("c.getPriceList");
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
                    product.price = conts[key] * usableA;
                    product.rentPerSqm = conts[key];
                    priceData.push(product);
                }
                //console.log('priceData', priceData);
                component.set("v.priceData", priceData);
                component.set("v.productLabel", [
                {label: 'Product', fieldName: 'productName', type: 'text'},
                {label: 'Price Per Unit', fieldName: 'rentPerSqm', type: 'currency', typeAttributes: { currencyCode: 'AUD'}},
                {label: 'Price', fieldName: 'price', type: 'currency', typeAttributes: { currencyCode: 'AUD'}}
                
            ]);
            } else {
                
            }
 		});
        $A.enqueueAction(action);		
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
                    product.price = conts[key] * inputArea;
                    product.rentPerSqm = conts[key];
                    priceData.push(product);
                }
                component.set("v.priceData", priceData);
                component.set("v.productLabel", [
                {label: 'Product', fieldName: 'productName', type: 'text'},
                {label: 'Price Per Unit', fieldName: 'rentPerSqm', type: 'currency', typeAttributes: { currencyCode: 'AUD'}},
                {label: 'Price', fieldName: 'price', type: 'currency', typeAttributes: { currencyCode: 'AUD'}}
            
            ]);
            } else {
                
            }
 		});           
        $A.enqueueAction(action);	
        }
    }
})