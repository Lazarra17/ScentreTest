/*
* @author:              Sidney Garcia
* @description:         Test class for PostChatterToCaseInvoc
*/
@isTest
public class PostChatterToCaseInvocTest {
    @TestSetup private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> caseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.OBJECT_CASE);
        Map<String, Schema.RecordTypeInfo> propTeamRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.PROPERTYTEAM);
         Id internalTeamRecTypeId;
        Map<String,Schema.RecordTypeInfo> propertyTeamRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName('PropertyTeam__c');
        Product2 productRecord;
        List<Property__c> propertyList = new List<Property__c>();
        List<Account> accountList = new List<Account>();
        List<Account> tempAccountList = new List<Account>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<contact> contactList = new list<contact>();
        List<case> caseList = new list<case>();
        List<User> testUserList = new List<User>();
        PropertyTeam__c propTeam = new PropertyTeam__c();
        Profile profileRec = [SELECT Id, UserLicense.Name FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        
        System.debug('profile rec ' + profileRec.UserLicense.Name);
        for(Integer i = 0; i < 20; i++){
            testUserList.add(TestDataFactory.createUniqueTestUser('Test ' + i, 'User 1 ' + i, profileRec.Id));
            testUserList[i].IsActive = true;
            
        }
        database.insert(testUserList);
        System.debug('Test User Profile ' + testUserList[0].ProfileId);
        
        //CREATE PRODUCT
        productRecord = TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, Constants.RENT);
        insert productRecord;
        
        List<Pricebook2> priceBookList = TestDataFactory.createPricebook(1);
        Database.insert(priceBookList);
        Pricebook2 priceBookRec = [SELECT Id, CurrencyIsoCode FROM Pricebook2 LIMIT 1];
        //System.debug('Pricebook rec ' + priceBookRec);
        
        Property__c property = TestDataFactory.createProperty(1)[0];
        property.PriceBook__c = priceBookRec.Id;
        Database.insert(property);
        
        //CREATE ACCOUNT
        accountList.addAll(TestDataFactory.createAccountBulk(1, property.Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(accountList);
        //System.debug('Account List ' + accountList);
        //CREATE OPPORTUNITY
        accountList = [SELECT Id, Property__c, Name FROM Account LIMIT 1];
        opportunityList = TestDataFactory.createOpportunity(accountList);
        //System.debug('Opportunity List' + opportunityList);
        database.insert(opportunityList);
        
        List<Contract__c> contrList = new List<Contract__c>();
        List<Space__c> spaceLst = TestDataFactory.createSpace(1, property);
        spaceLst[0].type__c = '1';
        spaceLst[0].BillingCategory__c = 'NA';
        database.insert(spaceLst);
        spaceLst = [SELECT Id, Type__c FROM Space__c];
        contrList = TestDataFactory.createContract(1, accountList[0]);
        contrList[0].space__c = spaceLst[0].id;
        database.insert(contrList);
        
        //CREATE ACCOUNTTEAMMEMBER
        List<AccountTeamMember> AccTeamMemberList = new List<AccountTeamMember>();
        AccountTeamMember AccTeamMemberRec = TestDataFactory.createAccountTeamMember(accountList[0].id, testUserList[0].id);
        AccTeamMemberList.add(AccTeamMemberRec);
        database.insert(AccTeamMemberList);
        
        Contract__c contractRec = [SELECT Id, Space__c, Property__c, RecordTypeId from Contract__c LIMIT 1];
        
        Id recordTypeId = caseRecordTypeMapByName.get(CONSTANTS.LEASE_AREA_VARIATION).getRecordTypeId();
        
        Set<string> CaseRecordtypeNames = new set<string>();
        CaseRecordtypeNames.add(CONSTANTS.RETAIL_DESIGN_INSTRUCTION);
        CaseRecordtypeNames.add(CONSTANTS.UPDATE_PROMOTIONAL_ALLOWANCE);
        CaseRecordtypeNames.add(CONSTANTS.MISCELLANEOUS_SERVICE);
        CaseRecordtypeNames.add(CONSTANTS.VARIANCE_TO_RENT_COMMENCEMENT);
        CaseRecordtypeNames.add(CONSTANTS.REQUEST_FOR_REFUND);
        CaseRecordtypeNames.add(CONSTANTS.CONDUCT_MARKET_REVIEW);
        CaseRecordtypeNames.add(CONSTANTS.LEASE_AREA_VARIATION);
        CaseRecordtypeNames.add(CONSTANTS.MANAGE_BANK_GUARANTEE);
        CaseRecordtypeNames.add(CONSTANTS.SURRENDER_A_LEASE);
        CaseRecordtypeNames.add(CONSTANTS.TERMINATE_A_LEASE);
        CaseRecordtypeNames.add(CONSTANTS.ASSIGN_OF_A_LEASE);
        CaseRecordtypeNames.add(CONSTANTS.TRADING_NAME_CHANGE);
        CaseRecordtypeNames.add(CONSTANTS.CREDIT_NOTE);
        CaseRecordtypeNames.add(CONSTANTS.CENTRE_TEAM);
        CaseRecordtypeNames.add(CONSTANTS.LEASING_FINANCE);
        CaseRecordtypeNames.add(CONSTANTS.MISCELLANEOUS_LEASE);
        CaseRecordtypeNames.add(CONSTANTS.ANCILLARY_TAX_INVOICE);
       
        for(String caseRecTypeName : CaseRecordtypeNames){
           case caseRec = TestDataFactory.CreateCase(accountList[0], caseRecordTypeMapByName.get(caseRecTypeName).getRecordTypeId(), contractRec.Id);
            caseRec.UnexpiredFitoutAmount__c = 28.50;
            caseRec.Space__c = contractRec.Space__c;
            if(CaseRecTypeName == CONSTANTS.MISCELLANEOUS_LEASE){ 
                caseRec.Type = CONSTANTS.CASE_TYPE_LV18MISCELLANEOUS;
                if(String.isBlank(caseRec.SubType__c)){
               		caseRec.SubType__c = CONSTANTS.CASE_SUBTYPE_LEASING_FINANCE;
                }
            }else if(CaseRecTypeName == CONSTANTS.MANAGE_BANK_GUARANTEE){
                caseRec.Type = CONSTANTS.CASE_TYPE_LV04BANK_GUARANTEE;
                if(String.isBlank(caseRec.SubType__c)){
               		caseRec.SubType__c = CONSTANTS.CASE_SUBTYPE_TRANSFER;
                }
            }else if(CaseRecTypeName == CONSTANTS.CENTRE_TEAM){
                caseRec.Type = CONSTANTS.CASE_TYPE_LV10CENTRE;
                if(String.isBlank(caseRec.SubType__c)){
               		caseRec.SubType__c = CONSTANTS.CASE_SUBTYPE_BAD_DEBIT_WRITE_OFF;
                }
                
            }else if(CaseRecTypeName == CONSTANTS.LEASING_FINANCE){
                caseRec.Type = CONSTANTS.CASE_TYPE_LV11LEASING_FINANCE;
                if(String.isBlank(caseRec.SubType__c)){
               		caseRec.SubType__c = CONSTANTS.CASE_SUBTYPE_BILLING_OF_PERCENT_RENT;
                }
                
            }else if(CaseRecTypeName == CONSTANTS.TERMINATE_A_LEASE){ 
                caseRec.Type = CONSTANTS.CASE_TYPE_LV05TERMINATION;
                if(String.isBlank(caseRec.SubType__c)){
               		caseRec.SubType__c = CONSTANTS.CASE_SUBTYPE_PRE_EXPIRY_OF_LEASE;
                }
            }else if(CaseRecTypeName == CONSTANTS.UPDATE_PROMOTIONAL_ALLOWANCE){ 
                
                caseRec.origin = CONSTANTS.CASE_ORIGIN_DEVELOPMENT;
            }
				
            caseList.add(caseRec);
        }
        
        case caseScentreRec1 = TestDataFactory.CreateCase(accountList[0], caseRecordTypeMapByName.get(CONSTANTS.CENTRE_TEAM).getRecordTypeId(), contractRec.Id);
        caseScentreRec1.UnexpiredFitoutAmount__c = 28.50;
        caseScentreRec1.Space__c = contractRec.Space__c;
        if(String.isBlank(caseScentreRec1.SubType__c)){
            caseScentreRec1.SubType__c = CONSTANTS.CASE_SUBTYPE_HOARDING;
        }
        
        case caseScentreRec2 = TestDataFactory.CreateCase(accountList[0], caseRecordTypeMapByName.get(CONSTANTS.CENTRE_TEAM).getRecordTypeId(), contractRec.Id);
        caseScentreRec2.UnexpiredFitoutAmount__c = 28.50;
        caseScentreRec2.Space__c = contractRec.Space__c;
        if(String.isBlank(caseScentreRec2.SubType__c)){
            caseScentreRec2.SubType__c = CONSTANTS.CASE_SUBTYPE_MAILBOX_CHARGES;
        }
        
        case caseScentreRec3 = TestDataFactory.CreateCase(accountList[0], caseRecordTypeMapByName.get(CONSTANTS.MISCELLANEOUS_LEASE).getRecordTypeId(), contractRec.Id);
        caseScentreRec3.UnexpiredFitoutAmount__c = 28.50;
        caseScentreRec3.Space__c = contractRec.Space__c;
        if(String.isBlank(caseScentreRec3.SubType__c)){
            caseScentreRec3.SubType__c = CONSTANTS.CASE_SUBTYPE_CENTRE;
        }
        
        caseList.add(caseScentreRec1);
        caseList.add(caseScentreRec2);
        caseList.add(caseScentreRec3);
        database.insert(caseList);
        caseList = [SELECT Id, Subtype__c FROM Case];
        
        //CREATE PROPERTY TEAM
        Property__c propRec = [SELECT Id FROM Property__c LIMIT 1];
        propTeam = TestDataFactory.createPropertyTeam(propRec.Id, CONSTANTS.TEAM_ROLE_GMLEASING, UserInfo.getUserId(), propTeamRecordTypeMapByName.get(CONSTANTS.PRT_INTERNAL_TEAM_MEMBER).getRecordTypeId());
        TriggerHandler.clearAllBypasses();
        database.insert(propTeam);
    }
    
    public static testMethod void testPostChatterToCase(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        PropertyTeam__c propTeam = [SELECT property__c,id,teammember__c, teammember__r.IsActive,role__c, Active__c from propertyteam__c WHERE teammember__r.IsActive = true];
        System.debug('Property Team ' + propTeam);
        List<Case> caseList = [SELECT Id FROM CASE LIMIT 20];
        //System.debug('Case ' + caseList);
        List<Id> caseIDList = new List<Id>();
        
        for(Case caseRec : caseList){
            caseIDList.add(caseRec.Id);
        }
        
        System.runAs(testUser) {
            
            Test.startTest();
            
            PostChatterToCaseInvoc.postChatterToCase(caseIDList);
            Test.stopTest();
        }
        List<CaseFeed> caseFeedList = [SELECT ID, ParentId, Body from CaseFeed where Id in :caseIDList];
        System.assertEquals(true, caseFeedList <> null);
    }
}