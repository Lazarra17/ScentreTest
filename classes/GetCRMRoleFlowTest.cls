/**
 * Author: Miguel Paguio
 * Description: Test Class for GetCRMRole
 **/

@isTest
public class GetCRMRoleFlowTest {
    @TestSetup private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Account accountRecord;
        PrecedentClause__c precedentClauseRecord;
        List<Property__c> propertyList = new List<Property__c>();
        List<Account> accountList = new List<Account>();
        List<PrecedentClause__c> precedentClauseList = new List<PrecedentClause__c>();
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        List<User> testUserList = new List<User>();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        
        testUserList.add(TestDataFactory.createUniqueTestUser('Test', 'User 1', profileRec.Id));
        testUserList.add(TestDataFactory.createUniqueTestUser('Test', 'User 2', profileRec.Id));
        
        Database.insert(testUserList); 
        
        //CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(10);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(10, pricebookList[0]);
        database.insert(propertyList);
        propertyList = [SELECT Id FROM Property__c LIMIT 1];
        
        //CREATE ACCOUNT
        accountList.addAll(TestDataFactory.createAccountBulk(100, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId()));
        accountList.addAll(TestDataFactory.createAccountBulk(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId()));
        database.insert(accountList);
        //CREATE PRECEDENT CLAUSE
        accountRecord = [SELECT Id, Name FROM Account WHERE ParentId = null AND RecordTypeId = :accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId() LIMIT 1];
                
        List<Contract__c> contrList = new List<Contract__c>();
        List<Space__c> spaceLst = TestDataFactory.createSpace(1, propertyList[0]);
        spaceLst[0].type__c = '1';
        database.insert(spaceLst);
        
        contrList = TestDataFactory.createContract(1, accountRecord);
        contrList[0].space__c = spaceLst[0].id;
        database.insert(contrList);
    
        Id internalTeamRecTypeId;
        List<PropertyTeam__c> propertyTeamList = new List<PropertyTeam__c>();
        Map<String,Schema.RecordTypeInfo> propertyTeamRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName('PropertyTeam__c');
        
        internalTeamRecTypeId = propertyTeamRecordTypeMap.get('PRT - Internal Team Member').getRecordTypeId();
        PropertyTeam__c propteam = TestDataFactory.createPropertyTeam(propertyList[0].id, constants.TEAM_ROLE_REGMGR, testUserList[0].Id, internalTeamRecTypeId);
        database.insert(propteam);
         
        List<Space__c> spaceList = TestDataFactory.createSpace(20, accountRecord, propertyList[0], contrList[0]);
        Database.insert(spaceList);     
        
    }

    public static testMethod void testgetRoleId() {
       
        List<Contract__c> contrlst = [select id from contract__c limit 1];
        List<Id> contrIdLst = new List<Id>();
        contrIdLst.add(contrlst[0].id);
      
        List<String> testStr = GetCRMRole.getRevAssuRoleId(contrIdLst);
    }
}