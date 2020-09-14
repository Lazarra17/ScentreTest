@isTest
public class checkReconfiguredSpaceTest {
    @TestSetup private static void testSetup(){
        Map<String, Schema.RecordTypeInfo> spaceRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName(Constants.SPACE);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Account> accountList = new List<Account>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Contract__c> contractList = new List<Contract__c>();
        
        List<Pricebook2> priceBookList = TestDataFactory.createPricebook(1);
        Database.insert(priceBookList);
        Pricebook2 priceBookRec = [SELECT Id, CurrencyIsoCode FROM Pricebook2 LIMIT 1];
        
        
        Property__c property = TestDataFactory.createProperty(1, priceBookRec)[0];
        Database.insert(property);
        Property__c propRec = [SELECT Id, Name FROM Property__c LIMIT 1];
        //CREATE ACCOUNT
        accountList.addAll(TestDataFactory.createAccountBulk(10, property.Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(accountList);
                
        List<Space__c> spaceList = TestDataFactory.createSpace(10, property);
        for(Space__c space : spaceList){
            space.RentableArea__c = 40;
            space.DevelopmentType__c = null;
            
            space.RecordTypeId = spaceRecordTypeMap.get(Constants.PROSPECTIVE_SPACE).getRecordTypeId();
        }
        Database.insert(spaceList);
        List<Space__c> newSpaceList = [SELECT Id, RentableArea__c, DevelopmentType__c, RecordTypeId, Type__c, Property__c FROM Space__c LIMIT 10];
        
        //CREATE OPPORTUNITY
        accountList = [SELECT Id, Property__c FROM Account LIMIT 10];
        opportunityList = TestDataFactory.createOpportunity(accountList);
        for(Integer i = 0; i < opportunityList.size(); i++){
            opportunityList[i].Space__c = spaceList[i].Id;
        }        
        database.insert(opportunityList);
        
        Account accountRecord = [SELECT Id, Name FROM Account WHERE ParentId = null AND RecordTypeId = :accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId() LIMIT 1];
        
        contractList = TestDataFactory.createContract(10, accountRecord);
        for(Integer i = 0; i<contractList.size();i++){
            contractList[i].space__c = newSpaceList[i].id;
            contractList[i].ActualVacateDate__c = null;
            contractList[i].Property__c = propRec.Id;
            contractList[i].LeaseStartDate__c = date.today() - 5;
        }
        database.insert(contractList);
        contractList = [SELECT Id, LeaseStartDate__c, ActualVacateDate__c FROM Contract__c];
        
        for(Integer i = 0; i<newSpaceList.size();i++){
            
            newSpaceList[i].CurrentRetailer__c = accountList[i].Id;
            
        }
        database.update(newSpaceList);
        List<SpaceGroup__c> spaceGroupList = new List<SpaceGroup__c>();
        
        spaceGroupList.add(TestDataFactory.createSpaceGroup(newSpaceList[0], newSpaceList[1])); 
        Database.insert(spaceGroupList);
        
        
    }
    

    
    public static testMethod void testcheckifReconfiguredSpace(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        List<Space__c> spaceLst = [SELECT Id from Space__c Limit 1];
        List<String> errMsg = new List<String>();
        List<Id> spaceIdLst = new List<Id>{spaceLst[0].Id};
        System.runAs(testUser){
            Test.startTest();
            errMsg.addall(checkReconfiguredSpace.checkifReconfiguredSpace(spaceIdLst));
            Test.stopTest();
        }
        
        System.assert(errMsg.size()>0);
        
    }
}