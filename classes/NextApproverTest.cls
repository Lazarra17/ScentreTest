@isTest
public class NextApproverTest {
  
  @isTest
    static void myUnitTest() {
    Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
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

        //CREATE ACCOUNT
        //accountList.addAll(TestDataFactory.createAccountBulk(10, property.Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        
        //database.insert(accountList);
        test.startTest();
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
            //test.startTest();
            Database.insert(spaceList);
            CreateForecastOpportunity.checkSpaceCriteria(spaceList);
            
            Approval.ProcessSubmitRequest req1 = 
            new Approval.ProcessSubmitRequest();
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
            
            NextApprover.getNextApprover(opp[0].id);
            NextApprover.getNextApprover(opp[1].id);
            Approval.Unlock(opp[0].id);
        	opp[0].ApprovalStatus__c = 'Initial Approval Rejected'; 
            opp[0].Pending_Approver__c = UserInfo.getUserId();
            update opp[0];
        	NextApprover.getNextApprover(opp[0].id);
            test.stopTest();
    }
    
}