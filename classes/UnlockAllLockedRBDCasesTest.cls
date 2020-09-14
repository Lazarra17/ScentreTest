@isTest
public class UnlockAllLockedRBDCasesTest {
    @TestSetup private static void testSetup(){
               
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
        
        Id recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Retail Design Billing').getRecordTypeId();
        
        List<Case> lstCase = new List<Case>();
        Case RDBCase = new Case();
        RDBCase.Subject = Constants.CASE_SUBJECT_RDB_IR;
        RDBCase.Space__c = spaceList[0].Id;
        RDBCase.RecordTypeId = recTypeId;
        RDBCase.Type = Constants.RETAIL_DESIGN_BILLING;
        RDBCase.Status = Constants.Completed;
        RDBCase.InspectionType__c = Constants.DSSO;
        lstCase.add(RDBCase);
        insert lstCase;
        Approval.lock(lstCase);
        //update lstCase;
        
    }
    
    public static testMethod void callBatchUnlockAllLockedRBDCases(){
        Test.startTest();
        UnlockAllLockedRBDCases batchRDB = new UnlockAllLockedRBDCases();
        Database.executeBatch(batchRDB, 5);
        Test.stopTest();
    }

}