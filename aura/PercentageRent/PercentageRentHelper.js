({
	prepopulateOccupancyCost : function(component) {
		component.set("v.occupancycost", component.get("v.oRecord.OccupancyCost__c"));
		
	},
		calculate : function(component) {
            
            if(!component.get("v.avoidRecurr")){
              	component.set("v.avoidRecurr", true); 
                var totalPromoLevy = Number(component.get("v.totalPromoLevy"));
                var totalOutgoings = Number(component.get("v.totalOutgoings"));
                var rent = Number(component.get("v.rent"));
                console.log("PENCET &&& "+ component.get("v.oRecord.PercentageRentPercent__c"));
                var percentageRent = Number(component.get("v.oRecord.PercentageRentPercent__c"));
                var foreTurnoverYear = Number(component.get("v.oRecord.ForecastedTurnoverYear1__c"));
                component.set("v.breakAmount",component.get("v.oRecord.BreakAmount__c"));
                    /*if(component.get("v.breaktType")){
                        
                    }else{
                        component.set("v.breaktType","Natural");
                    }*/
                var breaktye = component.get("v.breakTypeattribb");
                if (!component.get("v.initRun") && breaktye === "Natural" && rent !== "" && percentageRent !== "" && percentageRent !==0) {
                   component.set("v.breakAmount", (rent / percentageRent * 100).toFixed(2));
                    
                }
                var breakamt = Number(component.get("v.breakAmount"));
                //alert(breaktye);
                if(breaktye === "Artificial"){
                    component.set("v.forecastedpercentagerentyear", (foreTurnoverYear - breakamt) * percentageRent * .01);
                }else if(rent !== "" && percentageRent !== "" && foreTurnoverYear !== "") {
                    component.set("v.forecastedpercentagerentyear", (foreTurnoverYear * percentageRent * .01) - rent);
                }
                var forePercentYear = component.get("v.forecastedpercentagerentyear");
                if(totalPromoLevy === ""){
                        totalPromoLevy=0;
                 }
                if(totalOutgoings === ""){
                        totalOutgoings=0;
                 }
                 if(forePercentYear === ""||forePercentYear<0){
                     forePercentYear=0;
                     component.set("v.forecastedpercentagerentyear",0.00);
                 }
                 if(rent === ""){
                        rent=0;
                 }
                if (rent !== "" && foreTurnoverYear !== "" && foreTurnoverYear !==0) {
                    let occupancyCost = (((rent + totalPromoLevy + totalOutgoings + forePercentYear) / foreTurnoverYear)*100);
                    
                    console.log("occupancyCost : ", occupancyCost);
                    console.log("occupancyCost.toFixed(2) : ", occupancyCost.toFixed(2));
                    
                    component.set("v.occupancycost", occupancyCost.toFixed(2));
                    if(component.get("v.occupancycost") === "Infinity%"){
                        component.set("v.occupancycost", 0);
                    }
                } 
                component.set("v.avoidRecurr", false); 
            }
       
            
	},
	checkBreakTypeValue : function(component) {
		if(component.get("v.oRecord.BreakType__c") === "Artificial"){
			component.set("v.isArtificial", true);
            component.set("v.breakTypeattribb","Artificial");
		}else{
			component.set("v.isArtificial", false);
            component.set("v.breakTypeattribb","Natural");
		}
		
	},
    populateOppFields : function(component){
        component.set("v.oRecord.BreakType__c",component.get("v.breakTypeattribb"));
        component.set("v.oRecord.ForecastedPercentageRentYear1__c",component.get("v.forecastedpercentagerentyear"));
        component.set("v.oRecord.BreakAmount__c",component.get("v.breakAmount"));
    },
    
    showToast : function(component, title, type, message){
        var toast = component.find("toast-percent");
        
        toast.set("v.title", title);
        toast.set("v.state", type);
        toast.set("v.message", message);
        
        toast.showToast();
    }
})