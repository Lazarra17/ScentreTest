/*
 *       author: Bry Gorospe
 *       created date: April 27, 2018
 *       description: test class for ErrorHandlerUtilTest
 *       history: April 27, 2018 Bry Gorospe - Created
 *
*/
@isTest
private class ErrorHandlerUtilTest {

    /*
     *       author: Bry Gorospe
     *       created date: April 27, 2018
     *       description: create test data
     *       history: April 27, 2018 Bry Gorospe - Created
     *
    */
    @testSetup static void setup() {
        Id ACCGroupLevel	= getRecordTypeId('ACC - Group Level');
        Id ACCThirdParty	= getRecordTypeId('ACC - Property Based');
        Id ACCPropertyBased	= getRecordTypeId('ACC - Third Party');
        Account accountRec	= new Account();
        List<Property__c> propertyList	= new List<Property__c>();
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        
        //CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(10);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        
        propertyList = TestDataFactory.createProperty(10, pricebookList[0]);
        insert propertyList;
                
        accountRec = TestDataFactory.createAccount(1, propertyList[0].id, ACCGroupLevel);
        insert accountRec;
    }

    /*
     *       author: Bry Gorospe
     *       created date: April 30, 2018
     *       description: Fetch Account record type id
     *       history: April 30, 2018 Bry Gorospe - Created
     *
    */
    private static Id getRecordTypeId (String recordTypeName) {
    Map<String, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();
    Id recTypeId = recordTypes.get(recordTypeName).getRecordTypeId();
        return recTypeId;
    }
    
    /*
     *       author: Bry Gorospe
     *       created date: April 30, 2018
     *       description: Check simpler error
     *       history: April 30, 2018 Bry Gorospe - Created
     *
    */
    @isTest static void checkSimpleError(){
        Property__c propertyRecord = [SELECT Id, Name, BankAccountAddress__c FROM Property__c WHERE Name = 'Test Property 1' LIMIT 1];
        propertyRecord.BankAccountAddress__c = 'llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll';
        try {
			update propertyRecord;
            //system.debug('propertyRecord=========>>>>>>' + propertyRecord);
        } catch (DmlException e) {
            //system.debug('fail==============>>>>' + e.getMessage());
            ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(PropertyTriggerHandler.class.getName());
			errorHandler.createError(e);
        }
    }
    
    /*
     *       author: Bry Gorospe
     *       created date: April 30, 2018
     *       description: Check error with id param
     *       history: April 30, 2018 Bry Gorospe - Created
     *
    */
    @isTest static void checkErrorWithId(){
        Property__c propertyRecord = [SELECT Id, Name FROM Property__c WHERE Name = 'Test Property 1' LIMIT 1];
        propertyRecord.BankAccountAddress__c = 'llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll';
        try {
			update propertyRecord;
            //system.debug('propertyRecord=========>>>>>>' + propertyRecord);
        } catch (DmlException e) {
            //system.debug('fail==============>>>>' + e.getMessage());
            ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(PropertyTriggerHandler.class.getName());
			errorHandler.createError(e, propertyRecord.Id);
        }
    }
    
    /*
     *       author: Bry Gorospe
     *       created date: April 30, 2018
     *       description: Check error dml
     *       history: April 30, 2018 Bry Gorospe - Created
     *
    */
    @isTest static void checkErrorDml(){
        Property__c propertyRecord = [SELECT Id, Name FROM Property__c WHERE Name = 'Test Property 1' LIMIT 1];
        propertyRecord.BankAccountAddress__c = 'llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll';
        
        Database.SaveResult rslt = Database.update(propertyRecord, false);
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(PropertyTriggerHandler.class.getName());
        if (rslt.isSuccess()) {
            //System.debug('Successfully inserted account. Account ID: ' + rslt.getId());
        }
        else {
            errorHandler.createError(rslt, rslt.getId());
        }
        
        Database.UpsertResult urslt = Database.upsert(propertyRecord, false);
        if (rslt.isSuccess()) {
            //System.debug('Successfully inserted account. Account ID: ' + urslt.getId());
        }
        else {
            errorHandler.createError(urslt, urslt.getId());
        }
        
        Database.DeleteResult drList = Database.delete(propertyRecord, false);
        if (drList.isSuccess()) {
            //System.debug('Successfully inserted account. Account ID: ' + drList.getId());
        }
        else {
            errorHandler.createError(drList, drList.getId());
        }
        
        Database.UndeleteResult udrList = Database.undelete(propertyRecord, false);
        if (drList.isSuccess()) {
            //System.debug('Successfully inserted account. Account ID: ' + udrList.getId());
        }
        else {
            errorHandler.createError(udrList, udrList.getId());
        }

        errorHandler.save();
    }
    
    /*
     *       author: Bry Gorospe
     *       created date: April 30, 2018
     *       description: Check error with string param
     *       history: April 30, 2018 Bry Gorospe - Created
     *
    */
    @isTest static void checkErrorString(){
        Property__c propertyRecord = [SELECT Id, Name, ActualRentableArea__c FROM Property__c WHERE Name = 'Test Property 1' LIMIT 1];
        propertyRecord.BankAccountAddress__c = 'llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll';
        try {
			update propertyRecord;
            //system.debug('propertyRecord=========>>>>>>' + propertyRecord);
        } catch (DmlException e) {
            //system.debug('fail==============>>>>' + e.getMessage());
            ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(PropertyTriggerHandler.class.getName());
			errorHandler.createError(e.getMessage());
        }
    }
    
    /*
     *       author: Bry Gorospe
     *       created date: April 30, 2018
     *       description: Check error with string, id param
     *       history: April 30, 2018 Bry Gorospe - Created
     *
    */
    @isTest static void checkErrorStringWithId(){
        Property__c propertyRecord = [SELECT Id, Name, ActualRentableArea__c FROM Property__c WHERE Name = 'Test Property 1' LIMIT 1];
        propertyRecord.BankAccountAddress__c = 'llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll';
        try {
			update propertyRecord;
            //system.debug('propertyRecord=========>>>>>>' + propertyRecord);
        } catch (DmlException e) {
            //system.debug('fail==============>>>>' + e.getMessage());
            ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(PropertyTriggerHandler.class.getName());
			errorHandler.createError(e.getMessage(), String.valueOf(propertyRecord.Id));
        }
    }
    
    /*
     *       author: Bry Gorospe
     *       created date: April 30, 2018
     *       description: Check error with record id, error message, error type param
     *       history: April 30, 2018 Bry Gorospe - Created
     *
    */
    @isTest static void checkErrorStringWithIdErrType(){
        Property__c propertyRecord = [SELECT Id, Name, ActualRentableArea__c FROM Property__c WHERE Name = 'Test Property 1' LIMIT 1];
        propertyRecord.BankAccountAddress__c = 'llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll';
        try {
			update propertyRecord;
            //system.debug('propertyRecord=========>>>>>>' + propertyRecord);
        } catch (DmlException e) {
            //system.debug('fail==============>>>>' + e.getMessage());
            ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(PropertyTriggerHandler.class.getName());
			errorHandler.createError(e.getMessage(), String.valueOf(propertyRecord.Id), e.getTypeName());
        }
    }
}