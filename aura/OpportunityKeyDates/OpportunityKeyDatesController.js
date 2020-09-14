({
    init : function(component, event, helper) {
        window.setTimeout(
            $A.getCallback(function() {
                helper.getRecordType(component, event, helper);
            }), 2000
        );     
    },
    changeTerm : function(component, event, helper) {
        var sourcefieldid=event.getSource().getLocalId();
        let targetFieldRecord = component.get("v.targtefieldRecord");
        let pEndDate = component.get("v.targtefieldRecord.ProposedEndDate__c");
        let pStartDate = component.get("v.targtefieldRecord.ProposedStartDate__c");
        let proposedRentDate = targetFieldRecord.ProposedRentCommencementDate__c;
        let mPEndDate = moment(pEndDate);
        let mPStartDate = moment(pStartDate);
        let mProposedRentDate = moment(proposedRentDate);
        let fitoutdays=0;
        
        if(component.get("v.targtefieldRecord.FitoutDays__c")!==null){
            fitoutdays=component.get("v.targtefieldRecord.FitoutDays__c");
        }
        
        if(sourcefieldid === "proposedStartDate"){
            if(targetFieldRecord.CurrencyIsoCode === "AUD"){
                component.set("v.targtefieldRecord.ProposedRentCommencementDate__c",pStartDate);
            } else if(targetFieldRecord.CurrencyIsoCode === "NZD"){
                component.set("v.targtefieldRecord.ProposedHandoverDate__c", pStartDate);
            }
        }
        
        let phandoverDate = component.get("v.targtefieldRecord.ProposedHandoverDate__c");
        let mPhandoverDate = moment(phandoverDate);
        
        if(sourcefieldid!=="proposedEndDate" && sourcefieldid!=="proposedHandoverDate" && sourcefieldid!=="proposedRentCommencementDate"){
            var termvalue,monthvalue,dayvalue=0;
            if(!$A.util.isUndefined(component.get("v.targtefieldRecord.TermDays__c")) &&!$A.util.isEmpty(component.get("v.targtefieldRecord.TermDays__c"))){
                dayvalue=parseInt(component.get("v.targtefieldRecord.TermDays__c"));
            }
            if(!$A.util.isUndefined(component.get("v.targtefieldRecord.TermMonths__c")) &&!$A.util.isEmpty(component.get("v.targtefieldRecord.TermMonths__c"))){
                monthvalue=parseInt(component.get("v.targtefieldRecord.TermMonths__c"));
            }
            if(!$A.util.isUndefined(component.get("v.targtefieldRecord.TermYr__c")) &&!$A.util.isEmpty(component.get("v.targtefieldRecord.TermYr__c"))){
                termvalue=parseInt(component.get("v.targtefieldRecord.TermYr__c"));
            }
            let finalenddate = mPStartDate.add(0, 'day').format("YYYY-MM-DD");
            finalenddate = mPStartDate.add(dayvalue-1, 'day').format("YYYY-MM-DD");
            finalenddate = mPStartDate.add(monthvalue, 'month').format("YYYY-MM-DD");
            finalenddate = mPStartDate.add(termvalue, 'year').format("YYYY-MM-DD");
            component.set("v.targtefieldRecord.ProposedEndDate__c",finalenddate);
        }
        else if(sourcefieldid==="proposedEndDate"){
            let latestendate = mPEndDate.add(1, 'day').format("YYYY-MM-DD");
            let mlatestendate = moment(latestendate);
            let terms = [];
            console.log("pStartDate : ", pStartDate);
            console.log("latestendate : ", latestendate);
            
            terms = helper.calculateEndDateDifference(mPStartDate, mlatestendate);
            
            console.log('terms:' , terms);
            
            if(terms.years != 0){
                component.set("v.targtefieldRecord.TermYr__c",terms.years);
            }else{
                component.set("v.targtefieldRecord.TermYr__c",0);
            }
            if(terms.months != 0){
                component.set("v.targtefieldRecord.TermMonths__c",terms.months);
            }else{
                component.set("v.targtefieldRecord.TermMonths__c",0);
            }
            
            if(terms.days != 0){
                component.set("v.targtefieldRecord.TermDays__c",terms.days);
            }else{
                component.set("v.targtefieldRecord.TermDays__c",0);
            }
        }
        
        if(sourcefieldid === "proposedHandoverDate" || sourcefieldid === "proposedStartDate"){
            mPStartDate = moment(pStartDate);    
            let days = null;
            if(phandoverDate > pStartDate) {
                helper.showToast(component, "Failed!", "error", "Proposed Handover Date could not be greater than Proposed Start Date")
                component.set("v.targtefieldRecord.ProposedHandoverDate__c", pStartDate);
                
                if(targetFieldRecord.CurrencyIsoCode === "NZD"){
                    days = mProposedRentDate.diff(mPStartDate, 'days');
                } else if(targetFieldRecord.CurrencyIsoCode === "AUD"){
                    days = mPStartDate.diff(mPhandoverDate, 'days');
                }
                
               	component.set("v.targtefieldRecord.FitoutDays__c", days);
            } else {
                if(targetFieldRecord.CurrencyIsoCode === "NZD"){
                    days = mProposedRentDate.diff(mPhandoverDate, 'days');
                } else if(targetFieldRecord.CurrencyIsoCode === "AUD"){
                    days = mPStartDate.diff(mPhandoverDate, 'days');
                }
                
                if(days || days === 0) {
                    component.set("v.targtefieldRecord.FitoutDays__c",days);
                }
            }
        }
        
        if(sourcefieldid === "proposedRentCommencementDate" && targetFieldRecord.CurrencyIsoCode === "NZD"){
            let days = mProposedRentDate.diff(mPhandoverDate, 'days');
            if(days || days === 0) {
                console.log("days : ", days);
                component.set("v.targtefieldRecord.FitoutDays__c",days);
            }
        }
    },
    savekeydates : function (component, event, helper) {
        component.set("v.showSpinner", true);
        component.find('opptykeydateRec').saveRecord(function(saveResult) {
            if(saveResult.state ==="SUCCESS") {
                var finalenddate=component.get("v.targtefieldRecord.ProposedEndDate__c");
                var message="Key Dates are saved.";
                var backoutperiod = ["10","11","12","01","02","03"];
                if(moment(finalenddate).format("MM")!=null){
                    if(backoutperiod.includes(moment(finalenddate).format("MM"))){
                        helper.showToast(component, "Success!", "warning", "Proposed End Date falls under blackout Period.")
                    }
                }
                
                window.setTimeout(
                    $A.getCallback(function() {
                        helper.showToast(component, "Success!", "success", message);
                        component.set("v.showSpinner", false);
                    }), 3500
                ); 
                
                
            } else {
             	component.set("v.showSpinner", false);   
            }
        });
        $A.get('e.force:refreshView').fire();
    },
    toastErrorMessage : function (errormessage) {
        console.log('errormessage in debug', errormessage);
        var toastEventFailed = $A.get("e.force:showToast");
        toastEventFailed.setParams({
            "title": "Failed!",
            "type" : "error",
            "message": errormessage
        });
        toastEventFailed.fire();
    }    
})