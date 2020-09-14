@isTest
public class ApproveStatusControllerTest {
    @TestSetup private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> caseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.OBJECT_CASE);
        Product2 productRecord;
        List<Property__c> propertyList = new List<Property__c>();
        List<Account> accountList = new List<Account>();
        List<Account> tempAccountList = new List<Account>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<contact> contactList = new list<contact>();
        List<case> caseList = new list<case>();
        List<User> userList = new List<User>();
        List<Contract__c> contrList = new List<Contract__c>();
        List<Space__c> spaceLst = new List<Space__c>();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        
        
        //CREATE PRODUCT
        productRecord = TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, Constants.RENT);
        insert productRecord;
        
        List<Pricebook2> priceBookList = TestDataFactory.createPricebook(1);
        Database.insert(priceBookList);
        Pricebook2 priceBookRec = [SELECT Id, CurrencyIsoCode FROM Pricebook2 LIMIT 1];
        //System.debug('Pricebook rec ' + priceBookRec);
        
        propertyList = TestDataFactory.createProperty(1);
        for(Property__c property : propertyList){
            property.PriceBook__c = priceBookRec.Id;
        }
        Database.insert(propertyList);
        propertyList = [SELECT Id FROM Property__c LIMIT 5];
        //CREATE ACCOUNT
        accountList.addAll(TestDataFactory.createAccountBulk(1, propertyList[0].Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        
        database.insert(accountList);
        //System.debug('Account List ' + accountList);
        //CREATE OPPORTUNITY
        accountList = [SELECT Id, Property__c, Name FROM Account LIMIT 1];
        
        //CREATE SPACE
        spaceLst = TestDataFactory.createSpace(1, propertyList[0]);
        spaceLst[0].type__c = '1';
        spaceLst[0].BillingCategory__c = 'NA';
        database.insert(spaceLst);
        
        //CREATE CONTRACT
        spaceLst = [SELECT Id, Type__c FROM Space__c];
        contrList = TestDataFactory.createContract(1, accountList[0]);
        contrList[0].space__c = spaceLst[0].id;
        database.insert(contrList);
        
        opportunityList = TestDataFactory.createOpportunity(1, accountList[0], propertyList, spaceLst);
        for(Opportunity oppo : opportunityList){
            oppo.AnnualMinimumRent__c = 10000;
            oppo.ApprovalStatus__c = CONSTANTS.PENDING_INI_APRV;
        }
        //System.debug('Opportunity List' + opportunityList);
        database.insert(opportunityList);
        
        //Create Clause Library
        List<ClauseLibrary__c> clauseLibList = new List<ClauseLibrary__c>();
        clauseLibList = TestDataFactory.createClauseLibrary(1);
        database.insert(clauseLibList);
        
        //Create Opportunity Clause
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>();
        oppClauseList = TestDataFactory.createOpportunityClause(1, opportunityList[0], clauseLibList[0]);
        oppClauseList[0].Type__c = 'Usage';
        database.insert(oppClauseList);
        
        
    }
    
    public static testMethod void testGetATracking(){
        
        List<Opportunity> oppList = [Select id,ApprovalStatus__c from Opportunity limit 1];
        ApproveStatusController apprvstat = new ApproveStatusController();
        apprvstat.OppObj = oppList[0].id;
        List<OpportunityAuditHistory__c> oppAuditList = new List<OpportunityAuditHistory__c>();
        String newValue = '90000';
        String previousValue = CONSTANTS.EMPTY;
        oppAuditList = TestDataFactory.createOpportunityAuditHistory(oppList[0], CONSTANTS.ANNUAL_MINIMUM_RENT_API, newValue, previousValue, oppList[0].ApprovalStatus__c ,1);
        insert oppAuditList;
        apprvstat.getATracking();
        apprvstat.getUsageClause();

        
        /*
        
        
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Opportunity> oppList = [SELECT Id, ApprovalStatus__c FROM Opportunity LIMIT 200];
        HistoryTrackingUtil.HistoryTrackingWrapper historyWrapper = new HistoryTrackingUtil.HistoryTrackingWrapper();
        Set<String> IncludeFieldsforTracking = new Set<String>();
        List<Opportunity> historyTracking = new List<Opportunity>();
        LightningResponse wrapper = new LightningResponse();
        List<OpportunityAuditHistory__c> oppAuditList = new List<OpportunityAuditHistory__c>();
        
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
            
            for(Opportunity opp : oppList){
                wrapper = ApproveSummaryTracking.getChangedItem(opp.Id);
            }
            
            Test.stopTest();
        }*/
        
        
    }
}