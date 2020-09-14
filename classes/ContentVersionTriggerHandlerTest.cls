@isTest
public class ContentVersionTriggerHandlerTest {
 
    public static testMethod void testGetATracking(){
        ContentVersion cv=new Contentversion();
        cv.title='TEST Title';
        cv.PathOnClient ='test';
        Blob b = Blob.valueOf('Unit Test Attachment Body');
        cv.versiondata=EncodingUtil.base64Decode('Unit Test Attachment Body');
        cv.DocumentCategory__c = 'Plans';
        cv.DocumentType__c = Constants.LEASE_PLAN;
        Database.insert(cv);
    }
    
    public static testMethod void testLinkDocumentToGroup() {
        Id groupId = Label.SketchLeasePlanUserGroup;
        // Create Content Version
        ContentVersion cv = new ContentVersion(
            Title = 'Test Title',
            PathOnClient = 'Test.jpg',
            VersionData = EncodingUtil.base64Decode('Unit Test Attachment Body 1'),
            DocumentCategory__c = 'Plans',
            DocumentType__c = Constants.SKETCH_PLAN_DOC
        );
        
        Test.startTest();
        insert cv;
        Test.stopTest();
        
        List<ContentDocumentLink> docLinks = [SELECT Id, LinkedEntityId, ContentDocumentid FROM ContentDocumentLink WHERE LinkedEntityId=:groupId];
        
        System.debug('ContentDocumentLinks : ' + docLinks);
        //System.assertEquals(docLinks.size(), 1);
        
    }
    
}