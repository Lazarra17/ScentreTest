@IsTest
private class FeesChargesControllerTest{
    @TestSetup private static void testSetup(){
        Property__c testProperty = new Property__c();
        List<Account> accountList = new List<Account>();
        Account accountRecord = new Account();
        PriceBook2 pb = new PriceBook2 ();
        Product2 productBaseRentGross = new Product2();
        PricebookEntry pricebookEntryBaseRentGross = new PricebookEntry();
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Opportunity> opportunityList = new List<Opportunity>();
        Opportunity opportunityRecord = new Opportunity();
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        OpportunityLineItem OpportunityLineItemRecord = new OpportunityLineItem ();
        Integer loopInt = 0;
        List<Space__c> spaceList = new List<Space__c>();
        Product2 productRecord;
        //CREATE PRODUCT
        productRecord = TestDataFactory.createProduct(Constants.FEES_CHARGES, Constants.FEES_CHARGES);
        productRecord.SpaceBillingCategory__c = 'NA';
        insert productRecord;
        Id pricebookId = Test.getStandardPricebookId();
        //CREATE PROPERTY
        testProperty = TestDataFactory.createPropertyRecord();
        testProperty.PriceBook__c = pricebookId;
        database.insert(testProperty);
        //CREATE SPACE
        spaceList = TestDataFactory.createSpace(10, testProperty);
        for(Space__c spaceRec : spaceList){
            spaceRec.OccupancyStatus__c = Constants.SPACE_OCCUPANCYSTATUS_TRADING;
            spaceRec.Status__c = Constants.SPACE_STATUS_TRADING;
            spaceRec.Type__c = '2';
        }
        database.insert(spaceList);
        //CREATE ACCOUNT
        for(Integer counter = 0; counter < 5; counter++) {
            accountRecord = TestDataFactory.createAccount(counter, testProperty.Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId());
            accountList.add(accountRecord);
        }
        database.insert(accountList);
        accountList = [SELECT Id, Property__c FROM Account LIMIT 5];
        Contact contactRecord = TestDataFactory.createContact(CONSTANTS.TEST_FNAME, accountList[0]);
        insert contactRecord;
        //CREATE Products
        productBaseRentGross = TestDataFactory.createProduct(CONSTANTS.PRODUCT_BASE_RENT_GROSS, CONSTANTS.PRODUCT_FAMILY_RENT);
        database.insert(productBaseRentGross);
        productBaseRentGross = [SELECT Id FROM Product2 LIMIT 1];
        //CREATE PricebookEntry
        pricebookEntryBaseRentGross = TestDataFactory.createStandardPriceBookEntry(1, productBaseRentGross)[0];
        database.insert(pricebookEntryBaseRentGross);
        pricebookEntryBaseRentGross = [SELECT Id, Pricebook2Id FROM PricebookEntry LIMIT 1];
        //CREATE Opportunity
        opportunityList = TestDataFactory.createOpportunity(10, accountList[0]);
        for(Opportunity opp : opportunityList){
            opp.Space__c = spaceList[0].Id;
        }
        insert opportunityList;
    } 
    public static testMethod void testUpdateOpportunity() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        String feesChargesWrapJSON;
        FeesChargesController.Response res;
        Opportunity oppo = [SELECT Id, Name, Pricebook2Id FROM Opportunity LIMIT 1];
        FeesChargesController.FeesChargeParentWrapper parentWrapper;
        Product2 productBaseRentGross = new Product2();
        PricebookEntry pricebookEntryBaseRentGross = new PricebookEntry();
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        OpportunityLineItem OpportunityLineItemRecord = new OpportunityLineItem ();
        productBaseRentGross = [SELECT Id FROM Product2 LIMIT 1];
        pricebookEntryBaseRentGross = [SELECT Id, Pricebook2Id FROM PricebookEntry LIMIT 1];
        System.runAs(testUser){
            Test.startTest();
            //CREATE OpportunityLineItem
            for(Integer counter = 0; counter < 5; counter++) {
                if (counter < 5 ) {
                    opportunityLineItemRecord = TestDataFactory.createOpportunityLineItem(counter, oppo, productBaseRentGross, pricebookEntryBaseRentGross );
                }
                opportunityLineItemList.add(opportunityLineItemRecord);
            }
            insert opportunityLineItemList;
            res = FeesChargesController.getRelatedList(oppo, CONSTANTS.FEES_CHARGES);
            parentWrapper = (FeesChargesController.FeesChargeParentWrapper) JSON.deserialize(
                res.returnValue, 
                FeesChargesController.FeesChargeParentWrapper.class
            );
            Integer counter = 1;
            for(FeesChargesController.FeesChargesWrapper feeCharge : parentWrapper.feesChargesList){
                feeCharge.isActive = true;
            }
            feesChargesWrapJSON = JSON.serialize(parentWrapper.feesChargesList);
            res = FeesChargesController.saveChanges(oppo, feesChargesWrapJSON, Constants.FEES_CHARGES);
            Test.stopTest();
        }
        system.assertEquals(Constants.SUCCESS, res.status, res.message);
        parentWrapper = (FeesChargesController.FeesChargeParentWrapper) JSON.deserialize(
            res.returnValue, 
            FeesChargesController.FeesChargeParentWrapper.class
        );
        for(FeesChargesController.FeesChargesWrapper feeCharge : parentWrapper.feesChargesList){
            if(Constants.PRICEBOOKENTRY.equalsIgnoreCase(feeCharge.type)){
                system.assert(!feeCharge.isActive);
            } else if(Constants.OPPORTUNITYLINEITEM.equalsIgnoreCase(feeCharge.type)){
                system.assert(feeCharge.isActive);
            }
        }
    }
    public static testMethod void testHasEditAccess() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Opportunity oppo = [SELECT Id, Name, Pricebook2Id FROM Opportunity LIMIT 1];
        System.runAs(testUser){
            Test.startTest();
            system.assert(FeesChargesController.userHasEditAccess (oppo.id));
            Test.stopTest();
        }
    }   
    public static testMethod void testSaveChanges() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        String feesChargesWrapJSON;
        FeesChargesController.Response res;
        Opportunity oppo = [SELECT Id, Name, Pricebook2Id FROM Opportunity LIMIT 1];
        FeesChargesController.FeesChargeParentWrapper parentWrapper;
        System.runAs(testUser){
            Test.startTest();
            res = FeesChargesController.getRelatedList(oppo, CONSTANTS.FEES_CHARGES);
            parentWrapper = (FeesChargesController.FeesChargeParentWrapper) JSON.deserialize(
                res.returnValue, 
                FeesChargesController.FeesChargeParentWrapper.class
            );
            Integer counter = 0;
            for(FeesChargesController.FeesChargesWrapper feeCharge : parentWrapper.feesChargesList){
                if(Constants.PRICEBOOKENTRY.equalsIgnoreCase(feeCharge.type)){
                    feeCharge.isActive = true;
                } else if(Constants.OPPORTUNITYLINEITEM.equalsIgnoreCase(feeCharge.type)){
                    if(counter > 1){
                        feeCharge.totalPrice = 3000;
                    } else {
                        feeCharge.isActive = false;
                    }
                    counter++;
                }
            }
            feesChargesWrapJSON = JSON.serialize(parentWrapper.feesChargesList);
            res = FeesChargesController.saveChanges(oppo, feesChargesWrapJSON, Constants.FEES_CHARGES);
            Test.stopTest();
        }
        system.assertEquals(Constants.SUCCESS, res.status, res.message);
        parentWrapper = (FeesChargesController.FeesChargeParentWrapper) JSON.deserialize(
            res.returnValue, 
            FeesChargesController.FeesChargeParentWrapper.class
        );
        for(FeesChargesController.FeesChargesWrapper feeCharge : parentWrapper.feesChargesList){
            if(Constants.PRICEBOOKENTRY.equalsIgnoreCase(feeCharge.type)){
                system.assert(!feeCharge.isActive);
            } else if(Constants.OPPORTUNITYLINEITEM.equalsIgnoreCase(feeCharge.type)){
                system.assert(feeCharge.isActive);
            }
        }
    }
}