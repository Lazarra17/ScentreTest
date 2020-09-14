@isTest
public class ShareContentVersionWCGBtest {
    @TestSetup private static void testSetup(){
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
        
        //Create Space
        List<Space__c> spaceList = new List<Space__c>();
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        database.insert(spaceList);
        
        //Create Opportunity
        List<Opportunity> oppList = new List<Opportunity>();
        oppList = TestDataFactory.createOpportunity(1, accountList[0], propertyList[0], spaceList[0]);
        database.insert(oppList);
        
        //Create Content Version
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        contentVersionList.add(TestDataFactory.createContentVersion('Lease Plan Test File', 'Plans', 'Lease Plan'));
        database.insert(contentVersionList);
        contentVersionList = [SELECT Id, ContentDocumentId FROM ContentVersion];
        
        //Create DocumentLink
        List<ContentDocumentLink> contentDocLinkList = new List<ContentDocumentLink>();
        contentDocLinkList.add(TestDataFactory.createContentDocumentLink(spaceList[0].Id, contentVersionList[0]));
        database.insert(contentDocLinkList);
        
    }
    
    public static testMethod void callBatchShareContentVersionWCGB(){
        Test.startTest();
        ShareContentVersionWithChatterGroupBatch SCVWCGB = new ShareContentVersionWithChatterGroupBatch();
        Database.executeBatch(SCVWCGB, 200);
        Test.stopTest();
    }

}