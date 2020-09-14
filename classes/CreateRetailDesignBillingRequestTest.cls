/**
 * @author:			Kyle Tan
 * @desc:			test class for CreateRetailDesignBillingRequest
 **/
@isTest
private class CreateRetailDesignBillingRequestTest {
    
    @testSetup 
    private static void testSetup() {
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
        database.insert(accountList);
        
        //Create Space
        List<Space__c> spaceList = new List<Space__c>();
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        database.insert(spaceList);
        
        //Create Opportunity
        List<Opportunity> oppList = new List<Opportunity>();
        oppList = TestDataFactory.createOpportunity(1, accountList[0], propertyList[0], spaceList[0]);
        oppList[0].DevelopmentType__c = '';
        database.insert(oppList);
        
        //Create Contract
        List<Contract__c> contractList = new List<Contract__c>();
        contractList.addAll(TestDataFactory.createContract(1, accountList[0]));
        database.insert(contractList);
        
        //Create Case
        Map<String, Schema.RecordTypeInfo> caseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OBJECT_CASE);
        List<Case> caseList = new List<Case>();
        caseList.add(TestDataFactory.createCase(contractList[0], spaceList[0], caseRecordTypeMapByName.get(Constants.REQUEST_FOR_REFUND).getRecordTypeId()));
        caseList.add(TestDataFactory.createCase(contractList[0], spaceList[0], caseRecordTypeMapByName.get(Constants.INSPECTION_REPORT).getRecordTypeId()));
        caseList.add(TestDataFactory.createCase(contractList[0], spaceList[0], caseRecordTypeMapByName.get(Constants.RETAIL_DESIGN_INSTRUCTION).getRecordTypeId()));
        caseList.add(TestDataFactory.createCase(contractList[0], spaceList[0], caseRecordTypeMapByName.get(Constants.STATEMENT_OF_COMPLETION).getRecordTypeId()));
        for(Case caseRec :caseList) {
            caseRec.Opportunity__c = oppList[0].Id;
        }
        database.insert(caseList);
    }
    
    /**
     * @author:			Kyle Tan
     **/
    private static testMethod void testCreateCases() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id FROM Case]);
        List<Id> idList = new List<Id>(caseMap.keySet());
        system.runAs(testUser) {
            test.startTest();
            CreateRetailDesignBillingRequest.retailDesignBillingCase(idList);
            test.stopTest();
        }
    }
}