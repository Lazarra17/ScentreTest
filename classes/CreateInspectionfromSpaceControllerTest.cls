/*
*       author: Clark Marie Garde
*       created date: June 5, 2018
*       description: Test class for CreateInspectionfromSpaceController
*
*/

@isTest
public class CreateInspectionfromSpaceControllerTest {
    
    @TestSetup private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Property__c> propertyList = new List<Property__c>();
        Property__c propertyRecord = new Property__c();
        Account account = new Account();
        List<Space__c> spaceList= new List<Space__c>();
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
        database.insert(contrList);
        system.debug('contracttt' + contrList);
        contrRecord = [SELECT Id, Name, Account__c FROM Contract__c limit 1];
        
        //CREATE Space
        spaceList = TestDataFactory.createSpace(20, account, propertyList[0], contrRecord[0]);
        Database.insert(spaceList);

    }
    
    public static testMethod void getSpaceDetails() {
        Space__c space = [SELECT ID FROM Space__c LIMIT 1];
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        Account account = [SELECT Id FROM Account LIMIT 1];
        //Create Users
        List<User> userList = new List<User>();
        userList.add(TestDataFactory.createUniqueTestUser('Bruce', 'Wayne', profileRec.Id));
        database.insert(userList);
        CreateInspectionfromSpaceController.Response response = new CreateInspectionfromSpaceController.Response();
        //Create Account Team
        List<AccountTeamMember> accountTeamList = new List<AccountTeamMember>();
        accountTeamList.add(TestDataFactory.createAccountTeamMember(account.Id, userList[0].Id));
        database.insert(accountTeamList);
        Test.startTest();
        response = CreateInspectionfromSpaceController.getspacedetails(space.ID);
        Test.stopTest();
        
        System.assertEquals('Success', response.status); 
    }
    
    public static testMethod void getSpaceDetails2() {
        Space__c space = [SELECT ID, Property__c FROM Space__c LIMIT 1];
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        //Create Users
        List<User> userList = new List<User>();
        userList.add(TestDataFactory.createUniqueTestUser('Bruce', 'Wayne', profileRec.Id));
        database.insert(userList);
        //Create Property Team
        Map<String, Schema.RecordTypeInfo> propTeamRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.PROPERTY_TEAM_API);
        List<PropertyTeam__c> propertyTeamList = new List<PropertyTeam__c>();
        propertyTeamList.add(TestDataFactory.createPropertyTeam(space.Property__c, Constants.TEAM_ROLE_RDM, userList[0].Id, propTeamRecordTypeMapByName.get(Constants.PRT_INTERNAL_TEAM_MEMBER).getRecordTypeId()));
        database.insert(propertyTeamList);
        CreateInspectionfromSpaceController.Response response = new CreateInspectionfromSpaceController.Response();
        
        Test.startTest();
        response = CreateInspectionfromSpaceController.getspacedetails(space.ID);
        Test.stopTest();
        
        System.assertEquals('Success', response.status); 
    }
    
    public static testMethod void isIRCaseRaisedEarlierTest(){
        Space__c space = [SELECT ID, Property__c FROM Space__c LIMIT 1];
        
        Test.startTest();
        	Boolean flag = CreateInspectionfromSpaceController.isIRCaseRaisedEarlier(space.Id);
        Test.stopTest();
        
        System.assertEquals(flag, false);
    }
}