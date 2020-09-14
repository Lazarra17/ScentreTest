/*
* @author:              Sidney Garcia
* @description:         Test class for ContentBL
*/
@isTest
public class ContentBLTest {
    @TestSetup private static void testSetup() {
        Property__c testProperty = new Property__c();
        List<Account> accountList = new List<Account>();
        Account accountRecord = new Account();
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Opportunity> opportunityList = new List<Opportunity>();
        Opportunity opportunityRecord = new Opportunity();
        List<Space__c> spaceList = new List<Space__c>();
        Product2 productRecord;
        
        //CREATE PRODUCT
        
        productRecord = TestDataFactory.createProduct(Constants.FEES_CHARGES, Constants.FEES_CHARGES);
        productRecord.SpaceBillingCategory__c = 'NA';
        insert productRecord;
        
        
        Id pricebookId = Test.getStandardPricebookId();
        
        //CREATE PROPERTY
        testProperty = TestDataFactory.createPropertyRecord();
        testProperty.PriceBook__c = pricebookId;
        database.insert(testProperty);
        
        //CREATE SPACE
        spaceList = TestDataFactory.createSpace(10, testProperty);
        
        for(Space__c spaceRec : spaceList){
            spaceRec.OccupancyStatus__c = Constants.SPACE_OCCUPANCYSTATUS_TRADING;
            spaceRec.Status__c = Constants.SPACE_STATUS_TRADING;
            spaceRec.Type__c = '2';
        }
        
        database.insert(spaceList);
        
        //CREATE ACCOUNT
        for(Integer counter = 0; counter < 5; counter++) {
            accountRecord = TestDataFactory.createAccount(counter, testProperty.Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId());
            accountList.add(accountRecord);
        }
        database.insert(accountList);
        accountList = [SELECT Id, Property__c FROM Account LIMIT 5];
        Contact contactRecord = TestDataFactory.createContact(CONSTANTS.TEST_FNAME, accountList[0]);
        insert contactRecord;
        
        //CREATE Opportunity
        opportunityList = TestDataFactory.createOpportunity(10, accountList[0]);
        for(Opportunity opp : opportunityList){
            opp.Space__c = spaceList[0].Id;
        }
        insert opportunityList;
        
        List<ContentDocumentLink> conDocLinkList = new List<ContentDocumentLink>();
        ContentDocumentLink conDLRecord = new ContentDocumentLink();
        
        ContentVersion cv=new Contentversion();
        cv.title='ABC';
        cv.PathOnClient ='test';
        Blob b = Blob.valueOf('Unit Test Attachment Body');
        cv.versiondata=EncodingUtil.base64Decode('Unit Test Attachment Body');
        cv.DocumentCategory__c = 'Plans';
        cv.DocumentType__c = Constants.LEASE_PLAN;
        Database.insert(cv);
        
        ContentVersion conVer = new ContentVersion();
        conVer = [SELECT Id, title, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id];
        
        conDLRecord.ContentDocumentId = conVer.ContentDocumentId;
        conDLRecord.LinkedEntityId = opportunityList[0].Space__c;
        conDLRecord.ShareType = 'V';
        conDLRecord.Visibility = 'AllUsers';
        
        insert conDLRecord;
    }
    public static testMethod void testCreateContentDocumentLink(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        List<Opportunity> oppList = [SELECT Id, Space__c, Type FROM Opportunity LIMIT 10];
        List<ContentDocumentLink> conDocLinkList = new List<ContentDocumentLink>();
        System.runAs(testUser) {
            Test.startTest();
            conDocLinkList = ContentBL.createContentDocumentLink(oppList, 'Opportunity');
            Test.stopTest();
        }
        
        System.assert(conDocLinkList <> null);
        
    }
}