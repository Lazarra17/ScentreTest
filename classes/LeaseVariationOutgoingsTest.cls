/**
 * @author          : Yana Navarro
 * @desc            : Test class for LeaseVariationOutgoings
 **/
@isTest
private class LeaseVariationOutgoingsTest {
    
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
            productTemp.EffectiveToDate__c = null;
            productTemp.EffectiveFromDate__c = Date.newInstance(Date.today().year() - 1, 1, 1);
            productTemp.OutgoingsCategory__c = prodName;
            productTemp.DealType__c = 'Semi Gross';
            productTemp.SpaceBillingCategory__c = 'NR';
            productList.add(productTemp);
            
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
        
        Opportunity oppTemp;
        List<Opportunity> opportunityList = new List<Opportunity>();
        for(Integer loopCounter = 0; loopCounter < 4; loopCounter++){
            oppTemp = TestDataFactory.createOpportunity(1, propBasedAccount[0], propertyList[0], spaceList[0])[0];
            oppTemp.RecordTypeId = opportuntiyRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId();
            oppTemp.ProposedRentCommencementDate__c = Date.today();
            oppTemp.DealType__c = 'Semi Gross';
            oppTemp.TechByPassOnClone__c = true;
            opportunityList.add(oppTemp);
        }
        database.insert(opportunityList);
        
        opportunityList[0].Name = Constants.JDE_LEASE + ' Test';
        opportunityList[0].ParentOpportunity__c = opportunityList[1].Id;
        opportunityList[1].Type = null;
        opportunityList[1].Name = Constants.JDE_LEASE + ' Test';
        opportunityList[2].ParentOpportunity__c = opportunityList[3].Id;
        
        database.update(opportunityList);
        
        //Create OpportunityLineItem
        OpportunityLineItem oppLineItem;
        List<OpportunityLineItem> oppLineItemList = new List<OpportunityLineItem>();
        for(PriceBookEntry pbEntry : priceBookEntryList){
            oppLineItem = TestDataFactory.createOpportunityLineItem(0, opportunityList[0], productList[0], pbEntry);
            oppLineItem.Product2Id = pbEntry.Product2Id;
            
            oppLineItem = TestDataFactory.createOpportunityLineItem(0, opportunityList[2], productList[0], pbEntry);
            oppLineItem.Product2Id = pbEntry.Product2Id;
            
            oppLineItemList.add(oppLineItem);
        }
        Database.insert(oppLineItemList);
        
        List<LeaseVariationOutgoings__mdt> lVOutgoingsMetadataList 
            = [SELECT Id, MasterLabel, FieldReferenceAPIName__c, OutgoingName__c
               FROM LeaseVariationOutgoings__mdt];
        
        // Create Contract
        Contract__c contractTemp;
        List<Contract__c> contractList = new List<Contract__c>();
        contractTemp = TestDataFactory.createContract(1, propBasedAccount[0], propertyList[0], opportunityList[0])[0];
        for(LeaseVariationOutgoings__mdt lvMdt : lVOutgoingsMetadataList){
            contractTemp.put(lvMdt.FieldReferenceAPIName__c, 10);
        }
        contractList.add(contractTemp);
        contractTemp = TestDataFactory.createContract(1, propBasedAccount[0], propertyList[0], opportunityList[2])[0];
        contractList.add(contractTemp);
        
        database.insert(contractList);
    }
    
    @isTest
    private static void testRecreateOutgoingsJDELease(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SYSTEM_ADMINISTRATOR LIMIT 1];
        User runningUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        String oppName = Constants.JDE_LEASE + ' Test';
        List<Opportunity> opportunityList = [SELECT Id, Name 
                                             FROM Opportunity 
                                             WHERE ParentOpportunity__c != NULL
                                                AND ParentOpportunity__r.Name =: oppName];
        List<Contract__c> contractList = [SELECT Id, Name 
                                          FROM Contract__c 
                                          WHERE Opportunity__c =: opportunityList[0].Id];
        
        List<String> flowArgsList = new List<String>{
            Constants.OPPORTUNITYID + ':' + opportunityList[0].Id + ';' 
                + Constants.CONTRACTID + ':' + contractList[0].Id + ';' 
                + Constants.EFFECTIVE_DATE + ':2019-1-31'
        };
        
        system.runAs(runningUser){
            Test.startTest();
                LeaseVariationOutgoings.recreateOutgoings(flowArgsList);
            Test.stopTest();
        }
    }
    
    @isTest
    private static void testRecreateOutgoings(){
        String oppName = Constants.JDE_LEASE + ' Test';
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SYSTEM_ADMINISTRATOR LIMIT 1];
        User runningUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> opportunityList = [SELECT Id, Name 
                                             FROM Opportunity 
                                             WHERE ParentOpportunity__c != NULL
                                                AND ParentOpportunity__r.Name !=: oppName];
        List<Contract__c> contractList = [SELECT Id, Name 
                                          FROM Contract__c 
                                          WHERE Opportunity__c =: opportunityList[0].Id];
        
        List<String> flowArgsList = new List<String>{
            Constants.OPPORTUNITYID + ':' + opportunityList[0].Id + ';' 
                + Constants.CONTRACTID + ':' + contractList[0].Id + ';' 
                + Constants.EFFECTIVE_DATE + ':2020-1-31'
        };
        
        system.runAs(runningUser){
            Test.startTest();
                LeaseVariationOutgoings.recreateOutgoings(flowArgsList);
            Test.stopTest();
        }
    }
    
    @isTest
    private static void testGenerateOutoings(){
        Integer counter = 1;
        Date effectiveDate = Date.today();
        PriceBookEntry pbEntryTemp;
        Set<Id> priceBookEntryIdSet = new Set<Id>();
        List<PriceBookEntry> pbEntryList = new List<PriceBookEntry>();
        List<Product2> productList = [SELECT Id, Name, EffectiveFromDate__c, EffectiveToDate__c FROM Product2];
        List<Pricebook2> priceBookList = [SELECT Id, Name FROM Pricebook2];
        List<Opportunity> opportunityList = [SELECT Id, Name, ParentOpportunity__c, ParentOpportunity__r.Name,  
                                             ProposedRentCommencementDate__c, Property__r.ApplicableOutgoings__c,
                                             DealType__c, Space__r.BillingCategory__c, Space__r.Type__c, CurrencyIsoCode,
                                             Space__r.ApplicableOutgoings__c
                                             FROM Opportunity
                                             WHERE ParentOpportunity__c != NULL];
        
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SYSTEM_ADMINISTRATOR LIMIT 1];
        User runningUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        for(Product2 prod : productList){
            if(prod.EffectiveFromDate__c.year() == Date.today().addYears(1).year()){
                pbEntryTemp = TestDataFactory.createPriceBookEntry(1, priceBookList[0], prod)[0];
                pbEntryTemp.Pricebook2Id = priceBookList[0].Id;
                pbEntryTemp.UnitPrice = (2500 * counter++);
                pbEntryTemp.EffectiveToDate__c = prod.EffectiveToDate__c;
                pbEntryTemp.EffectiveFromDate__c = prod.EffectiveFromDate__c;
                pbEntryTemp.UseStandardPrice = false;
                
                pbEntryList.add(pbEntryTemp);
            }
        }
        
        Database.insert(pbEntryList);
        
        for(PriceBookEntry pbEntry : pbEntryList){
            priceBookEntryIdSet.add(pbEntry.Id);
        }
        
        pbEntryList = [SELECT Id, Name, Product2.OutgoingsCategory__c, Product2.DealType__c, Product2.SpaceType__c,
                       Product2.SpaceBillingCategory__c, CurrencyIsoCode, EffectiveFromDate__c, EffectiveToDate__c
                       FROM PriceBookEntry
                       WHERE Id IN: priceBookEntryIdSet];
        
        system.runAs(runningUser){
            Test.startTest();
                LeaseVariationOutgoings.generateOutoings(opportunityList[0], pbEntryList, effectiveDate);
            Test.stopTest();
        }
    }
}