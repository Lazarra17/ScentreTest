/*
*       author: Clark Marie Garde
*       created date: June 8, 2018
*       description: Test class for CreateInspectionBatch
*
*/
@isTest
public class CreateInspectionBatchTest {
    
    @TestSetup private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Property__c> propertyList = new List<Property__c>();
        Property__c propertyRecord = new Property__c();
        Account account = new Account();
        List<Space__c> spaceList= new List<Space__c>();
        Space__c spaceRecord = new Space__c();
        Account accountRecord = new Account();
        List<Contract__c> contrList= new List<Contract__c>();
        List<Contract__c> contrRecord = new List<Contract__c>();
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        
        //CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(10);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(10, pricebookList[0]);
        database.insert(propertyList);
        propertyRecord = [SELECT Id FROM Property__c LIMIT 1];
        
        //CREATE Account
        account = TestDataFactory.createAccount(20, propertyRecord.id, accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId());
        database.insert(account);
        accountRecord = [SELECT Id, Name FROM Account];
        
        //CREATE Contract
        contrList = TestDataFactory.createContract(20, account);
        
        for(Contract__c con : contrList){
          con.LeaseEndDate__c = Date.today().addMonths(9);
        }
        database.insert(contrList);
        system.debug('contracttt' + contrList); 
        contrRecord = [SELECT Id, Name, Account__c FROM Contract__c limit 1];
        
        //CREATE Space
        spaceList = TestDataFactory.createSpace(20, account, propertyList[0], contrRecord[0]);
        Database.insert(spaceList);
        spaceRecord = [SELECT Id, Name,CreateInspectionReport__c FROM Space__c LIMIT 1];
        
    }
    
    public static testMethod void getSpaceDetails() {
        Space__c spaceRec = [SELECT Type__c,CurrentLease__r.LeaseStatus__c,CurrentLeaseExpiryDate__c,Id,CurrentLease__c,CreateInspectionReport__c from Space__c WHERE CurrentLease__c!=null LIMIT 1];
        spacerec.Type__c = '3';
        TriggerHandler.bypass('SpaceTriggerHandler');
        TriggerHandler.bypass('ContractTriggerHandler');
        database.update(spacerec);
        List<Contract__c> contractList = [SELECT LeaseStatus__c,Id, Property__c, Name, Property__r.Name, Space__c, Space__r.Name,
                                            Space__r.CurrentLease__c, Account__r.Name, LeaseEndDate__c, Account__c, 
                                            Account__r.ParentId, Opportunity__c
                                          FROM Contract__c 
                                          WHERE Id =: spaceRec.CurrentLease__c AND AutoInspectionReportCreated__c=false 
                                          LIMIT 1];

        List<Case> caseToCreate = new List<Case>();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        database.insert(testUser);
        system.runAs(testUser){
            Test.startTest();
            caseToCreate = CaseBL.CreateInspectionforContract(contractList);
            database.insert(caseToCreate);      
            CreateInspectionBatch inspectionBatch = new CreateInspectionBatch(); 
            Id batchId = Database.executeBatch(inspectionBatch);
            
            contractList[0].LeaseEndDate__c = contractList[0].LeaseEndDate__c.addDays(1);
            database.update(contractList);
            batchId = Database.executeBatch(inspectionBatch);
            
            contractList[0].LeaseEndDate__c = contractList[0].LeaseEndDate__c.addDays(1);
            database.update(contractList);
            batchId = Database.executeBatch(inspectionBatch);
            
            Test.stopTest();
        }
        
        System.assertEquals(true, caseToCreate <> null);
        
    }
}