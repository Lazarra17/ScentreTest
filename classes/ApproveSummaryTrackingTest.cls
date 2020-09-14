/*
* @author:              Sidney Garcia
* @description:         Test class for ApproveSummaryTracking
*/
@isTest
public class ApproveSummaryTrackingTest {
    @TestSetup private static void testSetup() {
        Property__c testProperty = new Property__c();
        List<Account> accountList = new List<Account>();
        Account accountRecord = new Account();
        PriceBook2 pb = new PriceBook2 ();
        Product2 productBaseRentGross = new Product2();
        Product2 productFitoutContribution = new product2();
        Product2 productSundayTradeSemiGross = new Product2();
        Product2 productPromotionLevy = new Product2();
        Product2 productCouncilRatesNet = new Product2();
        PricebookEntry pricebookEntryBaseRentGross = new PricebookEntry();
        PricebookEntry pricebookEntryFitoutContribution = new PricebookEntry();
        PricebookEntry pricebookEntrySundayTradeSemiGross = new PricebookEntry();
        PricebookEntry pricebookEntryPromotionLevy = new PricebookEntry();
        PricebookEntry pricebookEntryCouncilRatesNet = new PricebookEntry();
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Opportunity> opportunityList = new List<Opportunity>();
        Opportunity opportunityRecord = new Opportunity();
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        OpportunityLineItem OpportunityLineItemRecord = new OpportunityLineItem ();
        Integer loopInt = 0;
        Product2 productRecord;
        
        //CREATE PRODUCT
        
        productRecord = TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, Constants.RENT);
        insert productRecord;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        //CREATE PROPERTY
        testProperty = TestDataFactory.createPropertyRecord();
        testProperty.PriceBook__c = pricebookId;
        database.insert(testProperty);
        
        //CREATE ACCOUNT
        for(Integer counter = 0; counter < 5; counter++) {
            accountRecord = TestDataFactory.createAccount(counter, testProperty.Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId());
            accountList.add(accountRecord);
        }
        database.insert(accountList);
        accountList = [SELECT Id, Property__c FROM Account LIMIT 5];
        Contact contactRecord = TestDataFactory.createContact(CONSTANTS.TEST_FNAME, accountList[0]);
        insert contactRecord;
        //CREATE Products
        productBaseRentGross = TestDataFactory.createProduct(CONSTANTS.PRODUCT_BASE_RENT_GROSS, CONSTANTS.PRODUCT_FAMILY_RENT);
        database.insert(productBaseRentGross);
        productBaseRentGross = [SELECT Id FROM Product2 LIMIT 1];
        
        //CREATE PricebookEntry
        pricebookEntryBaseRentGross = TestDataFactory.createStandardPriceBookEntry(1, productBaseRentGross)[0];
        database.insert(pricebookEntryBaseRentGross);
        pricebookEntryBaseRentGross = [SELECT Id, Pricebook2Id FROM PricebookEntry LIMIT 1];
        //CREATE Opportunity
        opportunityList = TestDataFactory.createOpportunity(10, accountList[0]);
        for(Opportunity oppo : opportunityList){
            
            oppo.AnnualMinimumRent__c = 10000;
            oppo.ApprovalStatus__c = CONSTANTS.PENDING_INI_APRV;
            oppo.LatestApprovedCapital__c = 100000;
        }
        insert opportunityList;
        
        //CREATE OpportunityLineItem
        for(Integer counter = 0; counter < 5; counter++) {
            opportunityLineItemRecord = TestDataFactory.createOpportunityLineItem(counter, opportunityList[counter], productBaseRentGross, pricebookEntryBaseRentGross);
            
            opportunityLineItemList.add(opportunityLineItemRecord);
        }
        insert opportunityLineItemList;
    }
    
    public static testMethod void getChangedItem(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Opportunity> oppList = [SELECT Id, ApprovalStatus__c FROM Opportunity LIMIT 200];
        HistoryTrackingUtil.HistoryTrackingWrapper historyWrapper = new HistoryTrackingUtil.HistoryTrackingWrapper();
        Set<String> IncludeFieldsforTracking = new Set<String>();
        List<Opportunity> historyTracking = new List<Opportunity>();
        LightningResponse wrapper = new LightningResponse();
        List<OpportunityAuditHistory__c> oppAuditList = new List<OpportunityAuditHistory__c>();
        ApproveStatusController apprvstat = new ApproveStatusController();
        
        System.runAs(testUser) {
            
            Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
            Map<Id,Opportunity> oppMapUpdated = new Map<Id,Opportunity>();
            
            List<Schema.FieldSetMember> getOppFieldsSetFields = SObjectType.Opportunity.FieldSets.HistoryTracking.getFields();
            
            String query = 'SELECT ';
            for(Schema.FieldSetMember f : getOppFieldsSetFields) {
                query += f.getFieldPath() + ', ';
            }
            query += 'Id FROM Opportunity LIMIT 1';
            System.debug('queryyyy ' + query); 
            
            Opportunity oppRec = Database.query(query);
            
            Opportunity oppRec1 = Database.query(query); 
            
            oppMap.put(oppRec.Id, oppRec);
            historyWrapper.oldMap = oppMap;
            
            TriggerHandler.clearBypass('OpportunityTriggerHandler');
            oppRec1.AnnualMinimumRent__c =90000;
            Database.update(oppRec1);
            
            oppMapUpdated.put(oppRec1.Id, oppRec1);
            historyWrapper.newMap = oppMapUpdated;
            historyWrapper.historyobjectAPIname = CONSTANTS.HISTORY_TRACKING_OPPO;
            historyWrapper.objectAPIName = CONSTANTS.OPPORTUNITY;
            historyWrapper.FieldSetAPIName = 'HistoryTracking';
            
            Test.startTest();
            IncludeFieldsforTracking = HistoryTrackingUtil.IncludeFieldsforTracking(CONSTANTS.HISTORY_TRACKING_OPPO, 'HistoryTracking');
            historyTracking = HistoryTrackingUtil.historyTracking(historyWrapper);
            String newValue = '90000';
            String previousValue = CONSTANTS.EMPTY;
            
            oppAuditList = TestDataFactory.createOpportunityAuditHistory(oppList[0], CONSTANTS.ANNUAL_MINIMUM_RENT_API, newValue, previousValue, oppList[0].ApprovalStatus__c ,1);
            insert oppAuditList;
            apprvstat.getATracking();
            for(Opportunity opp : oppList){
                wrapper = ApproveSummaryTracking.getChangedItem(opp.Id);
            }
            
            Test.stopTest();
        }
        
        
    }
}