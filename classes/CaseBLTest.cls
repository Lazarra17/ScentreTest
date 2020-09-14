/*
* @author:              Dave Camongol
* @description:         Test class for CaseBL
*/
@isTest
public class CaseBLTest {
    
    @TestSetup private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Account accountRecord;
        PrecedentClause__c precedentClauseRecord;
        List<Property__c> propertyList = new List<Property__c>();
        List<Account> accountList = new List<Account>();
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        List<PrecedentClause__c> precedentClauseList = new List<PrecedentClause__c>();
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
        
        //CREATE ACCOUNTTEAMMEMBER
        List<AccountTeamMember> AccTeamMemberList = new List<AccountTeamMember>();
        AccountTeamMember AccTeamMemberRec = TestDataFactory.createAccountTeamMember(accountList[0].id, testUserList[0].id);
        AccTeamMemberList.add(AccTeamMemberRec);
        database.insert(AccTeamMemberList);        
        
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
        PropertyTeam__c propteam = TestDataFactory.createPropertyTeam(propertyList[0].id, constants.TEAM_ROLE_GMLEASING,  testUserList[0].Id, internalTeamRecTypeId);
        database.insert(propteam);
        
        List<Space__c> spaceList = TestDataFactory.createSpace(20, accountRecord, propertyList[0], contrList[0]);
        Database.insert(spaceList);
        
        //CREATE PROPERTYTEAM
        Map<String, Schema.RecordTypeInfo> PropertyTeamRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.PROPERTYTEAM);
        List<PropertyTeam__c> lstPropertyTeam = new List<PropertyTeam__c>();
        string teamrole = Constants.TEAM_ROLE_RDM;
        PropertyTeam__c PropertyTeamRec = TestDataFactory.createPropertyTeam(propertyList[0].id, teamrole, testUserList[0].id, PropertyTeamRecordTypeMapByName.get(CONSTANTS.PRT_INTERNAL_TEAM_MEMBER).getRecordTypeId());
        //system.debug('Active '+ PropertyTeamRec.Active__c);
        lstPropertyTeam.add(PropertyTeamRec);
        database.insert(lstPropertyTeam);
        //system.debug('Active '+ lstPropertyTeam[0].Active__c);
        //system.debug('EndDate '+ lstPropertyTeam[0].EndDate__c);
        //system.debug('StartDate '+ lstPropertyTeam[0].StartDate__c);
        
        //CREATE Case
        Map<String, Schema.RecordTypeInfo> CaseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.OBJECT_CASE);
        
        Case CaseRec11 = TestDataFactory.createCase(contrList[0], spaceLst[0], CaseRecordTypeMapByName.get(CONSTANTS.CASE_RECORDTYPE_INSPECTIONREPORT).getRecordTypeId());
        CaseRec11.AccountId = accountList[0].Id;
        //CaseRec11.Opportunity__c = opportunityList[0].Id;
        //lstCase.add(CaseRec1);
        insert CaseRec11;
        
        
        List<Case> lstCase = new List<Case>();
        Case CaseRec1 = TestDataFactory.createCase(contrList[0], spaceLst[0], CaseRecordTypeMapByName.get(CONSTANTS.CASE_RECORDTYPE_INSPECTIONREPORT).getRecordTypeId());
        CaseRec1.ParentId = CaseRec11.Id;
        lstCase.add(CaseRec1);
        
        Case CaseRec2 = TestDataFactory.createCase(contrList[0], spaceLst[0], CaseRecordTypeMapByName.get(CONSTANTS.RETAIL_DESIGN_BILLING).getRecordTypeId());
        CaseRec2.ParentId = CaseRec11.Id;
        lstCase.add(CaseRec2);
        
        Case CaseRec3 = TestDataFactory.createCase(contrList[0], spaceLst[0], CaseRecordTypeMapByName.get(CONSTANTS.STATEMENT_OF_COMPLETION).getRecordTypeId());
        CaseRec3.ParentId = CaseRec11.Id;
        lstCase.add(CaseRec3);
        database.insert(lstCase);        
    }
    
    public static testMethod void testgetRoleId() {
        List<Contract__c> contrlst = [select id from contract__c limit 1];
        List<Id> contrIdLst = new List<Id>();
        contrIdLst.add(contrlst[0].id);
        CaseBL.getRoleId(contrIdLst,constants.TEAM_ROLE_ACCREVPAYABLES);
        
    }  
    public static testMethod void getSpaceDetails() {
        Space__c spaceRec = [SELECT Id,CurrentLease__c from Space__c where CurrentLease__c != null limit 1];
        List<Contract__c> contractList = [SELECT Id,Property__c, Name, Property__r.Name, Space__c, Space__r.Name,
                                          Space__r.CurrentLease__c, Account__r.Name, LeaseEndDate__c, Account__c, 
                                          Account__r.ParentId, Opportunity__c 
                                          FROM Contract__c 
                                          WHERE Id =: spaceRec.CurrentLease__c limit 1];
        List<Case> CaseList = [Select Id, Contract__c, Space__c, Status, Description, ReviewDate__c, EffectiveDate__c FROM Case limit 3];
        
        List<Id> contractIds = new List<Id>();
        for (Contract__c contract: contractList){
            contractIds.add(contract.id);
        }
        for (Case caserec: CaseList){
            contractIds.add(caserec.id);
        }
        
        List<Case> caseToCreate = new List<Case>();
        List<CaseEvent__e> caseEvents = new List<CaseEvent__e>();
        
        //List Payloads
        List<string> lstPayloads = new List<string>();
        lstPayloads=TestDataFactory.lstPayload(5);
        
        Test.startTest();
        caseToCreate = CaseBL.CreateInspectionforContract(contractList);
        caseEvents = CaseBL.generateCaseEvents(lstPayloads);
        CaseBL.retailDesignBillingCase(contractIds);
        CreateInspectionBatch inspectionBatch = new CreateInspectionBatch(); 
        Id batchId = Database.executeBatch(inspectionBatch);
        Test.stopTest();
        
        System.assertEquals(true, caseToCreate <> null);
        
    }
    public static testMethod void testGetContractfromOpportunity(){
        List<Property__c> propertyList = [SELECT Id FROM Property__c LIMIT 1];
        List<Space__c> spaceList = [SELECT Id FROM Space__c LIMIT 200];
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Account> accLst = new List<Account>();
        
        accLst.addAll(TestDataFactory.createAccountBulk(1, propertyList[0].Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        accLst[0].TradingName__c = 'abaccc';
        database.insert(accLst);
        
        accLst = [Select Name,id,Property__c from Account where recordtypeid =: accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId() limit 1];
        List<Opportunity> opportunityList = TestDataFactory.createOpportunity(1, accLst[0], propertyList, spaceList);
        database.insert(opportunityList);
        
        Opportunity opp = [Select Id from Opportunity limit 1];
        List<Contract__c> contrList = TestDataFactory.createContract(1, accLst[0]);
        
        for(Contract__c con : contrList){
            con.LeaseEndDate__c = Date.today().addMonths(9);
            con.Opportunity__c = opp.id;
        }
        
        database.insert(contrList);
        
        Map<Id, Opportunity> OppMap = new Map<Id, Opportunity>();
        oppMap.put(opp.id,opp);
        Test.startTest();
        Id ContractId = CaseBL.GetContractfromOpportunity(oppMap,opp.id);
        Test.stopTest();
        system.assert(true, ContractId <> null);
    }
    public static testMethod void testGenerateCaseEventsByMap(){
        List<Case> CaseList = [Select Recordtypeid, Id, Contract__c, Space__c, Status, Description, ReviewDate__c, EffectiveDate__c FROM Case limit 3];
        Map<Id, String> idStringMap = new Map<Id, String>();
        idStringMap.put(caseList[0].id, 'TestPayload');
        Map<Id,Id> recordidToRTId = new Map<Id, Id>();
        recordidToRTId.put(CaseList[0].id, CaseList[0].Recordtypeid);
        CaseBL.generateCaseEventsByMap(idStringMap, recordidToRTId);
    }
    
    
}