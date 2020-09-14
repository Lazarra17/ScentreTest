@isTest
public class UpdateUsageClauseBatchTest {
    @TestSetup private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        
        //Create Price Book
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //Create Property
        List<Property__c> propertyList = new List<Property__c>();
        propertyList = TestDataFactory.createProperty(1, priceBookList[0]);
        database.insert(propertyList);
        
        //Create Account
        List<Account> accountList = new List<Account>();
        accountList = TestDataFactory.createAccountBulk(5, propertyList[0].Id, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
        database.insert(accountList);
        
        //Create Space
        List<Space__c> spaceList = new List<Space__c>();
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        database.insert(spaceList);
        
        //Create Opportunity
        List<Opportunity> oppList = new List<Opportunity>();
        oppList = TestDataFactory.createOpportunity(1, accountList[0], propertyList[0], spaceList[0]);
        database.insert(oppList);
        
        //create Opportunity Clause
        List<OpportunityClause__c> listOppclause = new List<OpportunityClause__c>();
        for (Opportunity OppRec: oppList ){
            OpportunityClause__c Oppclause = TestDataFactory.CreateOppClause(OppRec);
            listOppclause.add(Oppclause);
        }
        database.insert(listOppclause);       
    }
    
    public static testMethod void testGenerateAccountEvents(){
        
        Test.startTest();
        UpdateUsageClauseBatch uUCB = new UpdateUsageClauseBatch();
        Database.executeBatch(uUCB, 5);
        Test.stopTest();
    }

}