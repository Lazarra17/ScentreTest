({
	init : function(component, event, helper) {
		var action = component.get("c.getChangedItem");
        console.log('id', component.get('v.recordId'));
        action.setParams({
            oppoId : component.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            if(state === "SUCCESS" && getReturn.status === "SUCCESS") {
                var retVal;
                if(getReturn.returnValue){
                    let counter = 0;
                    retVal = JSON.parse(getReturn.returnValue);
                    console.log('retVal', retVal);
                    var rentVarianceColorJ = '';
                    for(var i = 0; i < retVal.length; i++) {
                        var obj = retVal[i];
                        console.log('obj', obj);
                        console.log(obj.label);
                    	if (obj.label === 'Rent Variance %' && obj.isChanged) {
                            component.set("v.rentVarianceColor", "red");
                        } 
                        if (obj.label === 'Annual Minimum Rent' && obj.isChanged) {
                            component.set("v.annualMinColor", "red");
                        }
                        if (obj.label === 'Proposed Start Date' && obj.isChanged) {
                            component.set("v.proposedStartDateColor", "red");
                        }
                        if (obj.label === 'Term (Year)' && obj.isChanged) {
                            component.set("v.termYearColor", "red");
                        }
                        if (obj.label === 'Term (Months)' && obj.isChanged) {
                            component.set("v.termMonthColor", "red");
                        }
                        if (obj.label === 'Term (Days)' && obj.isChanged) {
                            component.set("v.termDayColor", "red");
                        }
                        if (obj.label === 'Total Forecast Capital' && obj.isChanged) {
                            component.set("v.totalForecastCapitalColor", "red");
                        }
                        if (obj.label === 'Capital Variance %' && obj.isChanged) {
                            component.set("v.capitalVarianceColor", "red");
                        }
                        if (obj.label === 'Forecasted Percentage Rent (Year 1)' && obj.isChanged) {
                            component.set("v.forecastPRentYear1Color", "red");
                        }
                        if (obj.label === 'Total Promotion Levy' && obj.isChanged) {
                            component.set("v.totalPromoLevyColor", "red");
                        }
                    }

                }
            } else {
            	console.log(getReturn);
            }
        });
        $A.enqueueAction(action);
    }
})