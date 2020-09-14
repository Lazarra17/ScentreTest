/**
 * @author:			Kyle Tan
 * @desc:			test class for AffiliationBL
 **/
@isTest
private class AffiliationBLTest {

    @testSetup
    private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);

        //Create Price Book
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //Create Property
        List<Property__c> propertyList = new List<Property__c>();
        propertyList = TestDataFactory.createProperty(1, priceBookList[0]);
        database.insert(propertyList);
        
        //Create Space
        List<Space__c> spaceList = new List<Space__c>();
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        database.insert(spaceList);
        
        //Create Account
        List<Account> accountList = new List<Account>();
        accountList = TestDataFactory.createAccountBulk(5, propertyList[0].Id, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
        database.insert(accountList);
        
        //Create Contact
        List<Contact> contactList = new List<Contact>();
        contactList.add(TestDataFactory.createContact('Test Name', accountList[0]));
        database.insert(contactList);
        
        //Create Affiliation
        List<Affiliation__c> affiliationList = new List<Affiliation__c>();
        affiliationList.add(TestDataFactory.createAffiliation(accountList[0], 
                                                              accountList[1], 
                                                              contactList[0], 
                                                              Constants.COMP_PERSONAL_GUARANTEES, 
                                                              Constants.CURRENT));
        database.insert(affiliationList);
        
        //Create Opportunity
        List<Opportunity> opportunityList = new List<Opportunity>();
        opportunityList = TestDataFactory.createOpportunity(5, accountList[0], propertyList[0], spaceList[0]);
        database.insert(opportunityList);
        
        //Create Opportunity Contact Role
        List<OpportunityContactRole> oppContactRoleList = new List<OpportunityContactRole>();
        oppContactRoleList.add(TestDataFactory.createOpportunityContactRole(opportunityList[0], contactList[0], 'Influencer'));
        database.insert(oppContactRoleList);
    }
    
    /**
     * @author:			Kyle Tan
     **/
    @isTest
    private static void createOpportunityConRolesTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<OpportunityContactRole> oppContactRoleList  = new List<OpportunityContactRole>();
        List<Affiliation__c> affiliationList = new List<Affiliation__c>([SELECT Id, Contact__c, Status__c, Type__c FROM Affiliation__c]);
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        system.runAs(testUser) {
            test.startTest();
            oppContactRoleList = AffiliationBL.createOpportunityConRoles(affiliationList[0], opportunityList);
            test.stopTest();
        }
        system.assertEquals(5, oppContactRoleList.size());
    }
    
    /**
     * @author:			Kyle Tan
     **/
    @isTest
    private static void updateNumberofGuarantorsTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> returnOppList = new List<Opportunity>();
        List<Affiliation__c> affiliationList = new List<Affiliation__c>([SELECT Id, Contact__c, Status__c, Type__c FROM Affiliation__c]);
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id, NumberofGuarantors__c FROM Opportunity]);
        system.runAs(testUser) {
            test.startTest();
            opportunityList[0].NumberofGuarantors__c = 0;
            returnOppList = AffiliationBL.updateNumberofGuarantors(affiliationList[0], opportunityList);
            test.stopTest();
        }
        for(Opportunity oppRec :returnOppList) {
            if(oppRec.Id == opportunityList[0].Id) {
                system.assertEquals(1, oppRec.NumberofGuarantors__c);
            } else {
                system.assertEquals(2, oppRec.NumberofGuarantors__c);
            }
        }
    }
    
    /**
     * @author:			Kyle Tan
     **/
    @isTest
    private static void deleteContactRoleTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<OpportunityContactRole> returnOppContactRoleList  = new List<OpportunityContactRole>();
        List<Affiliation__c> affiliationList = new List<Affiliation__c>([SELECT Id, Contact__c, Status__c, Type__c FROM Affiliation__c]);
        List<OpportunityContactRole> oppContactRoleList  = new List<OpportunityContactRole>([SELECT Id, ContactId FROM OpportunityContactRole]);
        system.runAs(testUser) {
            test.startTest();
            returnOppContactRoleList = AffiliationBL.deleteContactRole(affiliationList[0], oppContactRoleList);
            test.stopTest();
        }
        system.assertEquals(6, returnOppContactRoleList.size());
    }
    
    /**
     * @author:			Kyle Tan
     **/
    @isTest
    private static void reduceNumberOfGuarantorsTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> returnOppList = new List<Opportunity>();
        List<Affiliation__c> affiliationList = new List<Affiliation__c>([SELECT Id, Contact__c, Status__c, Type__c FROM Affiliation__c]);
        List<OpportunityContactRole> oppContactRoleList  = new List<OpportunityContactRole>([SELECT Id, OpportunityId FROM OpportunityContactRole]);
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id, NumberofGuarantors__c FROM Opportunity]);
        system.runAs(testUser) {
            test.startTest();
            returnOppList = AffiliationBL.reduceNumberOfGuarantors(affiliationList[0], oppContactRoleList, opportunityList);
            test.stopTest();
        }
        for(Opportunity oppRec :returnOppList) {
            system.assertEquals(0, oppRec.NumberofGuarantors__c);
        }
    }
}