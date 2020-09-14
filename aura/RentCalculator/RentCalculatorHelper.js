({
    getBudgetDataRec : function(component) {
        
        var getBudgetData = component.get("c.getBudgetData");
        
        
        if(component.get('v.simpleRecordEdit.AnnualMinimumRent__c')==='' || component.get('v.simpleRecordEdit.AnnualMinimumRent__c')===null ){
            var rent = 0;
        }else{
            var rent = component.get('v.simpleRecordEdit.AnnualMinimumRent__c');  
        }
        getBudgetData.setParams({
            opportunityId : component.get("v.recordId"),
            type : component.get('v.simpleRecordEdit.DealType__c'),
            rent : rent
        });
        getBudgetData.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            if(state === "SUCCESS"){
                component.set("v.budgetInfoList", getReturn);
            } else {
                console.log("ERROR");
            }
        });
        component.set('v.budgetInfoColumnList', [{label: 'BUDGET TYPE', fieldName: 'BudgetType', type: 'text'},
                                                 {label: 'BUDGET', fieldName: 'Budget', type: 'currency', cellAttributes: {alignment: 'left'}},
                                                 {label: 'VARIANCE', fieldName: 'Variance', type: 'currency', cellAttributes: {alignment: 'left'}}]);	
        
        $A.enqueueAction(getBudgetData);
    },
    refreshPromoFundCheckbox : function(component) {
        
        if(component.get('v.simpleRecord.PromoLevyIncluded__c')==='Yes'){
            component.set("v.promotionFundInclude", true);
        }else{
            component.set("v.promotionFundInclude", false);
        }
    },
    toggleSpinner : function(component){
        var spinner = component.find("spinner")        
        $A.util.toggleClass(spinner, "slds-hide");
    },
    saveDisplayDates : function(component) {
        if(component.get("v.displaykeydays")){
            var opptykeydates = component.find("keydatesComponent");
            opptykeydates.savekeydates();
        }
    },
	saveRentLDS : function(component) {
        let self = this;
		component.find(component.get("v.recordHandlerAttr")).saveRecord($A.getCallback(function(saveResult) {
                    // NOTE: If you want a specific behavior(an action or UI behavior) when this action is successful 
                    // then handle that in a callback (generic logic when record is changed should be handled in recordUpdated event handler)
                   console.log("SAVE RESULT"+saveResult.state);
                    if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                        self.showToast(component, "success", "Success!", "Rent details are updated.");
                    } else if (saveResult.state === "INCOMPLETE") {
                        console.log("User is offline, device doesn't support drafts.");
                    } else if (saveResult.state === "ERROR") {
                        console.log('Problem saving record, error: ' + JSON.stringify(saveResult.error));
                        var errMsg = "";
                        
                        for (var i = 0; i < saveResult.error.length; i++) {
                            errMsg += saveResult.error[i].message + "\n";
                        }
                        
                        self.showToast(component, "error", "Failed!", errMsg);
                    } else {
                        console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
                    }
            component.set("v.showSpinner", false);
        }));
	},
	calculate : function(component) {
		var validExpense = true;
        let self = this;
		try {
			if (validExpense && component.get("v.simpleRecordEdit.AnnualMinimumRent__c") !== "" && component.get("v.simpleRecordEdit.AnnualMinimumRent__c") !== null) {
				var action = component.get("c.getRentInfo");
				action.setParams({
					"opportunityId": component.get("v.recordId"),
					"currentRent": component.get("v.simpleRecordEdit.AnnualMinimumRent__c"),
					"grossRent" : component.get("v.grossSales"),
					"pecentageOfRent" : component.get("v.pecentageOfRent"),
					"isPromotionIncluded" : component.get("v.promotionFundInclude"),
					"leaseType" : component.get('v.simpleRecordEdit.DealType__c'),
					"isNZProperty" : component.get("v.isNZProperty"),
					"nzProperty" : component.get("v.nzProperty"),
					"promoThresholdApplies" : component.get("v.promoThresholdApplies"),
				});
                console.log('getRentInfo params ' + JSON.stringify(action.getParams()));
				// Add callback behavior for when response is received
				action.setCallback(this, function(response) {
					var state = response.getState();
					console.log('getRentInfo response ' + JSON.stringify(response));
					if (state === "SUCCESS") {
						var conts = response.getReturnValue();
                        console.log('getRentInfo return ' + JSON.stringify(conts));
						for(var key in conts){
							if (key === 'PromotionFund') {
								component.set('v.promotionFund', conts[key]);
							}
							if (key === 'PercentageRent') {
								component.set('v.pecentageRent', conts[key]); 
							}
						}
						/*if(component.get("v.initRun") && component.get("v.simpleRecordEdit.TotalPromotionLevy__c") !== 0 && component.get("v.simpleRecordEdit.TotalPromotionLevy__c") !== "" && component.get("v.simpleRecordEdit.TotalPromotionLevy__c") !== null){
                            component.set('v.promotionFund', component.get("v.simpleRecordEdit.TotalPromotionLevy__c")); 	
						}*/
                        
                        
                        component.set('v.totalOutgoings', component.get("v.simpleRecordEdit.TotalOutgoings__c"));
                        
                        const annualMinRent = parseFloat(component.get('v.simpleRecordEdit.AnnualMinimumRent__c'));
                        const percentageRent = component.get('v.simpleRecordEdit.PercentageRentAmount__c');
                        const totalOutgoings = component.get('v.totalOutgoings');
                        const promoFund = component.get('v.promotionFund');
                        const total = annualMinRent + percentageRent + promoFund + totalOutgoings;
						/*
						console.clear();
                        console.log('totalOutgoings: ', totalOutgoings);
                        console.log('promotionFund: ', promoFund);
                        console.log('AnnualMinimumRent__c: ', annualMinRent);
                        console.log('PercentageRentAmount__c: ', percentageRent);
                        console.log('TOTAL: ', total);
                        */
						component.set('v.totalGrossRent', total);
                        
					}
					else {
                        let errors = response.getError();
						self.showToast(component, "error", "Failed!", errors[0].message);
					}
					if(component.get("v.promotionFundInclude") === false){
						component.set('v.promotionFund', ''); 
					}
                    if(!component.get("v.initRun")){
                        
						var modal = component.find("percentRentComponent");
						modal.calculateDetails();
                    }

				});
				// Send action off to be executed
				$A.enqueueAction(action);   
			}
			
			
			this.getBudgetDataRec(component);
		}catch (e) {
			
		}	
    },
    
    showToast : function(component, type, title, message){
        let toast = component.find("toastRent");
        
        toast.set("v.title", title);
        toast.set("v.state", type);
        toast.set("v.message", message);
        
        toast.showToast();
    }
})