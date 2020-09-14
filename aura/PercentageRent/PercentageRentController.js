({
	init : function(component, event, helper) {
		// component.set("v.pecentageRentInput", component.get("v.pecentageOfRent"));
		component.set("v.initRun", true);
	//	component.set("v.breakTypeattribb","Natural");
		window.setTimeout(
                    $A.getCallback(function() {
                        helper.checkBreakTypeValue(component);
						helper.calculate(component);
                        helper.prepopulateOccupancyCost(component);
                    }), 2000
                );
	},
    calculatePercentageRent : function(component, event, helper) {
		component.set("v.oRecord.BreakType__c",component.get("v.breakTypeattribb"));
		component.set("v.oRecord.BreakAmount__c",component.get("v.breakAmount"));
		component.set("v.initRun", false);
		helper.calculate(component);
	},
    savePercentageRent : function (component, event, helper) {
        console.log("SAVE &&& "+ component.get("v.oRecord.PercentageRentPercent__c"));
        if(component.get("v.oRecord.PercentageRentPercent__c") !== null && component.get("v.oRecord.PercentageRentPercent__c") !== "" &&
		component.get("v.oRecord.ForecastedTurnoverYear1__c") !== null && component.get("v.oRecord.ForecastedTurnoverYear1__c") !== ""){  
            helper.populateOppFields(component);  
            component.find('percentageRentRec').saveRecord(function(saveResult) {
				if(saveResult.state ==="SUCCESS") {
                    helper.showToast(component, "Success!", "success", "The calculation is saved");
				} else {
					var errMsg = "";
					for (var i = 0; i < saveResult.error.length; i++) {
						errMsg += saveResult.error[i].message + "\n";
						console.log('ERROR MESSAGE: ' + errMsg);
					}
					
                    helper.showToast(component, "Failed!", "error", saveResult.state + " " + errMsg) 
				}
            });
        }
    },
    populateOppFieldsRent : function(component, event, helper){
        if(component.get("v.oRecord.PercentageRentPercent__c") !== null && component.get("v.oRecord.PercentageRentPercent__c") !== "" &&
           component.get("v.oRecord.ForecastedTurnoverYear1__c") !== null && component.get("v.oRecord.ForecastedTurnoverYear1__c") !== ""){
            helper.populateOppFields(component);  
        }
        
    }
})