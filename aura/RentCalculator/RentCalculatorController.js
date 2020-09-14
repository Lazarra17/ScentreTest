({
    handleRent : function(component, event, helper) {
		component.set("v.recordHandlerAttr", "");
        component.set("v.showSpinner", true);
		var percentageRent = component.find("percentRentComponent");
        percentageRent.populateOppFieldsPercRent();
		var percentageRentOpp = percentageRent.get("v.oRecord");
		component.set("v.simpleRecordEdit.PercentageRentPercent__c",percentageRentOpp.PercentageRentPercent__c);
		component.set("v.simpleRecordEdit.ForecastedTurnoverYear1__c",percentageRentOpp.ForecastedTurnoverYear1__c);
		component.set("v.simpleRecordEdit.ReasonForArtificialBreak__c",percentageRentOpp.ReasonForArtificialBreak__c);
		component.set("v.simpleRecordEdit.BreakType__c",percentageRentOpp.BreakType__c);
		component.set("v.simpleRecordEdit.BreakAmount__c",percentageRentOpp.BreakAmount__c);
		component.set("v.simpleRecordEditNoRent.PercentageRentPercent__c",percentageRentOpp.PercentageRentPercent__c);
		component.set("v.simpleRecordEditNoRent.ForecastedTurnoverYear1__c",percentageRentOpp.ForecastedTurnoverYear1__c);
		component.set("v.simpleRecordEditNoRent.ReasonForArtificialBreak__c",percentageRentOpp.ReasonForArtificialBreak__c);
		component.set("v.simpleRecordEditNoRent.BreakType__c",percentageRentOpp.BreakType__c);
		component.set("v.simpleRecordEditNoRent.BreakAmount__c",percentageRentOpp.BreakAmount__c);
		component.set("v.simpleRecordEditNoRent.FitoutContribution__c",component.get("v.simpleRecordEdit.FitoutContribution__c"));
		
   		if(component.get("v.displaykeydays")){
			var oppKeyDates = component.find("keydatesComponent");
			var keyDatesOpp = oppKeyDates.get("v.targtefieldRecord");
			component.set("v.simpleRecordEdit.ProposedHandoverDate__c",keyDatesOpp.ProposedHandoverDate__c);
			component.set("v.simpleRecordEdit.FitoutDays__c",keyDatesOpp.FitoutDays__c);     
			component.set("v.simpleRecordEdit.TermYr__c",keyDatesOpp.TermYr__c);  
			component.set("v.simpleRecordEdit.TermMonths__c",keyDatesOpp.TermMonths__c);  
			component.set("v.simpleRecordEdit.TermDays__c",keyDatesOpp.TermDays__c);  
			component.set("v.simpleRecordEdit.ProposedStartDate__c",keyDatesOpp.ProposedStartDate__c);  
			component.set("v.simpleRecordEdit.ProposedRentCommencementDate__c",keyDatesOpp.ProposedRentCommencementDate__c);  
			component.set("v.simpleRecordEdit.ProposedEndDate__c",keyDatesOpp.ProposedEndDate__c);          
			component.set("v.simpleRecordEdit.CloseDate",keyDatesOpp.CloseDate);
            component.set("v.simpleRecordEdit.ProposedShopOpeningDate__c",keyDatesOpp.ProposedShopOpeningDate__c);
			component.set("v.simpleRecordEditNoRent.ProposedHandoverDate__c",keyDatesOpp.ProposedHandoverDate__c);
			component.set("v.simpleRecordEditNoRent.FitoutDays__c",keyDatesOpp.FitoutDays__c);     
			component.set("v.simpleRecordEditNoRent.TermYr__c",keyDatesOpp.TermYr__c);  
			component.set("v.simpleRecordEditNoRent.TermMonths__c",keyDatesOpp.TermMonths__c);  
			component.set("v.simpleRecordEditNoRent.TermDays__c",keyDatesOpp.TermDays__c);  
			component.set("v.simpleRecordEditNoRent.ProposedStartDate__c",keyDatesOpp.ProposedStartDate__c);  
			component.set("v.simpleRecordEditNoRent.ProposedRentCommencementDate__c",keyDatesOpp.ProposedRentCommencementDate__c);  
			component.set("v.simpleRecordEditNoRent.ProposedEndDate__c",keyDatesOpp.ProposedEndDate__c);   	
			component.set("v.simpleRecordEditNoRent.CloseDate",keyDatesOpp.CloseDate);
            component.set("v.simpleRecordEditNoRent.ProposedShopOpeningDate__c",keyDatesOpp.ProposedShopOpeningDate__c);
		}
		
        var finalenddate=component.get("v.simpleRecordEdit.ProposedEndDate__c");
        var backoutperiod = ["10","11","12","01","02","03"];
        if(moment(finalenddate).format("MM")!=null){
            if(backoutperiod.includes(moment(finalenddate).format("MM"))){
                helper.showToast(component, "warning", "Success!", "Proposed End Date falls under blackout Period.");
            }
        }
        // LDS Saving record
        var proposedminimumRent=component.get("v.simpleRecordEdit.AnnualMinimumRent__c");
        if(proposedminimumRent!==""&&proposedminimumRent!==0){
            if(component.get("v.simpleRecordEdit.Type")!=="New Lease"){
                component.set("v.simpleRecordEdit.RentInAdvance__c",proposedminimumRent/12);
            }else{
                component.set("v.simpleRecordEdit.RentInAdvance__c",0);
            }
            
        }
        var action = component.get("c.createOPPLineItemWithRent");
        action.setParams({
            "opportunityId": component.get("v.recordId"),
            "rent": component.get("v.simpleRecordEdit.AnnualMinimumRent__c"),
            "grossRent" : component.get("v.grossSales"),
            "pecentageOfRent" : component.get("v.pecentageOfRent"),
            "leaseType" : component.get('v.simpleRecordEdit.DealType__c'),
            "isPromoIncluded" : component.get('v.promotionFundInclude'),
            "tresholdApplies" : component.get('v.promoThresholdApplies'),
            "isNZProperty" : component.get("v.isNZProperty"),
            "nzProperty" : component.get("v.nzProperty")
        });
        // Add callback behavior for when response is received
       console.log("BEFORE CALCULATED");
        if(component.get("v.calculated")){
		   action.setCallback(this, function(response) {
				console.log("INSIDE SAVE");
				var state = response.getState();
				var res = response.getReturnValue(); 
				if (state === "SUCCESS" && res.status === "SUCCESS") {
					var res = response.getReturnValue(); 
					var oppParent = component.get("v.simpleRecordEdit");
					if(res.isPromoLevy === true){
						oppParent.PromoLevyIncluded__c = 'Yes';
					}else{
						oppParent.PromoLevyIncluded__c = 'No';
					}
					component.set("v.simpleRecordEdit", oppParent);
					component.set('v.promotionFundInclude', res.isPromoLevy);
					component.set("v.recordHandlerAttr", "recordHandler");
					helper.saveRentLDS(component);
				}
				else {
					//save only 2
					component.set("v.recordHandlerAttr", "recordHandlerNoRent");
					helper.saveRentLDS(component);
					let errors = response.getError();
					console.log('errorMessage', response.getError());
					
					helper.showToast(component, "Failed", "error!", "No base rent or promo products available for selected Space, Billing Category and Deal Type.");
				}
				component.set("v.calculated", false);
			});  
			 $A.enqueueAction(action);
             //component.set("v.recordHandlerNoRent",component.get("v.recordHandler"));
            component.set("v.simpleRecordEditNoRent.AnnualMinimumRent__c", component.get("v.simpleRecordEdit.AnnualMinimumRent__c"));
            component.set("v.simpleRecordEditNoRent.DealType__c", component.get("v.simpleRecordEdit.DealType__c"));
            component.set("v.simpleRecordEditNoRent.PercentageRentIncluded__c", component.get("v.simpleRecordEdit.PercentageRentIncluded__c"));
            component.set("v.simpleRecordEditNoRent.RentInAdvance__c", component.get("v.simpleRecordEdit.RentInAdvance__c"));
            component.set("v.simpleRecordEditNoRent.AnnualMinimumRent__c", component.get("v.simpleRecordEdit.AnnualMinimumRent__c"));
        }else if(!component.get("v.calculated")){
			component.set("v.recordHandlerAttr", "recordHandlerNoRent");
			helper.saveRentLDS(component);
			component.set("v.calculated", false);
        }
    
   
    
 /*   window.setTimeout(
    $A.getCallback(function() {
    helper.saveDisplayDates(component);
    }), 2000
    );*/

    //percentageRent.saveDetails();
    $A.get('e.force:refreshView').fire();      
	},
    rentCalculate : function(component, event, helper) {
        component.set("v.initRun", false);
        component.set("v.calculated", true);
        helper.calculate(component);
    
	},
    doInit : function(component, event, helper) {
        var action = component.get("c.getMoreValue");
        component.set("v.initRun", true);
        action.setParams({
            "opportunityId": component.get("v.recordId")
        });
        // Add callback behavior for when response is received
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var conts = response.getReturnValue();
                if (conts.status === "SUCCESS") {
                    component.set('v.spaceType', conts.spaceType);  
                    component.set('v.userUITheme', conts.userUITheme);
                    component.set('v.nzProperty', conts.nzProperty);  
                    component.set('v.promotionFundInclude', conts.isPromoLevy);
                    component.set('v.totpromolevy', conts.totpromolevy);
                    //alert(component.get('v.nzProperty'));
                    if(component.get('v.nzProperty')){ 
                        component.set('v.isNZProperty', true); 
                    }
                    if(conts.userUITheme==$A.get("$Label.MobileAppTheme")){
                        component.set("v.isLEX",false);
                    }
                    
                    if(conts.isPromoLevy){
                        helper.calculate(component);
                    }
                    
                    component.set('v.pecentageOfRent', conts.percentageRent);
                    
                }
                if(conts.hasEditAccess){
                    component.set('v.isReadOnly', false);
                }
                if(conts.dealAchieved){
                    component.set('v.isReadOnly', true);
                }
                
            }
        });
        
        
        // Send action off to be executed
        $A.enqueueAction(action);
        
        try {
            window.setTimeout(
                $A.getCallback(function() {
                    helper.refreshPromoFundCheckbox(component);
                    helper.calculate(component);
                }), 2000
            );
        }
        catch (e) {
            
        }		
        
        
    },
	onSelectChange : function(component, event, helper) {
		component.set("v.calculated", true);
		helper.getBudgetDataRec(component);
		
		
	},
            
	/**
	* Control the component behavior here when record is changed (via any component)
	*/
    handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "CHANGED") {
            // record is changed, so refresh the component (or other component logic)
        } else if(eventParams.changeType === "LOADED") {
            // record is loaded in the cache
        } else if(eventParams.changeType === "REMOVED") {
            // record is deleted and removed from the cache
        } else if(eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving or deleting the record
        }
    }

})