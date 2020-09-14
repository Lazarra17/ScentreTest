/**
 * @author:         Kyle Tan
 * @desc:           Test method for Security Controller class
 **/
@isTest
private class SecurityControllerTest {
    @testSetup
    private static void testSetup() {
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
		accountList[0].PartnershipSegmentation__c = 'Strategic Partner';
        database.insert(accountList);
        
        //Create Contact
        List<Contact> conList = new List<Contact>();
        conList.add(TestDataFactory.createContact('Test User', accountList[0]));
        conList.add(TestDataFactory.createContact('Test User2', accountList[1]));
        database.insert(conList);
        
        //Create Affiliations
        List<Affiliation__c> affList = new List<Affiliation__c>();
        affList.add(TestDataFactory.createAffiliation(accountList[0], accountList[1], conList[0], Constants.COMP_PERSONAL_GUARANTEES, Constants.CURRENT));
        affList.add(TestDataFactory.createAffiliation(accountList[0], accountList[1], conList[0], Constants.COMP_PARENT_GUARANTEES, Constants.CURRENT));
        affList.add(TestDataFactory.createAffiliation(accountList[0], accountList[1], conList[0], Constants.PERSONAL_GUARANTEES_FRANCHISEE, Constants.CURRENT));
        affList.add(TestDataFactory.createAffiliation(accountList[0], accountList[1], conList[1], Constants.PERSONAL_GUARANTEES_FRANCHISEE, Constants.CURRENT));
        database.insert(affList);
        
        //Create Space
        List<Space__c> spaceList = new List<Space__c>();
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        database.insert(spaceList);
        
		//Create Precedent Clause
		Map<String, Schema.RecordTypeInfo> preClauseTypeMapByName = RecordTypeUtil.getAllRecordTypesByName('PrecedentClause__c');
		PrecedentClause__c preClause = TestDataFactory.createPrecedentClause(1, accountList[1].Id, preClauseTypeMapByName.get('National Agreements').getRecordTypeId());
		Database.insert(preClause);
		
        //Create Opportunity
        List<Opportunity> oppList = new List<Opportunity>();
        oppList = TestDataFactory.createOpportunity(1, accountList[0], propertyList[0], spaceList[0]);
		oppList[0].NationalAgreement__c = preClause.Id;
        database.insert(oppList);
		
		// Create Clause Library
		List<ClauseLibrary__c> clauseLibraryList = TestDataFactory.createClauseLibrary(1);
		Map<String, Schema.RecordTypeInfo> cLibraryRecordTypeByName = RecordTypeUtil.getAllRecordTypesByName('ClauseLibrary__c');
		clauseLibraryList[0].Type__c = 'RCA';
		clauseLibraryList[0].SubType__c = Constants.NATIONAL_CHANGE_IN_SECURITY;
		clauseLibraryList[0].Name = Constants.NATIONAL_CHANGE_IN_SECURITY;
		
		for(ClauseLibrary__c cLibrary : clauseLibraryList){
			cLibrary.RecordTypeId = cLibraryRecordTypeByName.get('CLA - Retail Clauses').getRecordTypeId();
		}
		
		Database.insert(clauseLibraryList);
		
    }
    
    /**
     * @author:     Kyle Tan
     **/
    @isTest
    private static void getOpportunityListTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Set<Id> accIdSet = new Set<Id>();
        Set<Id> oppIdSet = new Set<Id>();
        List<Opportunity> oppList = new List<Opportunity>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        for(Affiliation__c affRec :[SELECT Id, Account__c  FROM Affiliation__c]) {
            accIdSet.add(affRec.Account__c);
        }
        oppList = [SELECT Id FROM Opportunity WHERE AccountId IN :accIdSet];
        for(Opportunity oppRec :oppList) {
            oppIdSet.add(oppRec.Id);
        }
        system.runAs(testUser) {
            test.startTest();
            oppMap = SecurityController.getOpportunityMap(oppIdSet);
            test.stopTest();
        }
        system.assertEquals(1, oppMap.size());
    }
    
    /**
     * @author:     Kyle Tan
     **/
    @isTest
    private static void getAffiliationListTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Set<Id> accIdSet = new Set<Id>();
        List<Opportunity> oppList = new List<Opportunity>();
        List<Affiliation__c> affList = new List<Affiliation__c>([SELECT Id, Account__c  FROM Affiliation__c]);
        List<Affiliation__c> affListToAssert = new List<Affiliation__c>();
        for(Affiliation__c affRec :affList) {
            accIdSet.add(affRec.Account__c);
        }
        oppList = [SELECT Id, AccountId FROM Opportunity WHERE AccountId IN :accIdSet];
        system.runAs(testUser) {
            test.startTest();
            affListToAssert = SecurityController.getAffiliationList(oppList[0]);
            test.stopTest();
        }
        system.assertEquals(4, affListToAssert.size());
    }

    /**
     * @author:     Kyle Tan
     **/
    @isTest
    private static void getOpportunityContactsTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        Set<Id> oppIdSet = new Set<Id>();
        Set<Id> assertIdSet = new Set<Id>();
        for(Opportunity oppRec :oppList) {
            oppIdSet.add(oppRec.Id);
        }
        system.runAs(testUser) {
            test.startTest();
            assertIdSet = SecurityController.getOpportunityContacts(oppIdSet, oppList[0].Id);
            test.stopTest();
        }
        system.assertEquals(2, assertIdSet.size());
    }
    
    /**
     * @author:     Kyle Tan
     **/
    @isTest
    private static void getAffiliationsTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
		LightningResponse response = new LightningResponse();
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        system.runAs(testUser) {
            test.startTest();
            response = SecurityController.getAffiliations(oppList[0].Id);
            test.stopTest();
        }
        system.assertEquals('SUCCESS', response.status);
    }
    
    /**
     * @author:     Kyle Tan
     **/
    @isTest
    private static void saveAffiliationListTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
		LightningResponse response = new LightningResponse();
        LightningResponse assertResponse = new LightningResponse();
        List<OpportunityContactRole> oppConRoleList = new List<OpportunityContactRole>();
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        List<Contact> conList = new List<Contact>([SELECT Id, Name FROM Contact]);
        List<SecurityController.AffiliationsWrapper> updatedListWrapper = new List<SecurityController.AffiliationsWrapper>();
        Contact conRec = [SELECT Id FROM Contact WHERE LastName ='Test User2' LIMIT 1];
        oppConRoleList.add(SecurityController.createOpportunityContactRole(Constants.COMP_PERSONAL_GUARANTEES, conList[0].Id, oppList[0].Id));
        database.insert(oppConRoleList);
        oppList[0].NumberofGuarantors__c = null;
        database.update(oppList);
        response = SecurityController.getAffiliations(oppList[0].Id);
        updatedListWrapper = (List<SecurityController.AffiliationsWrapper>) JSON.deserialize(response.returnValue, List<SecurityController.AffiliationsWrapper>.class);
        Integer counter = 0;
        for(SecurityController.AffiliationsWrapper wrapRec :updatedListWrapper) {
            counter++;
            wrapRec.affContactId = conList[0].Id;
            wrapRec.isActive = false;
            if(counter == updatedListWrapper.size()) {
                wrapRec.affContactId = conRec.Id;
                wrapRec.isActive = true;
            }
        }
        system.debug('updatedListWrapper-->' + updatedListWrapper);
        system.runAs(testUser) {
            test.startTest();
            assertResponse = SecurityController.saveAffiliationList(oppList[0].Id, JSON.serialize(updatedListWrapper));
            test.stopTest();
        }
        system.assertEquals('SUCCESS', response.status);
    }
    
    /**
     * @author:     Kyle Tan
     **/
    @isTest
    private static void saveAffiliationListAddConRoleTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
		LightningResponse response = new LightningResponse();
        LightningResponse assertResponse = new LightningResponse();
        List<OpportunityContactRole> oppConRoleList = new List<OpportunityContactRole>();
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        List<Contact> conList = new List<Contact>([SELECT Id, Name FROM Contact]);
        List<SecurityController.AffiliationsWrapper> updatedListWrapper = new List<SecurityController.AffiliationsWrapper>();
        Contact conRec = [SELECT Id FROM Contact WHERE LastName ='Test User2' LIMIT 1];
        oppConRoleList.add(SecurityController.createOpportunityContactRole(Constants.COMP_PERSONAL_GUARANTEES, conList[0].Id, oppList[0].Id));
        database.insert(oppConRoleList);
        oppList[0].NumberofGuarantors__c = null;
        database.update(oppList);
        response = SecurityController.getAffiliations(oppList[0].Id);
        updatedListWrapper = (List<SecurityController.AffiliationsWrapper>) JSON.deserialize(response.returnValue, List<SecurityController.AffiliationsWrapper>.class);
        Integer counter = 0;
        database.delete([SELECT Id FROM OpportunityContactRole]);
        for(SecurityController.AffiliationsWrapper wrapRec :updatedListWrapper) {
            counter++;
            wrapRec.affContactId = conList[0].Id;
            wrapRec.isActive = true;
            if(counter == updatedListWrapper.size()) {
                wrapRec.affContactId = conRec.Id;
                wrapRec.isActive = true;
            }
        }
        system.debug('updatedListWrapper-->' + updatedListWrapper);
        system.runAs(testUser) {
            test.startTest();
            assertResponse = SecurityController.saveAffiliationList(oppList[0].Id, JSON.serialize(updatedListWrapper));
            test.stopTest();
        }
        system.assertEquals('SUCCESS', response.status);
    }
    /**
     * @author:     Kyle Tan
     **/
    @isTest
    private static void userHasEditAccessTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        LightningResponse response = new LightningResponse();
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        List<Account> accountList = new List<Account>([SELECT Id FROM Account]);
        system.runAs(testUser) {
            test.startTest();
            response = SecurityController.userHasEditAccess(oppList[0].Id);
            test.stopTest();
        }
        system.assertEquals('SUCCESS', response.status);
    }
    
    /**
     * @author:     Kyle Tan
     **/
    @isTest
    private static void buildAffiliationWrapperTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Set<Id> accIdSet = new Set<Id>();
        Set<Id> oppIdSet = new Set<Id>();
        Set<Id> assertIdSet = new Set<Id>();
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        List<Affiliation__c> affList = new List<Affiliation__c>([SELECT Id, Account__c  FROM Affiliation__c]);
        List<Affiliation__c> affListToAssert = new List<Affiliation__c>();
        List<SecurityController.AffiliationsWrapper> wrapper = new List<SecurityController.AffiliationsWrapper>();
        for(Opportunity oppRec :oppList) {
            oppIdSet.add(oppRec.Id);
        }
        for(Affiliation__c affRec :affList) {
            accIdSet.add(affRec.Account__c);
        }
        oppList = [SELECT Id, AccountId FROM Opportunity WHERE AccountId IN :accIdSet];
        affList = SecurityController.getAffiliationList(oppList[0]);
        assertIdSet = SecurityController.getOpportunityContacts(oppIdSet, oppList[0].Id);
        system.runAs(testUser) {
            test.startTest();
            wrapper = SecurityController.buildAffiliationWrapper(affList, assertIdSet);
            test.stopTest();
        }
    }
	
	@isTest
    private static void testCreateRCAOppClause(){
		Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SYSTEM_ADMINISTRATOR LIMIT 1];
        User runningUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
		
		List<Opportunity> opportunityList = [SELECT Id, RecordType.DeveloperName, SecurityDeposit__c, SecurityDepositMonths__c, 
											 SecurityDepositWeeks__c, SecurityDepositDays__c, 
											 NationalAgreement__r.RequiredSecurityDepositDays__c, 
											 NationalAgreement__r.RequiredSecurityDepositMonths__c, 
											 NationalAgreement__r.RequiredSecurityDepositWeeks__c, NationalAgreement__c, 
											 Account.PartnershipSegmentation__c, 
											 NationalAgreement__r.Account__r.PartnershipSegmentation__c
											 FROM Opportunity];
		
		opportunityList[0].SecurityDepositMonths__c = 4;
		Database.update(opportunityList[0]);
		
		system.runAs(runningUser){
            Test.startTest();
                SecurityController.createRCAOppClause(opportunityList[0]);
            Test.stopTest();
        }
	}
}