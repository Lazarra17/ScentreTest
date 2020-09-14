/**
 * @author          : Yana Navarro
 * @desc            : Test class for OutgoingsRefreshBatch
 **/
@isTest
private class OutgoingsRefreshBatchTest {
    
    @testSetup
    private static void testSetup(){
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName
            = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> opportuntiyRecordTypeMapByName
            = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY);
        
        //Create Product
        Product2 productTemp;
        Set<String> productNameSet;
        List<Product2> productList = new List<Product2>();
        
        productNameSet = new Set<String>{
            'Water Rates',
            'Cleaning',
            'Land Tax'
        };
        
        for(String prodName : productNameSet){
            productTemp = TestDataFactory.createProduct(prodName, 'Recoveries');
            productTemp.ProductCode = Constants.OTG;
            productTemp.SpaceType__c = '1;2';
            productTemp.EffectiveToDate__c = Date.newInstance(Date.today().year(), 12, 31);
            productTemp.EffectiveFromDate__c = Date.newInstance(Date.today().year(), 1, 1);
            productTemp.OutgoingsCategory__c = prodName;
            productTemp.DealType__c = 'Semi Gross';
            productTemp.SpaceBillingCategory__c = 'NR';
            productList.add(productTemp);
            
            productTemp = TestDataFactory.createProduct(prodName, 'Recoveries');
            productTemp.ProductCode = Constants.OTG;
            productTemp.SpaceType__c = '1;2';
            productTemp.EffectiveToDate__c = Date.newInstance(Date.today().year() + 1, 12, 31);
            productTemp.EffectiveFromDate__c = Date.newInstance(Date.today().year() + 1, 1, 1);
            productTemp.OutgoingsCategory__c = prodName;
            productTemp.DealType__c = 'Semi Gross';
            productTemp.SpaceBillingCategory__c = 'NR';
            productList.add(productTemp);
        }
        
        database.insert(productList);
        
        //Create Price Book
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //Create PriceBookEntry
        Integer counter = 1;
        PriceBookEntry pbEntryTemp;
        List<PriceBookEntry> priceBookEntryList = new List<PriceBookEntry>();
        List<PriceBookEntry> standardPriceBookEntryList = new List<PriceBookEntry>();
        
        for(Product2 prod : productList){
            if(prod.EffectiveFromDate__c.year() == Date.today().year()){
                pbEntryTemp = TestDataFactory.createPriceBookEntry(1, priceBookList[0], prod)[0];
                pbEntryTemp.Pricebook2Id = priceBookList[0].Id;
                pbEntryTemp.UnitPrice = (1000 * counter++);
                pbEntryTemp.EffectiveToDate__c = prod.EffectiveToDate__c;
                pbEntryTemp.EffectiveFromDate__c = prod.EffectiveFromDate__c;
                pbEntryTemp.UseStandardPrice = false;
                
                priceBookEntryList.add(pbEntryTemp);
            }
            
            pbEntryTemp = TestDataFactory.createPriceBookEntryRecord(prod.Name, prod, null);
            standardPriceBookEntryList.add(pbEntryTemp);
        }
        
        Database.insert(standardPriceBookEntryList);
        Database.insert(priceBookEntryList);
        
        //Create Property
        List<Property__c> propertyList = new List<Property__c>();
        propertyList = TestDataFactory.createProperty(1, priceBookList[0]);
        propertyList[0].ApplicableOutgoings__c = 'Water Rates;Cleaning;Land Tax';
        database.insert(propertyList);
        
        //Create Account
        List<Account> propBasedAccount = new List<Account>();
        propBasedAccount = TestDataFactory.createAccountBulk(1, propertyList[0].Id, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
        database.insert(propBasedAccount);
        
        //Create Space
        List<Space__c> spaceList = new List<Space__c>();
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        spaceList[0].Type__c = '1';
        spaceList[0].BillingCategory__c = 'NR';
        database.insert(spaceList);
        
        List<Opportunity> opportunityList = new List<Opportunity>();
        opportunityList = TestDataFactory.createOpportunity(10, propBasedAccount[0], propertyList[0], spaceList[0]);
        
        for(Opportunity opp : opportunityList){
            opp.RecordTypeId = opportuntiyRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId();
            opp.ProposedRentCommencementDate__c = Date.today().addYears(1);
            opp.DealType__c = 'Semi Gross';         
        }
        Database.insert(opportunityList);
        
        List<PriceBookEntry> newPbEntryList = new List<PriceBookEntry>();
        for(Product2 prod : productList){
            if(prod.EffectiveFromDate__c.year() == Date.today().addYears(1).year()){
                pbEntryTemp = TestDataFactory.createPriceBookEntry(1, priceBookList[0], prod)[0];
                pbEntryTemp.Pricebook2Id = priceBookList[0].Id;
                pbEntryTemp.UnitPrice = (2500 * counter++);
                pbEntryTemp.EffectiveToDate__c = prod.EffectiveToDate__c;
                pbEntryTemp.EffectiveFromDate__c = prod.EffectiveFromDate__c;
                pbEntryTemp.UseStandardPrice = false;
                
                newPbEntryList.add(pbEntryTemp);
            }
        }
        Database.insert(newPbEntryList);
    }
    
    @isTest
    private static void testOutgoingsRefreshBatch(){
        Set<Id> oppIdSet = new Set<Id>();
        List<Opportunity> opportunityList = [SELECT Id, Name FROM Opportunity];
        
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SYSTEM_ADMINISTRATOR LIMIT 1];
        User runningUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        for(Opportunity opp : opportunityList){
            oppIdSet.add(opp.Id);
        }
        
        Id batchId;
        
        system.runAs(runningUser){
            Test.startTest();
                OutgoingsRefreshBatch batch = new OutgoingsRefreshBatch(oppIdSet);
                batchId = Database.executeBatch(batch);
            Test.stopTest();
        }
        
         AsyncApexJob apexJob = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors 
                                 FROM AsyncApexJob 
                                 WHERE Id =: batchId];
        
        system.assertEquals('Completed', apexJob.Status);
    }
  
  
}