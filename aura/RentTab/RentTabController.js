({
    save : function(component, event, helper) {
        var saveRentCalc = component.find("rentCalcComponent");
        saveRentCalc.saveDetails();
        
        var savePercentageRent = component.find("percentRentComponent");
        savePercentageRent.saveDetails();
        
        var saveOpptykeydates = component.find("keydatesComponent");
        saveOpptykeydates.savekeydates();
    },
    calculate : function(component, event, helper) {
        var calculateRent = component.find("rentCalcComponent");
        calculateRent.calculateDetails();
        var calculatePercent = component.find("percentRentComponent");
        calculatePercent.calculateDetails();
    }
    
    
})