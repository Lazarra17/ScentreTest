@isTest
public class UpdatePendingApproverBatchTest {
    
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
			
			for(Opportunity opp : TestDataFactory.createOpportunity(1, acc)){
				opp.Space__c = spaceList[0].Id;
				opp.Property__c = propertyList[0].Id;
				opp.ProposedStartDate__c = Date.today().addDays(60);
                opp.Type = CONSTANTS.OPPTY_STAGENAME_NEWLEASE;
                opp.TechReadyForBatch__c = true;
                opp.JDESentStatus__c = '';
                opp.ApprovalStatus__c = CONSTANTS.PENDING_INI_APRV;
                //opp.Pending_Approver__c=null;
				opportunityList.add(opp);
			}
		}
        
        Database.insert(contactList);
        Database.insert(opportunityList);
        System.debug('OPPORTUNITY LIST ===== ' + opportunityList );
	}
	
	@isTest
	private static void testUpdatePendingApproverBatch() {
		
        
        UpdatePendingApproverBatch obj1 = new UpdatePendingApproverBatch();
        
        Test.startTest();         
			Database.executeBatch(obj1);   
		Test.stopTest();
		
		
	}

}