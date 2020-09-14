@isTest
private class NewLeaseStatusUpdateBatchTest {
	
	@testSetup
    private static void testSetup() {
		Integer counter;
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
		Contact contactTemp;
		List<Contact> contactList = new List<Contact>();
        List<Opportunity> opportunityList = new List<Opportunity>();
		
		for(Account acc : accountList){
			contactTemp = TestDataFactory.createContact('Test name ' + counter++, acc);
			contactList.add(contactTemp);
			
			for(Opportunity opp : TestDataFactory.createOpportunity(3, acc)){
				opp.Space__c = spaceList[0].Id;
				opp.Property__c = propertyList[0].Id;
				opp.ProposedStartDate__c = Date.today().addDays(60);
                opp.Type = CONSTANTS.OPPTY_STAGENAME_NEWLEASE;
                opp.TechReadyForBatch__c = true;
                opp.JDESentStatus__c = '';
				opportunityList.add(opp);
			}
		}
        
        Database.insert(contactList);
        Database.insert(opportunityList);
        System.debug('OPPORTUNITY LIST ===== ' + opportunityList );
	}
	
	@isTest
	private static void testNewLeaseStatusUpdateBatch() {
		Test.startTest();
			NewLeaseStatusUpdateBatch schedulableBatch = new NewLeaseStatusUpdateBatch();
			Id batchId = Database.executeBatch(schedulableBatch);
		Test.stopTest();
		
		System.assertNotEquals(batchId, null);
	}
    
    @isTest
	private static void testNewLeaseStatusUpdateBatchSchedulable() {
		NewLeaseStatusUpdateBatch schedulableBatch = new NewLeaseStatusUpdateBatch();
		Test.startTest();
		String sch = '0 0 12 1/1 * ? *'; 
        String jobId = system.schedule('Test Space Occupancy Update Schedulable', sch, schedulableBatch); 
        Test.stopTest();
		System.assertNotEquals(jobId, null);
	}
}