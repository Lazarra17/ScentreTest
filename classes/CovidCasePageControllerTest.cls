@isTest
public class CovidCasePageControllerTest {

    @TestSetup 
    private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Account accountRecord;
        PrecedentClause__c precedentClauseRecord;
        List<Property__c> propertyList = new List<Property__c>();
        List<Account> accountList = new List<Account>();
        List<Account> accountList1 = new List<Account>();
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        List<PrecedentClause__c> precedentClauseList = new List<PrecedentClause__c>();
        List<User> testUserList = new List<User>();
        List<Account> parentAccList = new List<Account>();
        
        Account account = new Account();
        
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        
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
        
        //CREATE PARENT ACCOUNT
        parentAccList.addAll(TestDataFactory.createAccountBulk(1, null, accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId()));
        database.insert(parentAccList);
        parentAccList = [SELECT Id, Property__c FROM Account LIMIT 1];
        
        //CREATE ACCOUNT
        for(Integer i = 0; i < 5; i++){
            account = TestDataFactory.createAccountwithParent(i, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), parentAccList.get(0).Id);
            account.is_National_Account__c = TRUE;
            
            accountList.add(account);
        }
        
        for(Integer i = 0; i < 5; i++){
            account = TestDataFactory.createAccountwithParent(i, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), parentAccList.get(0).Id);
            account.is_National_Account__c = FALSE;
            
            accountList.add(account);
        }
        database.insert(accountList);
        accountList = [SELECT Id, Name FROM Account LIMIT 100];
        
        //CREATE ACCOUNTTEAMMEMBER
        List<AccountTeamMember> AccTeamMemberList = new List<AccountTeamMember>();
        AccountTeamMember AccTeamMemberRec = TestDataFactory.createAccountTeamMember(parentAccList[0].id, testUserList[0].id);
        AccTeamMemberList.add(AccTeamMemberRec);
        database.insert(AccTeamMemberList);
        
        List<Contract__c> contrList = new List<Contract__c>();
        List<Space__c> spaceLst = TestDataFactory.createSpace(1, propertyList[0]);
        spaceLst[0].type__c = '1';
        database.insert(spaceLst);
        
        contrList = TestDataFactory.createContract(1, account);
        contrList[0].space__c = spaceLst[0].id;
        database.insert(contrList);
    
        Id internalTeamRecTypeId;
        List<PropertyTeam__c> propertyTeamList = new List<PropertyTeam__c>();
        Map<String,Schema.RecordTypeInfo> propertyTeamRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName('PropertyTeam__c');
        
        internalTeamRecTypeId = propertyTeamRecordTypeMap.get('PRT - Internal Team Member').getRecordTypeId();
        PropertyTeam__c propteam = TestDataFactory.createPropertyTeam(propertyList[0].id, constants.TEAM_ROLE_GMLEASING,  testUserList[0].Id, internalTeamRecTypeId);
        database.insert(propteam);
         
        List<Space__c> spaceList = TestDataFactory.createSpace(20, account, propertyList[0], contrList[0]);
        Database.insert(spaceList);
        
        //CREATE PROPERTYTEAM
        Map<String, Schema.RecordTypeInfo> PropertyTeamRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.PROPERTYTEAM);
        List<PropertyTeam__c> lstPropertyTeam = new List<PropertyTeam__c>();
        string teamrole = Constants.TEAM_ROLE_RDM;
        PropertyTeam__c PropertyTeamRec = TestDataFactory.createPropertyTeam(propertyList[0].id, teamrole, testUserList[0].id, PropertyTeamRecordTypeMapByName.get(CONSTANTS.PRT_INTERNAL_TEAM_MEMBER).getRecordTypeId());
        lstPropertyTeam.add(PropertyTeamRec);
        
        Database.insert(lstPropertyTeam);
        
        
        //CREATE Case
        accountList = [SELECT Id, ParentId, Property__c FROM Account WHERE ParentId != null AND Is_National_Account__c = TRUE];
        accountList1 = [SELECT Id, ParentId, Property__c FROM Account WHERE ParentId != null AND Is_National_Account__c = FALSE];
        
        List<Opportunity> opportunityList = TestDataFactory.createOpportunity(accountList);
        System.debug('Opportunity List' + opportunityList);
        database.insert(opportunityList);
        opportunityList = [SELECT Id FROM Opportunity LIMIT 200];
        Map<String, Schema.RecordTypeInfo> CaseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.OBJECT_CASE);

        
        Case CaseRec11 = TestDataFactory.createCase(contrList[0], spaceLst[0], CaseRecordTypeMapByName.get(CONSTANTS.CASE_RECORDTYPE_INSPECTIONREPORT).getRecordTypeId());
        CaseRec11.AccountId = accountList[0].Id;
        CaseRec11.Opportunity__c = opportunityList[0].Id;
        insert CaseRec11;
        
        List<Case> lstCase = new List<Case>();
        Case CaseRec1 = TestDataFactory.createCase(contrList[0], spaceLst[0], CaseRecordTypeMapByName.get(CONSTANTS.LVI_COVID19).getRecordTypeId());
        CaseRec1.AccountId = accountList[0].Id;
        CaseRec1.Opportunity__c = opportunityList[0].Id;
        CaseRec1.ParentId = CaseRec11.Id;
        CaseRec1.SubType__c = Constants.CASE_SUBTYPE_COVID_RENT_REQUEST;
       	CaseRec1.Type = 'LV18 - Miscellaneous';
        lstCase.add(CaseRec1);
        
        Case CaseRec2 = TestDataFactory.createCase(contrList[0], spaceLst[0], CaseRecordTypeMapByName.get(CONSTANTS.LVI_COVID19).getRecordTypeId());
        CaseRec2.AccountId = accountList1[0].Id;
        CaseRec2.Opportunity__c = opportunityList[0].Id;
        CaseRec2.ParentId = CaseRec11.Id;
        CaseRec2.SubType__c = Constants.CASE_SUBTYPE_COVID_RENT_REQUEST;
       	CaseRec2.Type = 'LV18 - Miscellaneous';
        lstCase.add(CaseRec2);
        
        
        Database.insert(lstCase);
    }
    
    @isTest
    static void getFieldsToShow_Test(){
    	List<Case> caseList = [SELECT Id, Status FROM Case WHERE Account.Is_National_Account__c = TRUE];
        CovidCasePageController.getFieldsToShow(caseList[0].Id);
    }
    
    @isTest
    static void getFieldsToShowPropTeam_Test(){
    	List<Case> caseList = [SELECT Id, Status FROM Case  WHERE Account.Is_National_Account__c = FALSE];
        CovidCasePageController.getFieldsToShow(caseList[0].Id);
    }
}