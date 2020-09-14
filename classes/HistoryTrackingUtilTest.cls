/*
* @author:              Sidney Garcia
* @description:         Test class for HistoryTrackingUtil
*/
@isTest
public class HistoryTrackingUtilTest {
    @TestSetup private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> spaceRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName(Constants.SPACE);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> precedentClauseRecordTypeMapByName  = RecordTypeUtil.getAllRecordTypesByName(Constants.PRECEDENT_CLAUSE_API);
        Account accountRecord;
        PrecedentClause__c precedentClauseRecord;
        Account account = new Account();
        List<Account> accountList = new List<Account>();
        List<Account> parentAccList = new List<Account>();
        List<Property__c> propertyList = new List<Property__c>();
        List<PrecedentClause__c> precedentClauseList = new List<PrecedentClause__c>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Product2> productList = new List<Product2>();
        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>();
        Pricebook2 pricebookRecord;
        Product2 productRecord;
        
        //CREATE PRODUCT
        productRecord = TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, Constants.RENT);
        insert productRecord;
        
        List<Pricebook2> priceBookList = TestDataFactory.createPricebook(1);
        Database.insert(priceBookList);
        Pricebook2 priceBookRec = [SELECT Id, CurrencyIsoCode FROM Pricebook2 LIMIT 1];
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(1);
        propertyList[0].Pricebook__c = priceBookRec.Id;
        database.insert(propertyList);
        propertyList = [SELECT Id FROM Property__c LIMIT 1];
        
        //CREATE PARENT ACCOUNT
        parentAccList.addAll(TestDataFactory.createAccountBulk(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(parentAccList);
        parentAccList = [SELECT Id, Property__c FROM Account LIMIT 1];
        
        //CREATE ACCOUNT
        account = TestDataFactory.createAccountwithParent(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), parentAccList.get(0).Id);
        database.insert(account);
        account = [SELECT Id, Property__c from Account LIMIT 1];
        
        List<Space__c> spaceList = TestDataFactory.createSpace(5, propertyList[0]);
        for(Space__c space : spaceList){
            space.RentableArea__c = 40;
            space.DevelopmentType__c = null;
            space.HeldVacantSpace__c = true;
            space.CurrencyIsoCode = 'AUD';
            space.RecordTypeId = spaceRecordTypeMap.get(Constants.PROSPECTIVE_SPACE).getRecordTypeId();
        }
        Database.insert(spaceList);
        
        //CREATE OPPORTUNITY
        accountList = [SELECT Id, Property__c, ParentId FROM Account LIMIT 1];
        
        opportunityList = TestDataFactory.createOpportunity(1, accountList[0], propertyList, spaceList);
        
        database.insert(opportunityList);
        
        
        
    }
    
    public static testMethod void testHistoryTrackingUpdateSpaceRecord(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        HistoryTrackingUtil.HistoryTrackingWrapper historyWrapper = new HistoryTrackingUtil.HistoryTrackingWrapper();
        Set<String> IncludeFieldsforTracking = new Set<String>();
        List<Space__c> historyTracking = new List<Space__c>();
        
        System.runAs(testUser) {
            Map<Id,Space__c> spaceMap = new Map<Id,Space__c>();
            Map<Id,Space__c> spaceMapUpdated = new Map<Id,Space__c>();
            Space__c spaceRec = [Select Id,RentableArea__c, UsableArea__c, DevelopmentType__c From Space__c LIMIT 1];
            Space__c spaceRec1 = [Select Id,RentableArea__c, UsableArea__c, DevelopmentType__c From Space__c LIMIT 1];
            spaceMap.put(spaceRec.Id, spaceRec);
            historyWrapper.oldMap = spaceMap;
            
            spaceRec1.RentableArea__c = 29;
            Database.update(spaceRec1);
            
            spaceMapUpdated.put(spaceRec1.Id, spaceRec1);
            historyWrapper.newMap = spaceMapUpdated;
            historyWrapper.historyobjectAPIname = CONSTANTS.HISTORY_TRACKING_SPACE;
            historyWrapper.objectAPIName = CONSTANTS.SPACE;
            Test.startTest();
            IncludeFieldsforTracking = HistoryTrackingUtil.IncludeFieldsforTracking(CONSTANTS.SPACE, null);
            historyTracking = HistoryTrackingUtil.historyTracking(historyWrapper);
            Test.stopTest();
        }
        System.assertEquals(true, IncludeFieldsforTracking <> null);
        System.assertEquals(true, historyTracking <> null);
    }
    public static testMethod void testHistoryTrackingOpportunity(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        HistoryTrackingUtil.HistoryTrackingWrapper historyWrapper = new HistoryTrackingUtil.HistoryTrackingWrapper();
        Set<String> IncludeFieldsforTracking = new Set<String>();
        List<Opportunity> historyTracking = new List<Opportunity>();
        
        
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
            oppRec1.AnnualMinimumRent__c = 10000;
            Database.update(oppRec1);
            
            oppMapUpdated.put(oppRec1.Id, oppRec1);
            historyWrapper.newMap = oppMapUpdated;
            historyWrapper.historyobjectAPIname = CONSTANTS.HISTORY_TRACKING_OPPO;
            historyWrapper.objectAPIName = CONSTANTS.OPPORTUNITY;
            historyWrapper.FieldSetAPIName = 'HistoryTracking';
            Test.startTest();
            IncludeFieldsforTracking = HistoryTrackingUtil.IncludeFieldsforTracking(CONSTANTS.HISTORY_TRACKING_OPPO, 'HistoryTracking');
            historyTracking = HistoryTrackingUtil.historyTracking(historyWrapper);
            Test.stopTest();
        }
        System.assertEquals(true, IncludeFieldsforTracking <> null);
        System.assertEquals(true, historyTracking <> null);
    }
    
    public static testMethod void testHistoryTrackingOpportunityReferenceField(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        HistoryTrackingUtil.HistoryTrackingWrapper historyWrapper = new HistoryTrackingUtil.HistoryTrackingWrapper();
        Set<String> IncludeFieldsforTracking = new Set<String>();
        List<Opportunity> historyTracking = new List<Opportunity>();
        
        
        System.runAs(testUser) {
            Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
            Map<Id,Opportunity> oppMapUpdated = new Map<Id,Opportunity>();
            
            List<Schema.FieldSetMember> getOppFieldsSetFields = SObjectType.Opportunity.FieldSets.CloneExcludedField.getFields();
            
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
            oppRec1.RMLARS__c = testUser.Id;
            Database.update(oppRec1);
            
            oppMapUpdated.put(oppRec1.Id, oppRec1);
            historyWrapper.newMap = oppMapUpdated;
            historyWrapper.historyobjectAPIname = CONSTANTS.HISTORY_TRACKING_OPPO;
            historyWrapper.objectAPIName = CONSTANTS.OPPORTUNITY;
            historyWrapper.FieldSetAPIName = 'CloneExcludedField';
            Test.startTest();
            IncludeFieldsforTracking = HistoryTrackingUtil.IncludeFieldsforTracking(CONSTANTS.HISTORY_TRACKING_OPPO, 'CloneExcludedField');
            historyTracking = HistoryTrackingUtil.historyTracking(historyWrapper);
            Test.stopTest();
        }
        System.assertEquals(true, IncludeFieldsforTracking <> null);
        System.assertEquals(true, historyTracking <> null);
    }
}