/*
* author: Alyana Navarro
* created date: October 10, 2018
* description: Test class for TriggerFactory
*/

@isTest
public class TriggerFactoryTest {
    
    @isTest
    private static void testCreateAndExecuteHandler() {
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        List<Property__c> propertyList = new List<Property__c>();
        
        //CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(10);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(10, pricebookList[0]);
        database.insert(propertyList);
        
        //UPDATE PROPERTY
        for(Property__c prop : propertyList){
            prop.PropertyStatus__c = 'Inactive';
        }
        TriggerHandler.clearBypass('PropertyTriggerHandler');
        database.update(propertyList);
        
        //DELETE PROPERTY
        TriggerHandler.clearBypass('PropertyTriggerHandler');
        database.delete(propertyList);
    }
}