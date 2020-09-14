/*
* @author:              Ashwini Makhija
* @description:         Test class for RentalAsstDateManagementBatch
*/
@isTest
public class RentalAsstDateManagementBatchTest {

    @TestSetup 
    private static void testSetup(){
        String periodVal;
        List<String> RentalAsstPeriodValuesList= new List<String>();
        Schema.DescribeFieldResult fieldResult = case.Rental_Assistance_Period__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            RentalAsstPeriodValuesList.add(pickListVal.getLabel());
        } 
        
        List<Covid_Case_Rental_Assistan__mdt> covidRentalAsstMetadataList = [SELECT MasterLabel, Start_Date__c, End_Date__c, Batch_Update__c 
                                                                             FROM Covid_Case_Rental_Assistan__mdt
                                                                             WHERE Batch_Update__c = TRUE LIMIT 1];
        
        for(String str : RentalAsstPeriodValuesList){
            if(str == covidRentalAsstMetadataList[0].MasterLabel){
                periodVal = covidRentalAsstMetadataList[0].MasterLabel;
            }
        }
        
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> caseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.OBJECT_CASE);
        Account testAccount = New Account();
        Property__c testProperty = New Property__c();
        List<Space__c> testSpace = New List<Space__c>();
        List<Contract__c> contrList = new List<Contract__c>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Case> caseList = new List<Case>();
        
        //CREATE PROPERTY
        testProperty = TestDataFactory.createPropertyRecord();
        database.insert(testProperty);
        
        //CREATE ACCOUNT
        testAccount = TestDataFactory.createAccount(1, testProperty.Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId());
        database.insert(testAccount);
        
        //CREATE SPACE
        testSpace = TestDataFactory.createSpace(1, testProperty);
        testSpace[0].type__c = '1';
        database.insert(testSpace);
        
        //CREATE CONTRACT
        contrList = TestDataFactory.createContract(1, testAccount);
        contrList[0].space__c = testSpace[0].id;
        database.insert(contrList);
        
        //CREATE OPPORTUNITY
        opportunityList = TestDataFactory.createOpportunity(1, testAccount, testProperty, testSpace[0]);
        database.insert(opportunityList);
        
        //CREATE CASES FOR BATCH TESTING
        for(Integer i = 0; i < 50; i++){
            Case newCase = TestDataFactory.CreateCase(testAccount, caseRecordTypeMapByName.get(Constants.LVI_COVID19).getRecordTypeId(), contrList[0].Id);
            newCase.Status = Constants.CASE_STATUS_PENDING_APPROVAL;
            newCase.Space__c = testSpace[0].Id;
            newCase.Contract__c = contrList[0].Id;
            newCase.Opportunity__c = opportunityList[0].Id;
            newCase.AccountId = testAccount.Id;
            newCase.JDESentStatus__c = Constants.OPPO_JDE_STATUS_READY;
            newCase.TechHasChildCase__c = true;
            newCase.SubType__c = Constants.CASE_SUBTYPE_COVID_RENT_REQUEST;
            newCase.Type = 'LV18 - Miscellaneous';
            newCase.Rental_Assistance_Period__c = periodVal;
            newCase.Rental_Assistance_Start_Date__c = system.today();
            newCase.Rental_Assistance_End_Date__c = system.today() + 20;
            caseList.add(newCase);
        }
        database.insert(caseList);
    }
    
    @isTest
    public static void RentalDatesBatchUpdateTest(){
        
        Test.startTest();
            RentalAsstDateManagementBatch testBatch = New RentalAsstDateManagementBatch();
            database.executeBatch(testBatch, 100);
        Test.stopTest();
    }
    
}