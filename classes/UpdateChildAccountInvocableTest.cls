/**
 * @author:				Kyle Tan
 * @desc:				test class for UpdateChildAccountInvocable
 **/
@isTest
private class UpdateChildAccountInvocableTest {
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
        
        //Create Space
        List<Space__c> spaceList = new List<Space__c>();
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        database.insert(spaceList);
        
        //Create Lead
        List<Lead> leadList = new List<Lead>();
        Database.LeadConvert lc = new database.LeadConvert();
        leadList = TestDataFactory.createLead(1, null, propertyList[0], spaceList[0]);
        database.insert(leadList);
        lc.setLeadId(leadList[0].Id);
        lc.setConvertedStatus('Qualified');
        database.convertLead(lc);
    }
    
    /**
     * @author:				Kyle Tan
     **/
    @isTest
    private static void updateChildAccountTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Account> accountList = new List<Account>([SELECT Id, TechConvertedLeadId__c FROM Account WHERE TechConvertedLeadId__c != null AND RecordType.DeveloperName = 'ACCGroupLevel']);
        system.runAs(testUser) {
            test.startTest();
            UpdateChildAccountInvocable.updateChildAccount(accountList);
            test.stopTest();
        }
    }
}