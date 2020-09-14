({
    doInit : function(component, event, helper) {
        var actions = [
            { label: 'Edit', name: 'edit' },
            { label: 'Delete', name: 'delete' }
        ]
        helper.getOpportunityLineItems(component);
        helper.verifyUserAccess(component);
        component.set('v.oppLineItemColumnList', [{ type: 'action', typeAttributes: { rowActions: actions }},
                                                  {label: 'CPI Type', fieldName: 'CPIType__c', type: 'text'},
                                                  {label: 'Standard Review Type', fieldName: 'StandardReviewType__c', type: 'text'},
                                                  {label: 'Review Type', fieldName: 'ReviewType__c', type: 'text'},
                                                  {label: 'Amount', fieldName: 'RentReviewAmount__c', type: 'currency',cellAttributes: {alignment: 'left'} },
                                                  {label: 'Effective From Date', fieldName: 'EffectiveFromDate__c', type: 'date'},
                                                  {label: 'Effective To Date', fieldName: 'EffectiveToDate__c', type: 'date'},
												  {label: 'Description', fieldName: 'Description', type: 'text'}]);
        component.set('v.promoLineItemColumnList', [{ type: 'action', typeAttributes: { rowActions: actions }},
                                                  {label: 'CPI Type', fieldName: 'CPIType__c', type: 'text'},
                                                  {label: 'Standard Review Type', fieldName: 'StandardReviewType__c', type: 'text'},
                                                  {label: 'Review Type', fieldName: 'ReviewType__c', type: 'text'},
                                                  {label: 'Effective From Date', fieldName: 'EffectiveFromDate__c', type: 'date'},
                                                  {label: 'Effective To Date', fieldName: 'EffectiveToDate__c', type: 'date'},
                                                  {label: 'Description', fieldName: 'Description', type: 'text'}]);
        component.set('v.showSpinner', false);
    },
    successSaving : function(component, event, helper) {
        helper.showToast(component, 'success', 'Opportunity Saved!', '');
        helper.getOpportunityLineItems(component);
        component.set('v.showSpinner', false);
    },
    errorSaving : function(component, event, helper) {
        helper.showToast(component, 'error', 'Error!', 'Error on saving opportunity');
        component.set('v.showSpinner', false);
    },
    toggleSpinner : function(component, event, helper) {
        component.set('v.showSpinner', true);
    },
    toggleModal : function(component, event, helper) {
        var modalBody;
        console.log(event.getSource().get("v.name"));
        $A.createComponent("c:AddReviewModal", {
            "oppRecordId": component.get('v.recordId'),
            "pricebookEntryId": component.get('v.pricebookEntryId'),
            "product2Id": event.getSource().get("v.name")
        },
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: "Add Review",
                                       body: modalBody, 
                                       showCloseButton: true,
                                       closeCallback: function() {
                                           $A.get('e.force:refreshView').fire();
                                       }
                                   })
                               }                               
                           });
    },
    viewLineItem : function(component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'edit':
                var modalBody;
                $A.createComponent("c:ViewRentReviewModal", {
                    "rentReviewId": row.Id,
                    "standardReview": row.StandardReviewType__c
                },
                                   function(content, status) {
                                       if (status === "SUCCESS") {
                                           modalBody = content;
                                           component.find('overlayLib').showCustomModal({
                                               header: "Add Review",
                                               body: modalBody, 
                                               showCloseButton: true,
                                               closeCallback: function() {
                                                   $A.get('e.force:refreshView').fire();
                                               }
                                           })
                                       }                               
                                   });
                break;
            case 'delete':
                helper.deleteLineItem(component, row);
                break;
        }
    },
    calculateDateAndTerm : function(component, event, helper) {
        var sourcefieldid=event.getSource().getLocalId();
      	let pEndDate=  component.find("proposedEndDate").get("v.value");
        let pStartDate = component.find("proposedStartDate").get("v.value");
        let mPEndDate = moment(pEndDate);
        let mPStartDate = moment(pStartDate);
     
        if(sourcefieldid!=="proposedEndDate"){
            var termvalue,monthvalue,dayvalue=0;
            if(!$A.util.isUndefined(component.find("termdays").get("v.value")) &&!$A.util.isEmpty(component.find("termdays").get("v.value"))){
                dayvalue=parseInt(component.find("termdays").get("v.value"));
            }
            if(!$A.util.isUndefined(component.find("termmonths").get("v.value")) &&!$A.util.isEmpty(component.find("termmonths").get("v.value"))){
                monthvalue=parseInt(component.find("termmonths").get("v.value"));
            }
            console.log("**"+component.find("oppRecTrmYr").get("v.value"));
            if(!$A.util.isUndefined(component.find("oppRecTrmYr").get("v.value")) &&!$A.util.isEmpty(component.find("oppRecTrmYr").get("v.value"))){
                termvalue=parseInt(component.find("oppRecTrmYr").get("v.value"));
            }
            let finalenddate = mPStartDate.add(0, 'day').format("YYYY-MM-DD");
            finalenddate = mPStartDate.add(dayvalue-1, 'day').format("YYYY-MM-DD");
            finalenddate = mPStartDate.add(monthvalue, 'month').format("YYYY-MM-DD");
            finalenddate = mPStartDate.add(termvalue, 'year').format("YYYY-MM-DD");
            console.log("FINAL: "+ finalenddate);
            component.find("proposedEndDate").set("v.value",finalenddate);
        }
        else if(sourcefieldid==="proposedEndDate"){
            let latestendate=mPEndDate.add(1, 'day').format("YYYY-MM-DD");
            let mlatestendate=moment(latestendate);
            //let diffDuration =0.0;
            let diffDuration = moment.duration(mlatestendate.diff(mPStartDate));
            
            console.log("diffDuration : ", diffDuration)
            
            if(diffDuration.years()!=0){
                component.find("oppRecTrmYr").set("v.value", (parseFloat(diffDuration.years())));
            } else{
                component.find("oppRecTrmYr").set("v.value", 0);
            }
            
            if(diffDuration.months()!=0){
                component.find("termmonths").set("v.value", parseFloat(diffDuration.months()));
            } else{
                component.find("termmonths").set("v.value", 0);
            }
            
            if(diffDuration.days()!=0){
                component.find("termdays").set("v.value", parseFloat(diffDuration.days()));
            } else{
                component.find("termdays").set("v.value",0);
            }
            console.log(diffDuration.years() + 'Years'); // 8 years
            console.log(diffDuration.months() + 'Months'); // 5 months
            console.log(diffDuration.days() + 'Days'); // 2 days
        }
    },
    
    //RPP - 9653  6-May-2020
    handleRowSelectionRentReview : function(component, event, helper){
        var oppLineItemRows = event.getParam('selectedRows');
        var setRows = [];
        for ( var i = 0; i < oppLineItemRows.length; i++ ) {
            setRows.push(oppLineItemRows[i].Id);
        }
        component.set('v.oppLineItemRentRows',setRows);
        if(setRows != null && setRows.length > 0){
            component.set('v.rentReviewEnabled',false);
            helper.getCPItypeValues(component);
            helper.getStdReviewTypeValues(component);
        }else{
            component.set('v.rentReviewEnabled',true);
        }

    },
    
    //RPP - 9653  6-May-2020
    handleUpdateRentReview : function(component, event, helper){
    	helper.getOppLineItemsRentReviewUpdate(component);
    },
    
    //RPP - 9653  6-May-2020
    handleRowSelectionPromoReview : function(component, event, helper){
        var oppLineItemRows = event.getParam('selectedRows');
        var setRows = [];
        for ( var i = 0; i < oppLineItemRows.length; i++ ) {
            setRows.push(oppLineItemRows[i].Id);
        }
        component.set('v.oppLineItemPromoRows',setRows);
        if(setRows != null && setRows.length > 0){
            component.set('v.promoReviewEnabled',false);
            helper.getCPItypeValues(component);
            helper.getStdReviewTypeValues(component);
        }else{
            component.set('v.promoReviewEnabled',true);
        }
    },
    
	//RPP - 9653  6-May-2020    
    handleUpdatePromoReview : function(component, event, helper){
    	helper.getOppLineItemsPromoReviewUpdate(component);
    }    
    
})