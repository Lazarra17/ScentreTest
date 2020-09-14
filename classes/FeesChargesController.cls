public with sharing class FeesChargesController {
    
    public class Response{
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String message;
        @AuraEnabled
        public String returnValue;
        
        public Response(){
            this.message = '';
            this.returnValue = '';
            this.status = Constants.SUCCESS;
        }
    }
    
    public class FeesChargeParentWrapper{
        public Boolean isTotalPriceEditable;
        public List<FeesChargesWrapper> feesChargesList;
    }
    
    public class FeesChargesWrapper{
        @AuraEnabled public Id recordId;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public Decimal listPrice;
        @AuraEnabled public Decimal totalPrice;
        @AuraEnabled public String type;
        @AuraEnabled public String productName;
        @AuraEnabled public Decimal productSalesPrice;
        @AuraEnabled public String capitalCategory;
    }
    
    @AuraEnabled
    public static Response getRelatedList(Opportunity opportunity, String productFamily){
        Response res = new Response();
        FeesChargesWrapper tempWrapperTemp;
        FeesChargeParentWrapper parentWrapper = new FeesChargeParentWrapper();
        Set<Id> oppLineItemPriceBookEntryId = new Set<Id>();
        List<PriceBookEntry> relatedPBEntryList;
        List<OpportunityLineItem> relatedOppLineItemList;
        List<FeesChargesWrapper> returnWrapperList = new List<FeesChargesWrapper>();
        Opportunity OpportunityRecord=new Opportunity();
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(FeesChargesController.class.getName());
       
        try{
            relatedOppLineItemList = DatabaseSOQLBank.getOpportunityLineItem(productFamily, opportunity.Pricebook2Id, opportunity.Id);
            OpportunityRecord=[Select Id,Opportunity.Property__c, Space__r.Property__r.PriceBook__c,Property__r.ApplicableOutgoings__c, Space__c, 
                               Space__r.ApplicableOutgoings__c, Space__r.Property__c, DealType__c, Space__r.RentableArea__c,
                               Space__r.SpaceProductsApplies__c,ProposedRentCommencementDate__c,Space__r.BillingCategory__c,
                               Space__r.Type__c,CurrencyIsoCode
                               From Opportunity Where Id =: opportunity.Id];
            if(String.isBlank(OpportunityRecord.Space__r.BillingCategory__c)){
                OpportunityRecord.Space__r.BillingCategory__c='NA';
            }
        } catch(Exception e){
            relatedOppLineItemList = null;
            errorHandler.createError(e);
        }
        Set<Id> productidSet=new Set<Id>();
        try{
            relatedPBEntryList = DatabaseSOQLBank.getPricebookEntry(productFamily, opportunity.Pricebook2Id);
            for(PricebookEntry pricebookentryrecord: relatedPBEntryList){
                productidSet.add(pricebookentryrecord.Product2Id);
            }
        } catch(Exception e){
            relatedPBEntryList = null;
            errorHandler.createError(e);
        }
        
        
        Map<Id,Product2> productMap=new Map<Id,Product2>([SELECT Id, Name,DealType__c,SpaceBillingCategory__c,SpaceType__c
                                                          FROM Product2 
                                                          WHERE IsActive = TRUE
                                                          AND DealType__c !=null
                                                          AND SpaceBillingCategory__c !=null
                                                          AND SpaceType__c !=null
                                                          AND Family =: productFamily
                                                          AND Id IN: productidSet]);
        
        if(relatedOppLineItemList != null && !relatedOppLineItemList.isEmpty()){
            for(OpportunityLineItem oppLineItem : relatedOppLineItemList){
                tempWrapperTemp = new FeesChargesWrapper();
                
                tempWrapperTemp.isActive = true;
                tempWrapperTemp.recordId = oppLineItem.Id;
                tempWrapperTemp.listPrice = oppLineItem.ListPrice;
                tempWrapperTemp.totalPrice = oppLineItem.UnitPrice;
                tempWrapperTemp.productName = oppLineItem.Product2.Name;
                tempWrapperTemp.type = Constants.OPPORTUNITYLINEITEM;
                returnWrapperList.add(tempWrapperTemp);
                
                oppLineItemPriceBookEntryId.add(oppLineItem.PriceBookEntryId);
            } 
        }     
        if(!relatedPBEntryList.isEmpty()){
            for(PriceBookEntry pBookEntry : relatedPBEntryList){
                
                if(!oppLineItemPriceBookEntryId.contains(pBookEntry.Id)){
                    List<String> productdealTypevalueList = productMap.get(pBookEntry.Product2Id).DealType__c.split(';');
                    List<String> productBillingcategoryList = productMap.get(pBookEntry.Product2Id).SpaceBillingCategory__c.split(';');
                    List<String> productSpacetypeList = productMap.get(pBookEntry.Product2Id).SpaceType__c.split(';');
                    
                    if(productdealTypevalueList.contains(OpportunityRecord.DealType__c)
                       &&productBillingcategoryList.contains(OpportunityRecord.Space__r.BillingCategory__c)
                       &&productSpacetypeList.contains(OpportunityRecord.Space__r.Type__c)
                       &&pBookEntry.CurrencyIsoCode==OpportunityRecord.CurrencyIsoCode){
                           tempWrapperTemp = new FeesChargesWrapper();	            	
                           tempWrapperTemp.isActive = false;
                           tempWrapperTemp.recordId = pBookEntry.Product2Id;
                           tempWrapperTemp.listPrice = pBookEntry.UnitPrice;
                           tempWrapperTemp.productName = pBookEntry.Product2.Name;
                           tempWrapperTemp.productSalesPrice = pBookEntry.UnitPrice;
                           tempWrapperTemp.totalPrice = 0.00;
                           tempWrapperTemp.capitalCategory =  pBookEntry.Product2.CapitalCategory__c;
                           tempWrapperTemp.type = Constants.PRICEBOOKENTRY;
                           
                           returnWrapperList.add(tempWrapperTemp);
                       }
                    
                }
            }
        }
        
        parentWrapper.feesChargesList = returnWrapperList;
        parentWrapper.isTotalPriceEditable = isTotalPriceEditable();
        
        if(!returnWrapperList.isEmpty()){
            res.returnValue = JSON.serialize(parentWrapper);
        } else {
            res.status = Constants.FAILED;
            res.message = Constants.NO_PRODUCTS_AVAILABLE;
        }
        
        errorHandler.save();
        return res;
    }
    
    @AuraEnabled
    public static Response saveChanges(Opportunity opportunity, String feesChargesWrapperJSON, String productFamily){
        OpportunityLineItem oppLineItemTemp;
        Response res = new Response();
        List<FeesChargesWrapper> feesChargesList;
        List<OpportunityLineItem> newOppLineItemList = new List<OpportunityLineItem>();
        List<OpportunityLineItem> forDeleteOppLineItemList = new List<OpportunityLineItem>();
        
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(FeesChargesController.class.getName());
        
        feesChargesList = (List<FeesChargesWrapper>) JSON.deserialize(feesChargesWrapperJSON, List<FeesChargesWrapper>.class);
        
        for(FeesChargesWrapper feesCharges : feesChargesList){
            if(Constants.OPPORTUNITYLINEITEM.equalsIgnoreCase(feesCharges.type)){
                if(feesCharges.isActive){
                    oppLineItemTemp = updateOpportunityLineItem(feesCharges);
                    newOppLineItemList.add(oppLineItemTemp);
                } else {
                    forDeleteOppLineItemList.add(
                        new OpportunityLineItem(Id = feesCharges.recordId)
                    );
                }
            } else if(feesCharges.isActive && Constants.PRICEBOOKENTRY.equalsIgnoreCase(feesCharges.type)){
                newOppLineItemList.add(
                    createOpportunityLineItem(opportunity.Id, feesCharges, productFamily)
                );
            }
        }
        
        try{
            if(!newOppLineItemList.isEmpty()){
                Database.upsert(newOppLineItemList);
            }
        } catch(Exception e){
            res.status = Constants.FAILED;
            res.message = e.getMessage();
            errorHandler.createError(e);
        }
        if(!Constants.FAILED.equalsIgnoreCase(res.status)){
            try{
                if(!forDeleteOppLineItemList.isEmpty()){
                    Database.delete(forDeleteOppLineItemList);
                }
            } catch(Exception e){
                res.status = Constants.FAILED;
                res.message = e.getMessage();
                errorHandler.createError(e);
            }
        }
        
        if(!Constants.FAILED.equalsIgnoreCase(res.status)){
            res = getRelatedList(opportunity, productFamily);
        }
        
        errorHandler.save();
        
        return res;
    }
    
    private static Boolean isTotalPriceEditable(){
        Boolean isTotalPriceEditable = false;
        String readWriteProfile = Label.CapitalTotalPriceReadWriteAccess;
        
        Profile prof = DatabaseSOQLBank.getProfile(UserInfo.getProfileId());
        
        if(readWriteProfile.contains(prof.Name) || Constants.SYSTEM_ADMINISTRATOR.equalsIgnoreCase(prof.Name)){
            isTotalPriceEditable = true;
        }
        
        return isTotalPriceEditable;
    } 
    
    private static OpportunityLineItem updateOpportunityLineItem(FeesChargesWrapper feesCharges){
        OpportunityLineItem oppLineItem = new OpportunityLineItem();
        
        oppLineItem.Id = feesCharges.recordId;
        oppLineItem.UnitPrice = feesCharges.totalPrice;
        
        return oppLineItem;
    }
    
    private static OpportunityLineItem createOpportunityLineItem(Id opportunityId, FeesChargesWrapper feesCharges, String productFamily){
        OpportunityLineItem oppLineItem = new OpportunityLineItem();
        
        oppLineItem.IsActive__c = true;
        oppLineItem.Product2Id = feesCharges.recordId;
        oppLineItem.OpportunityId = opportunityId;
        oppLineItem.UnitPrice = feesCharges.productSalesPrice;
        
        if(feesCharges.totalPrice != null){
            oppLineItem.UnitPrice = feesCharges.totalPrice;
        }
        
        oppLineItem.ProductFamily__c = productFamily;
        
        if(Constants.CAPITAL.equalsIgnoreCase(productFamily)){
            oppLineItem.CapitalCategory__c = feesCharges.capitalCategory;
        }
        
        return oppLineItem;
    }
    
    @AuraEnabled
    public static Boolean userHasEditAccess(Id opportunityId) {
        Boolean hasEditAccess = false;
        Boolean isOppLocked = false;
        Boolean isDealAchieved = false;
        Boolean userAccess = false;
        opportunity oppRecord = new Opportunity();
        if(opportunityId != null) {
            try {
                oppRecord = [SELECT id, DealAchieved__c FROM Opportunity WHERE id =: opportunityId];
            } catch(Exception e) {
                oppRecord = null;
            }
            if(Approval.isLocked(opportunityId)) {
                isOppLocked = true;
            }
        }
        if(oppRecord != null) {
            isDealAchieved = oppRecord.DealAchieved__c;
        }
        for(UserRecordAccess usrRecAcc : [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId =: userInfo.getUserId() AND RecordId =:opportunityId]){
            hasEditAccess = usrRecAcc.HasEditAccess;
        }      
        if(!isOppLocked && !isDealAchieved && hasEditAccess) {
            userAccess = true;
        }
        return userAccess;
    }
}