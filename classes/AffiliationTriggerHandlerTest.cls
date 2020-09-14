@isTest
private class AffiliationTriggerHandlerTest {
	
	@testSetup
    private static void testSetup() {
		Integer counter;
		Integer counter2;
		Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
		
		//CREATE PRICEBOOK
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        priceBookList = TestDataFactory.createPricebook(1);
        Database.insert(priceBookList);
		
		//CREATE PROPERTY
        List<Property__c> propertyList = new List<Property__c>();
        propertyList = TestDataFactory.createProperty(1, priceBookList[0]);
        Database.insert(propertyList);
		
		//Create Space
        List<Space__c> spaceList = new List<Space__c>();
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        database.insert(spaceList);
		
		//CREATE ACCOUNT
        List<Account> accountList = new List<Account>();
        accountList = TestDataFactory.createAccountBulk(5, propertyList[0].Id, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
        Database.insert(accountList);
		
		//CREATE CONTACT AND OPPORTUNITY
		counter = 1;
		counter2 = 0;
		Contact contactTemp;
		List<Contact> contactList = new List<Contact>();
        List<Opportunity> opportunityList = new List<Opportunity>();
		
		for(Account acc : accountList){
			contactTemp = TestDataFactory.createContact('Test name ' + counter++, acc);
			contactList.add(contactTemp);
			
			counter2 = 0;
			for(Opportunity opp : TestDataFactory.createOpportunity(3, acc)){
				opp.Space__c = spaceList[0].Id;
				opp.Property__c = propertyList[0].Id;
				
				if(counter == 1){
					opp.NumberofGuarantors__c = 1;
				}
				
				opportunityList.add(opp);
				
				counter++;
			}
		}
        
        Database.insert(contactList);
        Database.insert(opportunityList);
	}
	
	@isTest
	private static void testAffiliationInsert() {
		Integer counter = 1;
		List<Affiliation__c> affiliationList = new List<Affiliation__c>();
		List<Account> accountList = [SELECT Id, Name FROM Account];
		Map<Id, Contact> accIdContactMap = new Map<Id, Contact>();
		
		for(Contact con : [SELECT Id, Name, AccountId FROM Contact]){
			accIdContactMap.put(con.AccountId, con);
		}
		
		for(Account acc : accountList){
			affiliationList.add(
				TestDataFactory.createAffiliation(
					acc, 
					accountList[counter++], 
					accIdContactMap.get(acc.Id), 
					Constants.COMP_PERSONAL_GUARANTEES, 
					Constants.CURRENT
				)
			);
			
			if(counter == accountList.size()){
				counter = 0;
			}
		}
		
		Test.startTest();
			Database.insert(affiliationList);
		Test.stopTest();
	}
    
    /**
     * @author			:Kyle Tan
     **/
    @isTest
    private static void onDeleteTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Account> accountList = new List<Account>([SELECT Id FROM Account]);
        List<Contact> contactList = new List<Contact>([SELECT Id FROM Contact]);
        //Create Affiliation
        List<Affiliation__c> affiliationList = new List<Affiliation__c>();
        affiliationList.add(TestDataFactory.createAffiliation(accountList[0], 
                                                              accountList[1], 
                                                              contactList[0], 
                                                              Constants.COMP_PERSONAL_GUARANTEES, 
                                                              Constants.CURRENT));
        database.insert(affiliationList);
        affiliationList = [SELECT Id FROM Affiliation__c];
        system.runAs(testUser) {
            test.startTest();
            TriggerHandler.clearAllBypasses();
            database.update(affiliationList);
            TriggerHandler.clearAllBypasses();
            database.delete(affiliationList);
            test.stopTest();
        }
    }
}