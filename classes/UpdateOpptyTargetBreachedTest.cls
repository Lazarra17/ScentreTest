@isTest
public class UpdateOpptyTargetBreachedTest {
    
    @TestSetup private static void testSetup() {
        Property__c testProperty = new Property__c();
        List<Account> accountList = new List<Account>();
        Account accountRecord = new Account();
        PriceBook2 pb = new PriceBook2 ();
        Product2 productBaseRentGross = new Product2();
        PricebookEntry pricebookEntryBaseRentGross = new PricebookEntry();
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Opportunity> opportunityList = new List<Opportunity>();
        Opportunity opportunityRecord = new Opportunity();
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        OpportunityLineItem OpportunityLineItemRecord = new OpportunityLineItem ();
        Integer loopInt = 0;
        Product2 productRecord;
        
        //CREATE PRODUCT
        
        productRecord = TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, Constants.RENT);
        insert productRecord;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        //CREATE PROPERTY
        testProperty = TestDataFactory.createPropertyRecord();
        testProperty.PriceBook__c = pricebookId;
        database.insert(testProperty);
        
        //CREATE ACCOUNT
        for(Integer counter = 0; counter < 5; counter++) {
            accountRecord = TestDataFactory.createAccount(counter, testProperty.Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId());
            accountRecord.BillingStreet = 'Gorge Street';
            accountRecord.BillingCity = 'Sydney';
            accountRecord.BillingCountry = 'Australia';
            accountRecord.BillingPostalCode = '2000';
            accountRecord.BillingState = 'Victoria';
            accountList.add(accountRecord);
        }
        database.insert(accountList);
        accountList = [SELECT Id, Name, Property__c FROM Account LIMIT 5];
        Contact contactRecord = TestDataFactory.createContact(CONSTANTS.TEST_FNAME, accountList[0]);
        insert contactRecord;
        //CREATE Products
        productBaseRentGross = TestDataFactory.createProduct(CONSTANTS.PRODUCT_BASE_RENT_GROSS, CONSTANTS.PRODUCT_FAMILY_RENT);
        database.insert(productBaseRentGross);
        productBaseRentGross = [SELECT Id FROM Product2 LIMIT 1];
        
        //CREATE PricebookEntry
        pricebookEntryBaseRentGross = TestDataFactory.createStandardPriceBookEntry(1, productBaseRentGross)[0];
        database.insert(pricebookEntryBaseRentGross);
        pricebookEntryBaseRentGross = [SELECT Id, Pricebook2Id FROM PricebookEntry LIMIT 1];
        //CREATE Opportunity
        opportunityList = TestDataFactory.createOpportunity(1, accountList[0]);
        for(Opportunity opp : opportunityList){
            opp.StageName = 'Register Lease';
            opp.AnnualMinimumRent__c = 400.00;
            opp.PercentageRentIncluded__c = false;
            opp.PromoLevyIncluded__c = 'No';
            opp.TechByPassOnClone__c = true;
        }
        insert opportunityList;
        
        List<Opportunity> oppList = TestDataFactory.createOpportunity(1, accountList[0]);
        for(Opportunity opp : oppList){
            opp.StageName = 'Issue Lease';
            opp.AnnualMinimumRent__c = 400.00;
            opp.PercentageRentIncluded__c = false;
            opp.PromoLevyIncluded__c = 'No';
            opp.TechByPassOnClone__c = true;
        }
        insert oppList;        
        
        //CREATE OpportunityLineItem
        for(Opportunity opp : opportunityList) {
            
            opportunityLineItemRecord = TestDataFactory.createOpportunityLineItem(5, opp, productBaseRentGross, pricebookEntryBaseRentGross );
            
            opportunityLineItemList.add(opportunityLineItemRecord);
            
        }
        insert opportunityLineItemList;
        
        
        List<Task> taskList = new List<Task>();
        //for(Opportunity opp : opportunityList){
        Task t1 = TestDataFactory.createTask(opportunityList[0].id, contactRecord.id, 'Certify Lease', System.today()-15, '03 - Certify Lease');
        t1.CompletedDate__c = system.today()+30;
        taskList.add(t1);
        Task t2 = TestDataFactory.createTask(opportunityList[0].id, contactRecord.id, 'Receive Certified Lease', System.today()-15, '19 - Receive Certified Lease');
        t2.CompletedDate__c = system.today()+30;
        taskList.add(t2);
        Task t3 = TestDataFactory.createTask(opportunityList[0].id, contactRecord.id, 'Register Lease', System.today()-15, '17 - Register Lease');
        t3.CompletedDate__c = system.today()+30;
        taskList.add(t3);
        Task t4 = TestDataFactory.createTask(opportunityList[0].id, contactRecord.id, 'RM Leasing Execute Documents', System.today()-15, '20 - RM Leasing Execute Documents');
        t4.CompletedDate__c = system.today()+30;
        taskList.add(t4);
        Task t5 = TestDataFactory.createTask(opportunityList[0].id, contactRecord.id, 'RM Retail Admin Execute Documents', System.today()-15, '28 - RM Retail Admin Execute Documents');
        t5.CompletedDate__c = system.today()+30;
        taskList.add(t5);
        Task t6 = TestDataFactory.createTask(opportunityList[0].id, contactRecord.id, 'Send Documents to JV for Execution', System.today()-15, '24 - Send Documents to JV for Execution');
        t6.CompletedDate__c = system.today()+30;
        taskList.add(t6);
        // }
        
        
        Task t11 = TestDataFactory.createTask(oppList[0].id, contactRecord.id, 'Generate Acceptance (w/ Modifications)', System.today()-15, '07 - Generate Acceptance (w/ Modifications)');
        t11.CompletedDate__c = system.today()+30;
        taskList.add(t11);
        Task t22 = TestDataFactory.createTask(oppList[0].id, contactRecord.id, 'Send Acceptance (w/ Modifications)', System.today()-15, '40 - Send Acceptance (w/ Modifications)');
        t22.CompletedDate__c = system.today()+30;
        taskList.add(t22);
        Task t33 = TestDataFactory.createTask(oppList[0].id, contactRecord.id, 'Instruct Solicitor', System.today()-15, '39 - Instruct Solicitor');
        t33.CompletedDate__c = system.today()+30;
        taskList.add(t33);
        Task t44 = TestDataFactory.createTask(oppList[0].id, contactRecord.id, 'Issue Lease Documents', System.today()-15, '13 - Issue Lease Documents');
        t44.CompletedDate__c = system.today()+30;
        insert taskList;
        
        Task t = [Select Id, ActivityDuration__c, Status,CompletedDate__c, CreatedDate From Task Where Id =: taskList[1].Id LIMIT 1];
        system.debug('Tasklist: '+t);
    }
    
    
    @isTest
    public static void batchTest(){
        
        Test.startTest();
        UpdateOpptyTargetBreached bat = new UpdateOpptyTargetBreached();
        Database.executeBatch(bat); 
        Test.stopTest();
        
        Opportunity opp1 = [SELECT Id, Name, Target_Breached__c FROM Opportunity WHERE StageName = 'Register Lease' LIMIT 1];
        System.assertEquals('Documents Execution', opp1.Target_Breached__c);
        Opportunity opp2 = [SELECT Id, Name, Target_Breached__c FROM Opportunity WHERE StageName = 'Issue Lease' LIMIT 1];
        System.assertEquals('Acceptance to Issue Lease', opp2.Target_Breached__c);
    }
}