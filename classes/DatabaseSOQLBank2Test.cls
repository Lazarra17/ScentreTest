@isTest
public class DatabaseSOQLBank2Test{
    
    @TestSetup 
    private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> precedentClauseRecordTypeMapByName  = RecordTypeUtil.getAllRecordTypesByName(Constants.PRECEDENT_CLAUSE_API);
        Account accountRecord;
        PrecedentClause__c precedentClauseRecord;
        Account account = new Account();
        List<Account> parentAccList = new List<Account>();
        List<Property__c> propertyList = new List<Property__c>();
        List<PrecedentClause__c> precedentClauseList = new List<PrecedentClause__c>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Product2> productList = new List<Product2>();
        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>();
        List<Space__c> spaceList = new List<Space__c>();
        Pricebook2 pricebookRecord;
        Product2 productRecord;
        
        //CREATE PRODUCT
        productRecord = TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, Constants.RENT);
        insert productRecord;
        
        List<Pricebook2> priceBookList = TestDataFactory.createPricebook(1);
        Database.insert(priceBookList);
        Pricebook2 priceBookRec = [SELECT Id, CurrencyIsoCode FROM Pricebook2 LIMIT 1];
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(1);
        propertyList[0].Pricebook__c = priceBookRec.Id;
        database.insert(propertyList);
        propertyList = [SELECT Id FROM Property__c LIMIT 1];
        
        //CREATE PARENT ACCOUNT
        parentAccList.addAll(TestDataFactory.createAccountBulk(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(parentAccList);
        parentAccList = [SELECT Id, Property__c FROM Account LIMIT 1];
        
        //CREATE ACCOUNT
        account = TestDataFactory.createAccountwithParent(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), parentAccList.get(0).Id);
        database.insert(account);
        account = [SELECT Id, Property__c from Account LIMIT 1];
        
        //CREATE PRECEDENT CLAUSE
        
        for(Integer counter = 0; counter < 10; counter++) {
            precedentClauseRecord = TestDataFactory.createPrecedentClause(counter, account.Id);
            if(counter < 190) {
                precedentClauseRecord.RecordTypeId = precedentClauseRecordTypeMapByName.get(Constants.NATIONAL_PRECEDENT_CLAUSES).getRecordTypeId();
            } else {
                precedentClauseRecord.RecordTypeId = precedentClauseRecordTypeMapByName.get(Constants.NATIONAL_AGREEMENTS).getRecordTypeId();
            }
            precedentClauseRecord.StandardReviewTypes__c = 'CPI+1.5';
            precedentClauseList.add(precedentClauseRecord);
        }
        database.insert(precedentClauseList);
        
        //CREATE OPPORTUNITY
        opportunityList = TestDataFactory.createOpportunity(10, account);
        database.insert(opportunityList);
        
        //CREATE PRICEBOOK
        pricebookRecord = TestDataFactory.createPricebook();
        database.insert(pricebookRecord);
        pricebookRecord = [SELECT Id FROM Pricebook2 LIMIT 1];
        
        //CREATE PRODUCTS
        productList = TestDataFactory.createProduct(10);
        database.insert(productList);
        
        //CREATE PRICEBOOK ENTRY
        for(Integer i = 0; i < 10; i++) {
            pricebookEntryList.addAll(TestDataFactory.createStandardPriceBookEntry(1, productList[i]));
        }
        database.insert(pricebookEntryList);
        
        //CREATE PROPERTIES
        propertyList = TestDataFactory.createProperty(10);
        for (Property__c prop : propertyList){
            prop.Pricebook__c = priceBookRec.Id;
        }
        insert propertyList;
        
        //CREATE SPACES
        spaceList = TestDataFactory.createSpace(10, propertyList);
        insert spaceList;
        
    }
    
    public static testMethod void MyTestMethod () {    
        Test.startTest();
        
        List<Opportunity> oppList = [Select Id from Opportunity];
        Set<ID> oppSetIds =  (new Map<Id,Opportunity>(oppList)).keySet();
        
        Account accountRec = [SELECT Id, Property__c from Account LIMIT 1];
        Set<ID> accSetIds =  new Set<ID>();
        accSetIds.add(accountRec.Id);
        
        List<Space__c> spacesList = [SELECT Id FROM Space__c];
        Set<ID> spaceSetIds = (new Map<Id, Space__c>(spacesList)).keySet();
		   
        
        DatabaseSOQLBank.getOpportunityLineItemAggregate(oppList);
        DatabaseSOQLBank.getOpportunityMap(oppSetIds);
        DatabaseSOQLBank.getOpportunity(accSetIds);
        DatabaseSOQLBank.getAccountByPrecedentClause(accSetIds);
        DatabaseSOQLBank.getReviewRecord(oppSetIds);
        
        
        
        
        List<Product2> prodList = DatabaseSOQLBank.getProductsToPopulate(new List<String>{'Test%'});
        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Name, Product2Id FROM PriceBookEntry];
        Set<ID> pbeSetIds =  (new Map<Id,PricebookEntry>(pbeList)).keySet();
        DatabaseSOQLBank.getPriceBookEntry(pbeSetIds, pbeList[0].Name );
        DatabaseSOQLBank.getPriceBookEntry(prodList);
        DatabaseSOQLBank.getPrecedentClauseOfAccount(new List<Id>(accSetIds),RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT).get(CONSTANTS.PROPERTY_BASED).getRecordTypeId());
		Id stdPriceBookId = DatabaseSOQLBank.getStandardPricebookId();
        Map<Id, Property__c> propPriceBookMap = DatabaseSOQLBank.getPropertyPricebookMap();
        DatabaseSOQLBank.getOpportunitySpaceMap(new List<Id>(spaceSetIds));
        DatabaseSOQLBank.getSpaces(spaceSetIds);
        Test.stopTest();
    }
    
    
}