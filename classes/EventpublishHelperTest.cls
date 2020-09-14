/**
 * @author:				Kyle Tan
 * @desc:				Test Class for EventpublishHelper
 **/
@isTest
private class EventpublishHelperTest {
    
    @testSetup
    private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        
        //Create Price Book
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //Create Property
        List<Property__c> propertyList = new List<Property__c>();
        propertyList = TestDataFactory.createProperty(1, priceBookList[0]);
        database.insert(propertyList);
        
        //Create Account
        List<Account> accountList = new List<Account>();
        accountList = TestDataFactory.createAccountBulk(5, propertyList[0].Id, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
        database.insert(accountList);
        
        //Create Contact
        List<Contact> contactList = new List<Contact>();
        contactList.add(TestDataFactory.createContact('Test Name', accountList[0]));
        database.insert(contactList);
        
        //Create Space
        List<Space__c> spaceList = new List<Space__c>();
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        database.insert(spaceList);
        
        //Create Opportunity
        List<Opportunity> oppList = new List<Opportunity>();
        oppList = TestDataFactory.createOpportunity(1, accountList[0], propertyList[0], spaceList[0]);
        database.insert(oppList);
        
        //Create Case
        List<Case> caseList = new List<Case>();
        caseList.addAll(TestDataFactory.createCase(5, contactList[0]));
        database.insert(caseList);
    }
    
    /**
     * @author:		Kyle Tan
     **/
    @isTest
    private static void opportunityFieldChangePublishHelperTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        EventpublishHelper.Eventpublishwrapper wrapper = new EventpublishHelper.Eventpublishwrapper();
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>([SELECT Id, JDESentStatus__c FROM Opportunity]);
        Map<Id, Opportunity> newOppMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([SELECT Id, JDESentStatus__c FROM Opportunity]);
        for(Opportunity oppRec :opportunityMap.values()) {
            opportunityMap.get(oppRec.Id).JDESentStatus__c = 'Ready';
            oldOppMap.get(oppRec.Id).JDESentStatus__c = 'Processing';
        }
        system.runAs(testUser) {
            test.startTest();
            EventpublishHelper callClass = new EventpublishHelper();
            wrapper = EventpublishHelper.opportunityFieldChangePublishHelper(oldOppMap, newOppMap, opportunityMap);
            test.stopTest();
        }
    }
    
    /**
     * @author:		Kyle Tan
     **/
    @isTest
    private static void caseFieldChangePublishHelperTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        EventpublishHelper.Eventpublishwrapper wrapper = new EventpublishHelper.Eventpublishwrapper();
        Map<Id, Case> oldCaseMap = new Map<Id, Case>([SELECT Id, Type, JDESentStatus__c FROM Case]);
        Map<Id, Case> newCaseMap = new Map<Id, Case>();
        Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, Type, JDESentStatus__c FROM Case]);
        for(Case caseRec :caseMap.values()) {
            caseMap.get(caseRec.Id).JDESentStatus__c = 'Ready';
            oldCaseMap.get(caseRec.Id).JDESentStatus__c = 'Ready';
            caseMap.get(caseRec.Id).Type = 'Checksheet';
            oldCaseMap.get(caseRec.Id).Type = '	Inspection Request';
        }
        system.runAs(testUser) {
            test.startTest();
            wrapper = EventpublishHelper.caseFieldChangePublishHelper(oldCaseMap, newCaseMap, caseMap);
            wrapper = EventpublishHelper.caseFieldChangePublishHelper(null, newCaseMap, caseMap);
            test.stopTest();
        }
    }
    
    /**
     * @author:		Kyle Tan
     **/
    @isTest
    private static void acrFieldChangePublishHelperTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Id> validACRIds = new List<Id>();
        Map<Id, AccountContactRelation> oldACRMap = new Map<Id, AccountContactRelation>([SELECT Id, IsActive FROM AccountContactRelation]);
        Map<Id, AccountContactRelation> acrMap = new Map<Id, AccountContactRelation>([SELECT Id, IsActive FROM AccountContactRelation]);
        for(AccountContactRelation acrRec :acrMap.values()) {
            acrMap.get(acrRec.Id).IsActive = true;
            oldACRMap.get(acrRec.Id).IsActive = false;
        }
        system.runAs(testUser) {
            test.startTest();
            validACRIds = EventpublishHelper.acrFieldChangePublishHelper(oldACRMap, acrMap);
            test.stopTest();
        }
    }
    
    /**
     * @author:		Kyle Tan
     **/
    @isTest
    private static void contactFieldChangePublishHelperTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Id> activeContactIds = new List<Id>();
		Map<Id, Contact> oldContactMap = new Map<Id, Contact>([SELECT Id, Phone FROM Contact]);
        Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id, Phone FROM Contact]);
        for(Contact contactRec :contactMap.values()) {
            contactMap.get(contactRec.Id).Phone = '12345';
            oldContactMap.get(contactRec.Id).Phone = '54321';
        }
        system.runAs(testUser) {
            test.startTest();
            activeContactIds = EventpublishHelper.contactFieldChangePublishHelper(oldContactMap, contactMap);
            test.stopTest();
        }
    }
    
    /**
     * @author:		Kyle Tan
     **/
    @isTest
    private static void accountFieldChangePublishHelperTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        EventpublishHelper.Eventpublishwrapper wrapper = new EventpublishHelper.Eventpublishwrapper();
        Map<Id, Account> oldAccountMap = new Map<Id, Account>([SELECT Id, Phone FROM Account]);
        Map<Id, Account> newAccountMap = new Map<Id, Account>();
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Phone FROM Account]);
        for(Account accRec :accountMap.values()) {
            accountMap.get(accRec.Id).Phone = '12345';
            oldAccountMap.get(accRec.Id).Phone = '54321';
        }
        system.runAs(testUser) {
            test.startTest();
            wrapper = EventpublishHelper.accountFieldChangePublishHelper(oldAccountMap, newAccountMap, accountMap);
            test.stopTest();
        }
    }
    
    /**
     * @author:		Kyle Tan
     **/
    @isTest
    private static void spacefieldChangepublishHelperTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        EventpublishHelper.Eventpublishwrapper wrapper = new EventpublishHelper.Eventpublishwrapper();
        Map<Id, Space__c> oldSpaceMap = new Map<Id, Space__c>([SELECT Id, Status__c FROM Space__c]);
        Map<Id, Space__c> newSpaceMap = new Map<Id, Space__c>();
        Map<Id, Space__c> spaceMap = new Map<Id, Space__c>([SELECT Id, Status__c FROM Space__c]);
        for(Space__c spaceRec :spaceMap.values()) {
            spaceMap.get(spaceRec.Id).Status__c = 'New';
            oldSpaceMap.get(spaceRec.Id).Status__c = 'Held';
        }
        system.runAs(testUser) {
            test.startTest();
            wrapper = EventpublishHelper.SpacefieldChangepublishHelper(oldSpaceMap, spaceMap, newSpaceMap);
            test.stopTest();
        }
    }
}