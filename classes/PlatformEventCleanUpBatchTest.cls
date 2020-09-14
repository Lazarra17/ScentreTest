/**
 * @author:			Kyle Tan
 * @description:	Test Class for PlatformEventCleanUpBatch
 **/
@isTest
private class PlatformEventCleanUpBatchTest {
    
    @testSetup
    private static void testSetup(){
        //Create Price Book
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //Create Property
        List<Property__c> propertyList = new List<Property__c>();
        propertyList = TestDataFactory.createProperty(1, priceBookList[0]);
        database.insert(propertyList);

        //Create Account
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        List<Account> accountList = new List<Account>();
        accountList = TestDataFactory.createAccountBulk(5, propertyList[0].Id, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
        for(Account accRec :accountList) {
            accRec.TechAcknowledgeVersion__c = 1;
			accRec.TechDispatchedVersion__c = 2;
        }
        database.insert(accountList);
                
        //Create Contact
        Contact conRec = new Contact();
        conRec = TestDataFactory.createContact('Test Contact', accountList[0]);
        conRec.TechAcknowledgeVersion__c = 1;
        conRec.TechDispatchedVersion__c = 2;
        database.insert(conRec);
        
        //Create Space
        List<Space__c> spaceList = new List<Space__c>();
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        for(Space__c spaceRec :spaceList) {
            spaceRec.TechAcknowledgeVersion__c = 1;
            spaceRec.TechDispatchedVersion__c = 2;
        }
        database.insert(spaceList);
        
        //Create Opportunity
        List<Opportunity> oppList = new List<Opportunity>();
        oppList = TestDataFactory.createOpportunity(1, accountList[0], propertyList[0], spaceList[0]);
        for(Opportunity oppRec :oppList) {
            oppRec.TechAcknowledgeVersion__c = 1;
            oppRec.TechDispatchedVersion__c = 2;
            oppRec.JDESentStatus__c = 'Ready';
        }
        database.insert(oppList);
        
        //Create Contract
        List<Contract__c> contractList = new List<Contract__c>();
        contractList.addAll(TestDataFactory.createContract(1, accountList[0]));
        database.insert(contractList);
        
        //Create Case
        Map<String, Schema.RecordTypeInfo> caseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OBJECT_CASE);
        List<Case> caseList = new List<Case>();
        caseList.add(TestDataFactory.createCase(contractList[0], spaceList[0], caseRecordTypeMapByName.get(Constants.REQUEST_FOR_REFUND).getRecordTypeId()));
        for(Case caseRec :caseList) {
            caseRec.TechAcknowledgeVersion__c = 1;
            caseRec.TechDispatchedVersion__c = 2;
            caseRec.JDESentStatus__c = 'Ready';
        }
        database.insert(caseList);
    }
    
    /**
     * @author:			Kyle Tan
     **/
    private static testMethod void PlatformEventCleanUpBatch() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        system.runAs(testUser){
            test.startTest();
            PlatformEventCleanUpBatch batch = new PlatformEventCleanUpBatch();
            Id batchJobID = database.executeBatch(batch);
            test.stopTest();
        }
    }
}