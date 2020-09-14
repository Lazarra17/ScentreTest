@isTest
public class SpacePreviousAndCurrentUpdateBatchTest {
    @TestSetup 
    private static void testSetup() {
        List<Contract__c> contractList = new List<Contract__c>();
        List<Opportunity> oppList = new List<Opportunity>();
        List<Space__c> spaceList= new List<Space__c>();
        List<Property__c> propertyList = new List<Property__c>();
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        
        //CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(10);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(10, pricebookList[0]);
        database.insert(propertyList);
        
        //CREATE ACCOUNT
        Account account = new Account();
        account = TestDataFactory.createAccount(10);
        account.Property__c = propertyList[0].Id;
        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(Constants.PROPERTY_BASED_APINAME).getRecordTypeId();
        database.insert(account);
        
        //CREATE SPACE
        spaceList = TestDataFactory.createSpace(10, propertyList[0]);
        database.insert(spaceList);
        
        //CREATE OPPORTUNITY
        oppList = TestDataFactory.createOpportunity(1, account.Id);
        oppList[0].Property__c = propertyList[0].Id;
        oppList[0].Space__c = spaceList[0].Id;
        oppList[0].TradeFlag__c = true;
        oppList[0].ActualShopOpenedDate__c = System.today() - 4;
        oppList[0].TechTradeFlagChangedDate__c = System.today();
        insert oppList;
        
        //CREATE OPPORTUNITY
        /*oppList = TestDataFactory.createOpportunity(1, account.Id);
        oppList[0].TradeFlag__c = true;
        oppList[0].TechTradeFlagChangedDate__c = System.today();
        insert oppList;*/
        
        //CREATE CONTRACT
        Integer counter = 0;
        contractList = TestDataFactory.createContract(10, account);
        for(Contract__c con : contractList){
            con.LeaseStartDate__c = Date.today();
            con.Space__c = spaceList[counter++].Id;
            con.TechStatusChanged__c = true;
            con.LeaseStatus__c = 'A';
            con.Opportunity__c =  oppList[0].Id; // ---
        }
        database.insert(contractList);
        
        spaceList[0].CurrentLease__c = contractList[2].Id;
        Database.update(spaceList);
    }
    
    @isTest
    private static void testUpdateSpace() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Space__c> spaceToUpdateList = [SELECT Id from Space__c LIMIT 1];
        List<Contract__c> contractList = [SELECT Id, Account__c, Account__r.Name, Space__c, ActualVacateDate__c FROM Contract__c];
        
        System.runAs(testUser){
            Test.startTest(); 
            //spaceToUpdateList = SpaceBL.updateCurrentAndPreviousTenant(contractList);
            SpacePreviousAndCurrentUpdateBatch spacePrevBatch = new SpacePreviousAndCurrentUpdateBatch(); 
            Id batchId = Database.executeBatch(spacePrevBatch);
            Test.stopTest();
            
            //System.assertEquals(true, spaceToUpdateList <> null);
        }
    }
    
    @isTest
    private static void testSchedulableBatch() {
        Test.StartTest();
        SpacePreviousAndCurrentUpdateBatch sh1 = new SpacePreviousAndCurrentUpdateBatch();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test SpacePreviousAndCurrentUpdateBatch Schedule', sch, sh1); 
        Test.stopTest(); 
    }
    
}