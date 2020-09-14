public class OpportunityOptionsController{
    public class RentReviewWrapper{
        @AuraEnabled public List<OpportunityLineItem> optionslineItemList = new List<OpportunityLineItem>();
        @AuraEnabled public List<PriceBookentry> optionpriceBookentryRecordList = new List<PriceBookentry>();
    }
    
    @AuraEnabled
    public static LightningResponse getOpportunityLineItem(Id opportunityId) {
        LightningResponse responseObject = new LightningResponse();
        RentReviewWrapper wrapper=new RentReviewWrapper();
        Opportunity opptyRecord=DatabaseSOQLBank.getOpportunity(opportunityId)[0];
        
        wrapper.optionpriceBookentryRecordList = DatabaseSOQLBank.getPricebookOption('Options', opptyRecord.Pricebook2Id);
        
        if (wrapper.optionpriceBookentryRecordList!=NULL && !wrapper.optionpriceBookentryRecordList.isEmpty()) {
            wrapper.optionslineItemList=DatabaseSOQLBank.getOptionsLineItem(opportunityId, wrapper.optionpriceBookentryRecordList[0].Id);
        }
        system.debug('&&'+wrapper.optionslineItemList);
        responseObject.returnValue = JSON.serialize(wrapper);
        return responseObject;
    }
    
    @AuraEnabled
    public static LightningResponse userHasEditAccess(Id opportunityId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(SecurityController.class.getName());
        LightningResponse response = new LightningResponse();
        try{
            response.returnValue = JSON.serialize(OpportunityLineItemController.userHasEditAccess(opportunityId));
        } catch(Exception e) {
            response.status = Constants.FAILED;
            response.message = e.getMessage();
            errorHandler.createError(e);
        }
        return response;
    }
    
    @AuraEnabled
    public static void insertOptions(String description,Id pricebookEntryId, id product2Id,Integer optionTerms,Id opportunityId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(OpportunityOptionsController.class.getName());
        OpportunityLineItem oppLineRecord = new OpportunityLineItem();

        oppLineRecord.Description = description;
        oppLineRecord.OpportunityId = opportunityId;
        oppLineRecord.PricebookEntryId = pricebookEntryId;
        oppLineRecord.OptionsTerm__c=optionTerms;
        oppLineRecord.Product2Id = product2Id;

        try{
            system.debug('oppLineRecord: '+ oppLineRecord);
            database.insert(oppLineRecord);   
        }catch (Exception e) {
            errorHandler.createError(e);
            system.debug(e);
        }
        errorHandler.save();
    }
    
    @AuraEnabled
    public static void removeOpportunity(Id opportunityProductId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(OpportunityOptionsController.class.getName());
        if(opportunityProductId != null) {
            try {
                database.delete(opportunityProductId);
            } catch (Exception e) {
                errorHandler.createError(e);
            } 
        }
        errorHandler.save();
    }
}