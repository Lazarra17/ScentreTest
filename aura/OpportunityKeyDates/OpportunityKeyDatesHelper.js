({
    getRecordType : function (component, event, helper) {
        var recordType = component.get("v.targtefieldRecord.RecordType.DeveloperName");
        if(recordType === 'OPP_StoreRoomLeasing'){
            component.set("v.isStoreRoom", false);
        }
        
    },
    
    showToast : function(component, title, type, message){
        var toast = component.find("toast-keyDates");
        
        toast.set("v.title", title);
        toast.set("v.state", type);
        toast.set("v.message", message);
        
        toast.showToast();
    },
    
    /*calculateTerms : function(proposedStartDate, proposedEndDate){
        let terms = {};
        
        terms.days = 0;
        terms.months = 0;
        terms.years = 0;
        
        console.log("proposedEndDate.years() : ", proposedEndDate.years());
        console.log("proposedEndDate.months() : ", proposedEndDate.months());
        console.log("proposedEndDate.days() : ", proposedEndDate.date());
        
        console.log("proposedStartDate.years() : ", proposedStartDate.years());
        console.log("proposedStartDate.months() : ", proposedStartDate.months());
        console.log("proposedStartDate.days() : ", proposedStartDate.date());
        
        if(proposedEndDate.years() > proposedStartDate.years()){
            terms.years = proposedEndDate.years() - proposedStartDate.years();
        }
        
        if(proposedEndDate.months() >= proposedStartDate.months()){
            terms.months = proposedEndDate.months() - proposedStartDate.months();
        } else {
            terms.years = (terms.years > 0) ? terms.years - 1 : 0;
            terms.months = proposedEndDate.months() + (12 - proposedStartDate.months());
        }
        
        let defaultMonth = 30;
        if(proposedEndDate.months() == 0 || proposedEndDate.months() == 2 || proposedEndDate.months() == 4 || proposedEndDate.months() == 6
           || proposedEndDate.months() == 7 || proposedEndDate.months() == 9 || proposedEndDate.months() == 11){
            defaultMonth = 31;
        } else if(proposedEndDate.months() == 1){
            defaultMonth = 28;
        }
        
        if(proposedEndDate.date() >= proposedStartDate.date()){
            terms.days = proposedEndDate.date() - proposedStartDate.date();
        } else {
            terms.months = (terms.months > 0) ? terms.months - 1 : 0;
            terms.days = proposedEndDate.date() + (defaultMonth - proposedStartDate.date());
        }
        
        terms.days = terms.days == (defaultMonth - 1) ? 0 : terms.days + 1;
        
        console.log("terms : ", terms);
        
        return terms;
    },*/
    
    calculateEndDateDifference : function(startDate, endDate) {
        var interval = ['years', 'months', 'days'];
        var diff;
        var diffInterval = [];
        for(var i = 0; i < interval.length; i++) {
            diff = endDate.diff(startDate, interval[i]);
            startDate = startDate.add(diff, interval[i]);
            diffInterval[interval[i]] = diff;
        }
        return diffInterval;
    }
})