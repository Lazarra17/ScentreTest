/*
 *      @author: James Tucay
 * 		@description:	Test Class for InconsistentLesseeController
*/
@isTest
public class InconsistentLesseeControllerTest {
	@testSetup
    private static void testSetup(){
        Property__c testProperty = new Property__c();
        List<Account> accountList = new List<Account>();
        Account accountRecord = new Account();
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        
        Id pricebookId = Test.getStandardPricebookId();
        
        //CREATE PROPERTY
        testProperty = TestDataFactory.createPropertyRecord();
        testProperty.PriceBook__c = pricebookId;
        database.insert(testProperty);

        //CREATE ACCOUNT
        accountRecord = TestDataFactory.createAccount(1, testProperty.Id, accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId());
        accountRecord.LesseeName__c = 'ABCZ';
        System.debug('accountRecord.LesseeName__c: ' + accountRecord.TradingName__c);
        accountList.add(accountRecord);
        database.insert(accountList);
        System.debug('accountList: ' + accountList);
    }
    
    
    public static testMethod void testGetLesseeNames(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        String tradingName = 'ABCZ 2';
        String lesseeName = 'SampleAccountLessee2';
        List<Account> accountList = new List<Account>();
        
        accountList = DatabaseSOQLBank.getAccountList(tradingName, lesseeName);
        System.debug('sample: ' + DatabaseSOQLBank.getAccountList(tradingName, lesseeName));
        
        System.runAs(testUser) {
            Test.startTest();
            System.debug(InconsistentLesseeController.getLesseeNames(tradingName, lesseeName));
            Test.stopTest();
        }
         System.assertEquals(true, (String.isNotBlank(tradingName) && String.isNotBlank(lesseeName)));
    }
    
    public static testMethod void testGetPrecClauseRecTypeId() {
		Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<String, Schema.RecordTypeInfo> precClauseRecTypeMap = RecordTypeUtil.getAllRecordTypesByName(Constants.PRECEDENT_CLAUSE_API);
        String tempString;
        
        System.runAs(testUser) {
            Test.startTest();
            	tempString = InconsistentLesseeController.getPrecClauseRecTypeId();
            Test.stopTest();
        }
        
        System.assertEquals(true, tempString.equals(precClauseRecTypeMap.get(Constants.NATIONAL_PRECEDENT_CLAUSES).getRecordTypeId()));
    }
}