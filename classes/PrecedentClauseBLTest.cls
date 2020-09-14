/*
* @author:          Kyle Tan
* @description:     Test Class for PrecedentClauseBL
*/
@isTest
private class PrecedentClauseBLTest {
    
    //testSetup
    @TestSetup private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Property__c propertyRecord = new Property__c();
        Account accountRecord = new Account();
        PrecedentClause__c precedentClauseRecord = new PrecedentClause__c();        
        List<Property__c> propertyList = new List<Property__c>();
        List<Account> accountList = new List<Account>();
        List<Account> tempAccountList = new List<Account>();
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<PrecedentClause__c> precedentClauseList = new List<PrecedentClause__c>();
        
        Product2 productRecord;
        
        //CREATE PRODUCT
        productRecord = TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, Constants.RENT);
        insert productRecord;
        
        //CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(10);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(10, pricebookList[0]);
        database.insert(propertyList);
        Property__c propRec = [SELECT Id FROM Property__c LIMIT 1];
        //CREATE ACCOUNT
        accountList = TestDataFactory.createAccountBulk(10, 
                                                        propertyRecord.Id, 
                                                        accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId());
        database.insert(accountList);
        tempAccountList = [SELECT Id 
                            FROM Account 
                            WHERE ParentId = null 
                            AND RecordTypeId = :accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId() 
                            LIMIT 10];
        accountList = new List<Account>();
        for(Integer counter = 0; counter < 10; counter++) {
            accountRecord = TestDataFactory.createAccountwithParent(counter, 
                                                                    null, 
                                                                    accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), 
                                                                    tempAccountList.get(counter).Id);
            accountList.add(accountRecord);
        }
        Test.startTest();
        database.insert(accountList);
        
        //CREATE OPPORTUNITY
        accountList = [SELECT Id, Account.Property__c FROM Account WHERE ParentId != null LIMIT 10];
        
        opportunityList = TestDataFactory.createOpportunity(accountList);
        
        database.insert(opportunityList);
        
        //CREATE PRECEDENT CLAUSE
        accountList = [SELECT Id 
                        FROM Account 
                        WHERE ParentId = null 
                        AND RecordTypeId = :accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId() 
                        LIMIT 10];

        for(Integer counter = 0; counter < 10; counter++) {
            precedentClauseRecord = TestDataFactory.createPrecedentClause(counter, accountList.get(counter).Id);
            precedentClauseList.add(precedentClauseRecord);
        }
        
        database.insert(precedentClauseList);
        Test.stopTest();
        
    }
    
    /*
    * @author:          Kyle Tan
    * @description:     Test Class for updateOpportunityClause
    */
    public static testMethod void updateOpportunityClauseTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        OpportunityClause__c opportunityClauseRecord = new OpportunityClause__c();
        List<OpportunityClause__c> opportunityClauseList = new List<OpportunityClause__c>();
        
        system.runAs(testUser) {
            Test.startTest();
            
            for(PrecedentClause__c tempPrecedentClauseRecord : [SELECT Id, Type__c, Name, Description__c, 
                                                                Comments__c, EffectiveToDate__c 
                                                                FROM PrecedentClause__c 
                                                                LIMIT 200]) {
                opportunityClauseRecord = PrecedentClauseBL.updateOpportunityClause(new OpportunityClause__c(), tempPrecedentClauseRecord);
                opportunityClauseList.add(opportunityClauseRecord);
            }
            
            Test.stopTest();
        }
        
        for(OpportunityClause__c tempOpportunityClause : opportunityClauseList) {
            system.assertEquals('Usage', tempOpportunityClause.Type__c); 
            system.assert(String.valueOf(tempOpportunityClause.ClauseDetails__c).startsWith('Test Description'));
            system.assert(String.valueOf(tempOpportunityClause.LeasingComment__c).startsWith('Test Comments'));
        }
        
    }
    
    /*
    * @author:          Kyle Tan
    * @description:     Test Class for buildOpportunityClauseMap
    */
    public static testMethod void buildOpportunityClauseMapTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Set<Id> precedentClauseIdSet = new Set<Id>();
        Map<Id, List<OpportunityClause__c>> buildOpportunityClauseMap = new Map<Id, List<OpportunityClause__c>>();
        
        
        for(PrecedentClause__c precedentClauseRecord : [SELECT Id FROM PrecedentClause__c LIMIT 200]) {
            precedentClauseIdSet.add(precedentClauseRecord.Id);
        }
        
        System.runAs(testUser) {
            Test.startTest();
            
            buildOpportunityClauseMap = PrecedentClauseBL.buildOpportunityClauseMap(precedentClauseIdSet);
            
            Test.stopTest();
        }
        
        system.assertEquals(10, buildOpportunityClauseMap.size());
    }
    
    /*
    * @author:          Kyle Tan
    * @description:     Test Class for buildopportunityFromAccountMap
    */
    public static testMethod void buildopportunityFromAccountMapTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Set<Id> precedentClauseAccountIdSet = new Set<Id>();
        Map<Id, List<Opportunity>> opportunityFromAccountMap = new Map<Id, List<Opportunity>>();
        
        for(PrecedentClause__c precedentClauseRecord : [SELECT Id, Account__c FROM PrecedentClause__c LIMIT 200]) {
            precedentClauseAccountIdSet.add(precedentClauseRecord.Account__c);
        }
        
        System.runAs(testUser) {
            Test.startTest();
            
            opportunityFromAccountMap = PrecedentClauseBL.buildopportunityFromAccountMap(precedentClauseAccountIdSet);
            
            Test.stopTest();
        }
        
        system.assertEquals(opportunityFromAccountMap.size(), 10);
    }
    
}