public with sharing class RentReviewController {
    
    public class RentReviewWrapper{
        @AuraEnabled public List<OpportunityLineItem> rentReviewList = new List<OpportunityLineItem>();
        @AuraEnabled public List<OpportunityLineItem> promoReviewList = new List<OpportunityLineItem>();
        @AuraEnabled public String rentRevPbEntry = null;
        @AuraEnabled public String promoRevPbEntry = null;
        @AuraEnabled public String rentReviewProdId = null;
        @AuraEnabled public String promoRevProdId = null;
    }
    
    /*
* @author:			Kyle Tan
* @paramaters:		opportunityId - used as reference to get opportunity line items
* @description:	used to get all opportunity line items of opportunity that are rent review
*/
    @AuraEnabled
    public static LightningResponse getOpportunityLineItem(Id opportunityId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(RentReviewController.class.getName());
        RentReviewWrapper wrapper = new RentReviewWrapper();
        LightningResponse responseObject = new LightningResponse();
        Id rentReviewId = null;
        Id promoRevId = null;
        Id priceBookId = null;
        Set<Id> tempOppIdSet = new Set<Id>();
        Set<Id> priceBookIdSet = new Set<Id>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        Map<String, PricebookEntry> productNameandPricebookEntryMap = new Map<String, PricebookEntry>();
        List<PriceBookEntry> pbEntryList = new List<PriceBookEntry>();
        tempOppIdSet.add(opportunityId);
        
        // Start LF RPP-10151 8.5.2019
        Id rentReviewPbeId = null;
        Id promoRevPbeId = null;
        Map<Id, PriceBookEntry> promoRevByPriceBookMap = new Map<Id, PricebookEntry>();
        Map<Id, PriceBookEntry> rentRevByPriceBookMap = new Map<Id, PricebookEntry>();
        // End LF RPP-10151 8.5.2019
        
        try{
            oppMap = DatabaseSOQLBank.getOpportunityMap(tempOppIdSet);
        } catch (Exception e) {
            oppMap = null;
        }
        if(oppMap != null) {
            if(oppMap.containsKey(opportunityId)) {
                // Start LF RPP-10151 8.5.2019
                Id oppPriceBookId = oppMap.get(opportunityId).Pricebook2Id;
                priceBookIdSet.add(oppPriceBookId);
                promoRevByPriceBookMap = DatabaseSOQLBank.getPriceBookEntry(priceBookIdSet, Constants.PRODUCT_PROMO_REVIEW);
                promoRevPbeId = promoRevByPriceBookMap.containsKey(oppPriceBookId) ? promoRevByPriceBookMap.get(oppPriceBookId).Id : null;
                rentRevByPriceBookMap = DatabaseSOQLBank.getPriceBookEntry(priceBookIdSet, Constants.PRODUCT_RENT_REVIEW);
                rentReviewPbeId = rentRevByPriceBookMap.containsKey(oppPriceBookId) ? rentRevByPriceBookMap.get(oppPriceBookId).Id : null;
                // End LF RPP-10151 8.5.2019
            }
        }
        try{
            rentReviewId = DatabaseSOQLBank.getProduct(Constants.PRODUCT_RENT_REVIEW);
        } catch(Exception e) {
            rentReviewId = null;
        }
        try{
            promoRevId = DatabaseSOQLBank.getProduct(Constants.PRODUCT_PROMO_REVIEW);
        } catch(Exception e) {
            promoRevId = null;
        }
        try{
            pbEntryList = DatabaseSOQLBank.getPriceBookEntry(priceBookIdSet);
        } catch (Exception e) {
            pbEntryList = null;
        }

        
        if(rentReviewId != null && promoRevId != null) {
            Set<Id> oppIdSet = new Set<Id>();
            oppIdSet.add(opportunityId);
            List<OpportunityLineItem> oppLineItemList = new List<OpportunityLineItem>();
            try {
                oppLineItemList = new List<OpportunityLineItem>(DatabaseSOQLBank.getReviewRecord(oppIdSet));
            } catch(Exception e) {
                oppLineItemList = null;
            }          
            
            if(oppLineItemList != null && oppLineItemList.size() > 0) {
                for(OpportunityLineItem oppLineItemRec :oppLineItemList) {
                    if(oppLineItemRec.Product2Id == promoRevId) {
                        wrapper.promoReviewList.add(oppLineItemRec);
                    } else if (oppLineItemRec.Product2Id == rentReviewId) {
                        wrapper.rentReviewList.add(oppLineItemRec);
                    }
                }
                wrapper.rentReviewProdId = rentReviewId;
                wrapper.promoRevProdId = promoRevId;
                wrapper.rentRevPbEntry = rentReviewPbeId; // LF RPP-10151 8.5.2019
                wrapper.promoRevPbEntry = promoRevPbeId; // LF RPP-10151 8.5.2019
                responseObject.returnValue = JSON.serialize(wrapper);
                system.debug('responseObject.returnValue-->' + responseObject.returnValue);
            }
        }
        errorHandler.save();
        return responseObject;
    }
    
    /*
    * @author:			Kyle Tan
    * @parameters:		oppLineItemId - ID of the rent review line item to be deleted
    * @description:	deletes rent review line item
    */
    @AuraEnabled
    public static void deleteLineItem(Id oppLineItemId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(RentReviewController.class.getName());
        if(oppLineItemId != null) {
            try{
                database.delete(oppLineItemId);
            } catch(Exception e) {
                errorHandler.createError(e);
            }
        }
        errorHandler.save();
    }
    
    /**
     * @author:			Kyle Tan
     * @desc:			verify if user has edit access on the opportunity record
     **/
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
    
    /*
* @author:			Shrikant Hase
* @paramaters:		opportunityId - used as reference to get opportunity line items
					oppLineItemIds - opp line items to be updated
					stdRevType - New Standard Review Type Value
					cpiType - New CPI Type Value
* @description:	used to get all opportunity line items of opportunity that are either rent or promo reviews for bulk update
* RPP: 9653 
*/
    @AuraEnabled
    public static List<OpportunityLineItem> getOppLineItemForUpdate(Id opportunityId, List<Id> oppLineItemIds, String cpiType, String stdRevType){
        List<String> cpiTypeValues = RentReviewController.getCPITypeValues();
        List<String> stdRevTypetypeValues = RentReviewController.getStdReviewTypeValues();
        Set<Id> oppIdSet = New Set<Id>();
        oppIdSet.add(opportunityId);
        List<OpportunityLineItem> oppLineItemList = new List<OpportunityLineItem>();
        List<OpportunityLineItem> oppLineItemListForUpdate = new List<OpportunityLineItem>();
            try {
                oppLineItemList = new List<OpportunityLineItem>(DatabaseSOQLBank.getReviewRecord(oppIdSet));
            } catch(Exception e) {
                oppLineItemList = null;
            }  
        if(oppLineItemList != null && oppLineItemList.size() > 0){
            for(OpportunityLineItem oppItemRec: oppLineItemList){
                if(oppLineItemIds.contains(oppItemRec.Id)){
                    if(cpiTypeValues.contains(cpiType)){
                        oppItemRec.CPIType__c = cpiType;
                    }
                    if(stdRevTypetypeValues.contains(stdRevType)){
                    	oppItemRec.StandardReviewType__c = stdRevType;
                    }
                    oppLineItemListForUpdate.add(oppItemRec);
                }
            }
        }
        
        if(oppLineItemListForUpdate != null && oppLineItemListForUpdate.size() > 0){
            update oppLineItemListForUpdate;
            return oppLineItemListForUpdate;
        }else{
            return null;
        }
    }
  
    /*
* @author:			Shrikant Hase
* @description:	used to get 'CPI Type' Picklist Values
* RPP: 9653 
*/
    @AuraEnabled        
    public static List<String> getCPITypeValues(){
        List<String> pickListValuesList = new List<String>();
        Schema.DescribeFieldResult fieldResult = OpportunityLineItem.CPIType__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }     
        return pickListValuesList;
    }
    
    /*
* @author:			Shrikant Hase
* @description:	used to get 'Standard Review Type' Picklist Values
* RPP: 9653 
*/
    @AuraEnabled        
    public static List<String> getStdReviewTypeValues(){
        List<String> pickListValuesList = new List<String>();
        Schema.DescribeFieldResult fieldResult = OpportunityLineItem.StandardReviewType__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }     
        return pickListValuesList;
    }
}