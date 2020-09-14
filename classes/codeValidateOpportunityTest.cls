@isTest
public class codeValidateOpportunityTest {
  @testSetup
    private static void testSetup(){
    Account account;
        Contact contact;
        Opportunity opportunityRecord;
        OpportunityContactRole oppContactRole;
        List<Contact> contactList = new List<Contact>();
        List<Account> accountList = new List<Account>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<OpportunityContactRole> oppContactRoleList = new List<OpportunityContactRole>();
        
        //CREATE ACCOUNT LIST
        for(Integer counter = 0; counter < 5; counter++) {
        account = TestDataFactory.createAccount(counter);
        accountList.add(account);
        }
        Database.insert(accountList);
        
        //CREATE CONTACT LIST
        for(Integer counter = 0; counter < 5; counter++) {
        contact = TestDataFactory.createContact('Doe', accountList[counter]);
        contactList.add(contact);
        }
        Database.insert(contactList);
        System.debug('contactListId: ' + contactList[0].id);
        
        
        //CREATE OPPORTUNITY RECORD LIST
        for(Integer counter = 0; counter < 2; counter++) {
            opportunityRecord = TestDataFactory.createOpportunityRecord(counter, accountList);
            opportunityRecord.ApprovalStatus__c = constants.PEND_FINALAPPROV;
            opportunityRecord.NumberofGuarantors__c = counter;
            opportunityList.add(opportunityRecord);
        }
        Database.insert(opportunityList);
        
        //CREATE OPPORTUNITY CONTACT ROLE
        oppContactRole = TestDataFactory.createOpportunityContactRole(opportunityList[0], contact, constants.COMP_PERSONAL_GUARANTEES);
        oppContactRoleList.add(oppContactRole);
        oppContactRoleList.add(TestDataFactory.createOpportunityContactRole(opportunityList[0], contact, constants.COMP_PERSONAL_GUARANTEES));
        Database.insert(oppContactRoleList);
    }
    
    public static testMethod void testValidateRecord() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> opportunityList = [SELECT NumberofGuarantors__c,Id, Name, ApprovalStatus__c FROM Opportunity LIMIT 2];
        List<Id> oppIdList = new List<Id>();
        List<OpportunityContactRole> tempOCRole;
        List<String> guarantorRoles = new List<String>{constants.COMP_PERSONAL_GUARANTEES, constants.COMP_PARENT_GUARANTEES, constants.PERSONAL_GUARANTEES_FRANCHISEE};
        
        for(Integer counter = 0; counter < opportunityList.size(); counter++) {
            oppIdList.add(opportunityList[counter].Id);
        }
        
        System.runAs(testUser) {
            Test.startTest();
        codeValidateOpportunity.validateRecord(oppIdList);
        opportunityList[0].NumberofGuarantors__c = 6;
        opportunityList[1].NumberofGuarantors__c = 3;
        database.update(opportunityList);
        codeValidateOpportunity.validateRecord(oppIdList);
            Test.stopTest();
        }
    }
    
}