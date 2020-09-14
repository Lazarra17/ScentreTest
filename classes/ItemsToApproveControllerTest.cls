@isTest
public class ItemsToApproveControllerTest {
    
    @testSetup
    private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> caseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.OBJECT_CASE);
        List<Account> accountList = new List<Account>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Contract__c> contractList = new List<Contract__c>();
        
        List<Pricebook2> priceBookList = TestDataFactory.createPricebook(1);
        Database.insert(priceBookList);
        Pricebook2 priceBookRec = [SELECT Id, CurrencyIsoCode FROM Pricebook2 LIMIT 1];
        
        Property__c property = TestDataFactory.createProperty(1, priceBookRec)[0];
        property.PropertyStatus__c = 'Active';
        Database.insert(property);
        Property__c propRec = [SELECT Id, Name FROM Property__c LIMIT 1];
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Type = 'Forecast';
        acc.Property__c = propRec.Id;
        acc.TradingName__c = 'ABCZ';
        acc.RecordTypeId = accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId();
        acc.ShippingCountry = 'Australia';
        acc.ShippingStreet = '1234 Test Street Drive';
        acc.ShippingCity = 'Sydney';
        acc.ShippingState = 'Queensland';
        acc.ShippingPostalCode = '1234';
        acc.BillingCountry = 'Australia';
        acc.BillingStreet = '1234 Test Street Drive';
        acc.BillingCity = 'Sydney';
        acc.BillingState = 'Queensland';
        acc.BillingPostalCode = '1234';
        acc.BillingEmailAddress__c = 'testemail@address.com';
        acc.ACN__c = 'ACN';
        acc.Category__c = 'S420';
        acc.SuperfineCategory__c = 'S421';
        acc.LesseeName__c = 'Test Lessee';
        insert acc;
        
        List<Space__c> spaceList = TestDataFactory.createSpace(5, propRec);
        Map<String, Schema.RecordTypeInfo> spaceRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName(Constants.SPACE);
        
        for(Space__c space : spaceList){
            space.RentableArea__c = 40;
            space.DevelopmentType__c = null;
            space.RecordTypeId = spaceRecordTypeMap.get(Constants.PROSPECTIVE_SPACE).getRecordTypeId();
        }
        Database.insert(spaceList);

        List<Contract__c> contrList = TestDataFactory.createContract(1, acc);
        contrList[0].space__c = spaceList[0].id;
        database.insert(contrList);
        
        Case cs = TestDataFactory.createCase(acc, CaseRecordTypeMapByName.get(CONSTANTS.CASE_RECORDTYPE_INSPECTIONREPORT).getRecordTypeId(), contrList[0].Id);
        Database.insert(cs);
    }
    
    @isTest
    public static void testOpportunityApproval(){
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        
        List<Opportunity> opp = [Select Id From Opportunity];
        opp[0].GMRetailAdmin__c = UserInfo.getUserId();
        opp[0].GMLARS__c = UserInfo.getUserId();
        opp[0].GroupGeneralManagerLARS__c = UserInfo.getUserId();
        opp[0].ApprovalSubmitter__c = UserInfo.getUserId();
        opp[0].RMRetailAdmin__c = UserInfo.getUserId();
        opp[0].DirectorLARSNZDevelopment__c = UserInfo.getUserId();
        opp[0].RetailManager__c = UserInfo.getUserId();
        opp[0].RMLARS__c = UserInfo.getUserId();
        
        update opp[0];
        
        req1.setObjectId(opp[0].id);
        
        // Submit on behalf of a specific submitter
        req1.setSubmitterId(UserInfo.getUserId()); 
        
        // Submit the record to specific process and skip the criteria evaluation
        req1.setProcessDefinitionNameOrId('RetailInitialApproval_v2');
        req1.setSkipEntryCriteria(true);
        
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(req1);
        
        test.startTest();
        List<ItemsToApproveController.ItemToApproveWrapper> itemsToApprove = ItemsToApproveController.getItemsToApprove();
        test.stopTest();
        System.debug('itemsToApprove === '+itemsToApprove);
        System.assertEquals(itemsToApprove.size(), 1);
    }
    
    @isTest
    public static void testCaseApproval(){
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        
        Case cs = [SELECT id, TechRegionalLeasingManager__c FROM Case LIMIT 1];
        cs.TechRegionalLeasingManager__c = UserInfo.getUserId();
        cs.TechRegionalManagerRetailAdmin__c = UserInfo.getUserId();
        
        update cs;
        req1.setObjectId(cs.Id);
        // Submit on behalf of a specific submitter
        req1.setSubmitterId(UserInfo.getUserId()); 
        
        // Submit the record to specific process and skip the criteria evaluation
        req1.setProcessDefinitionNameOrId('CAS_GMLeasingApproval');
        req1.setSkipEntryCriteria(true);
        /*List<Id> approverIds = new List<Id>();
        approverIds.add(UserInfo.getUserId());
        req1.setNextApproverIds(approverIds);*/
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(req1);
        
        test.startTest();
        List<ItemsToApproveController.ItemToApproveWrapper> itemsToApprove = ItemsToApproveController.getItemsToApprove();
        ItemsToApproveController.saveItemToApprove(itemsToApprove[0].workItemId, 'Approve', 'Test Comments', UserInfo.getUserId());
        test.stopTest();
        System.debug('itemsToApprove === '+itemsToApprove);
        System.assertEquals(itemsToApprove.size(), 1);
        
    }
    
}