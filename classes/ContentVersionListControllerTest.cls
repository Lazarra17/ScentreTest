@isTest
private class ContentVersionListControllerTest {
    @TestSetup 
    private static void testSetup(){
        // CREATE ACCOUNT
        Account acc = TestDataFactory.createAccount(1);
        Database.insert(acc);
        
        //CREATE PRICEBOOK
        List<Pricebook2> pricebookList = TestDataFactory.createPricebook(1);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        // CREATE PROPERTY
        List<Property__c> propertyList = TestDataFactory.createProperty(1, pricebookList[0]);
        database.insert(propertyList);
        
        // CREATE OPPORTUNITY
        List<Opportunity> opportunityList = TestDataFactory.createOpportunity(1, acc, propertyList[0]);
        database.insert(opportunityList);
        
        ContentVersion cv=new Contentversion();
        cv.title='ABC';
        cv.PathOnClient ='test';
        Blob b = Blob.valueOf('Unit Test Attachment Body');
        cv.versiondata=EncodingUtil.base64Decode('Unit Test Attachment Body');
        cv.DocumentCategory__c = 'Assignment';
        cv.DocumentType__c = 'Deed of Assignment';
        Database.insert(cv);
        
        ContentDocumentLink conDocLink = new ContentDocumentLink();
        ContentVersion conVer = new ContentVersion();
        
        conVer = [SELECT Id, title, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id];
        
        conDocLink.ContentDocumentId = conVer.ContentDocumentId;
        conDocLink.LinkedEntityId = opportunityList[0].Id;
        conDocLink.ShareType = 'V';
        conDocLink.Visibility = 'AllUsers';

        insert conDocLink;
    }
    
    @isTest
    private static void testGetAllFiles() {
        LightningResponse res;
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        
        Test.startTest();
            res = ContentVersionListController.getallfiles(opp.Id);
        Test.stopTest();
        
        system.assertEquals('SUCCESS', res.status);
    }
    
    @isTest
    private static void testGetAllFilesFail() {
        LightningResponse res;
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        
        Test.startTest();
            res = ContentVersionListController.getallfiles(acc.Id);
        Test.stopTest();
        
        system.assertEquals('FAILED', res.status);
    }
    
    @isTest
    private static void testUpdateContentVersionFail() {
        String cVersionJSON;
        LightningResponse res;
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        ContentVersionListController.ContentVersionWrapper cVersionWrapper;
        List<ContentVersion> cVersionList = new List<ContentVersion>();
        
        res = ContentVersionListController.getallfiles(opp.Id);
        
        cVersionWrapper = (ContentVersionListController.ContentVersionWrapper) JSON.deserialize(res.returnValue, ContentVersionListController.ContentVersionWrapper.class);
        
        for(ContentVersionListController.ContentVersionDetailWrapper cVersionWrap : cVersionWrapper.contentVersionList){
            cVersionWrap.contentVersion.FinalVersion__c = true;
            cVersionWrap.contentVersion.DocumentType__c = 'Acceptance Letter';
            cVersionWrap.contentVersion.DocumentCategory__c = 'Plans';
            
            cVersionList.add(cVersionWrap.contentVersion);
        }
        
        cVersionJSON = JSON.serialize(cVersionList);
        
        Test.startTest();
            res = ContentVersionListController.updateContentVersion(String.valueOf(opp.Id), cVersionJSON);
        Test.stopTest();
        
        system.assertEquals('FAILED', res.status);
    }
    
    @isTest
    private static void testUpdateContentVersion() {
        String cVersionJSON;
        LightningResponse res;
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        ContentVersionListController.ContentVersionWrapper cVersionWrapper;
        List<ContentVersion> cVersionList = new List<ContentVersion>();
        
        res = ContentVersionListController.getallfiles(opp.Id);
        
        cVersionWrapper = (ContentVersionListController.ContentVersionWrapper) JSON.deserialize(res.returnValue, ContentVersionListController.ContentVersionWrapper.class);
        
        for(ContentVersionListController.ContentVersionDetailWrapper cVersionWrap : cVersionWrapper.contentVersionList){
            cVersionWrap.contentVersion.FinalVersion__c = true;
            cVersionWrap.contentVersion.DocumentType__c = 'Lease Plan';
            cVersionWrap.contentVersion.DocumentCategory__c = 'Plans';
            
            cVersionList.add(cVersionWrap.contentVersion);
        }
        
        cVersionJSON = JSON.serialize(cVersionList);
        
        Test.startTest();
            res = ContentVersionListController.updateContentVersion(String.valueOf(opp.Id), cVersionJSON);
        Test.stopTest();
        
        //system.assertEquals('SUCCESS', res.status);
        
        res = ContentVersionListController.getallfiles(opp.Id);
        
        cVersionWrapper = (ContentVersionListController.ContentVersionWrapper) JSON.deserialize(res.returnValue, ContentVersionListController.ContentVersionWrapper.class);
        
        for(ContentVersionListController.ContentVersionDetailWrapper cVersionWrap : cVersionWrapper.contentVersionList){
            //system.assert(cVersionWrap.contentVersion.FinalVersion__c);
            //system.assertEquals('Plans', cVersionWrap.contentVersion.DocumentCategory__c);
            //system.assertEquals('Lease Plan', cVersionWrap.contentVersion.DocumentType__c);
        }
    }
}