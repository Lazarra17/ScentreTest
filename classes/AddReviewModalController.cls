public with sharing class AddReviewModalController {
    /*
     * @author:         Kyle Tan
     * @description:    inserts the opportunity line item created in the rent review component
    */
    @AuraEnabled
    public static LightningResponse insertRentReview(String standardReviewType, String CPIType, String effectiveFromDate, String effectiveToDate, String description, Id opportunityId, Id pricebookEntryId, Id product2Id, String reviewType, String amount,Decimal cappedpercentage) {
        LightningResponse response = new LightningResponse();
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(AddReviewModalController.class.getName());
        OpportunityLineItem oppLineRecord = new OpportunityLineItem();
        oppLineRecord.StandardReviewType__c = standardReviewType;
        oppLineRecord.CPIType__c = CPIType;
        if(String.isNotEmpty(reviewType)) {
            oppLineRecord.ReviewType__c = reviewType;
        }
        if(String.isNotEmpty(amount)) {
            oppLineRecord.RentReviewAmount__c = amount;
        } 
        oppLineRecord.EffectiveFromDate__c = Date.valueOf(effectiveFromDate);
        oppLineRecord.EffectiveToDate__c = Date.valueOf(effectiveToDate);
        oppLineRecord.Description = description;
        oppLineRecord.OpportunityId = opportunityId;
        oppLineRecord.PricebookEntryId = pricebookEntryId;
        oppLineRecord.Product2Id = product2Id;
        oppLineRecord.Flexi_Rent__c = true;
        oppLineRecord.CappedPercent__c = cappedpercentage;
        try{
            database.insert(oppLineRecord);   
        }catch (Exception e) {
            errorHandler.createError(e);
            String errorMessage = e.getMessage();
            response.message = errorMessage.substring(errorMessage.indexOf(Constants.COMMA_NO_SPACE) + 1, errorMessage.length());
            response.status = Constants.FAILED;
        }
        errorHandler.save();
        return response;
    }
    
}