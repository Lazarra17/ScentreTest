/*
*       author: Miguel Paguio
*       created date: May 9, 2018
*       description: Test class for SpaceOccupancyUpdateHelper
*       history: May 9, 2018 Miguel Paguio- Created
*
*/

@isTest
public class SpaceOccupancyUpdateHelperTest {
    
    @TestSetup 
    private static void testSetup() {
        List<Space__c> spaceList= new List<Space__c>();
        List<Account> accountList = new List<Account>();
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        List<Contract__c> contractList = new List<Contract__c>();
        List<Property__c> propertyList = new List<Property__c>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<SpaceBudgetAndForecast__c> spaceBudgetCreateRec = new List<SpaceBudgetAndForecast__c>();
        Map<String, Schema.RecordTypeInfo> contractRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName('Contract__c');
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        
        //CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(10);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(10, pricebookList[0]);
        database.insert(propertyList);
        
        //CREATE ACCOUNT
        accountList.addAll(TestDataFactory.createAccountBulk(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(accountList);
        
        //CREATE SPACE
        spaceList = TestDataFactory.createSpace(15, propertyList[0]);
        // VACANCY
        spaceList[0].Status__c = Constants.SPACE_STATUS_CLOSED;
        
        //LBNT
        spaceList[1].Status__c = Constants.SPACE_STATUS_NEW;
        
        //LBNT
        spaceList[2].Status__c = Constants.SPACE_STATUS_ATRISK;
        
        //HELD VACANCIES
        spaceList[3].Status__c = Constants.SPACE_STATUS_HELD;
        spaceList[3].HeldVacantSpace__c = true;
        
        //PROJECT SHOPS
        spaceList[4].Status__c = Constants.SPACE_STATUS_PROJECT;
        
        //EXPIRING LEASES
        spaceList[5].Status__c = Constants.SPACE_STATUS_TRADING;
        //spaceList[5].CurrentLeaseExpiryDate__c = Date.today();
        
        //HOLDOVERS
        spaceList[6].Status__c = Constants.SPACE_STATUS_TRADING;
        //spaceList[6].CurrentLeaseExpiryDate__c = Date.today().addDays(-1);
        
        // TRADING NEW RETAILERS
        spaceList[7].Status__c = Constants.SPACE_STATUS_TRADING;
        //spaceList[7].CurrentLeaseExpiryDate__c = Date.today().addYears(1);
        //spaceList[7].LatestAchievedOpportunity__c = true;
        
        // TRADING NEW RETAILERS
        spaceList[8].Status__c = Constants.SPACE_STATUS_TRADING;
        
        database.insert(spaceList);
        
        //CREATE OPPORTUNITY
        accountList = [SELECT Id, Property__c FROM Account LIMIT 1];
        opportunityList = TestDataFactory.createOpportunity(15, accountList[0], propertyList[0]);
        
        for(Integer counter = 0; counter < opportunityList.size(); counter++){
            opportunityList[counter].Space__c = spaceList[counter].Id;
            opportunityList[counter].CurrentLeaseVirtualVacancy__c = 'No';
        }
        
        opportunityList[0].Type = Constants.OPPTY_STAGENAME_NEWRETAILER;
        opportunityList[2].CurrentLeaseVirtualVacancy__c = null;
        opportunityList[7].Type = Constants.OPPTY_STAGENAME_NEWRETAILER;
        opportunityList[8].Type = Constants.OPPTY_STAGENAME_NEWRETAILER;
        
        database.insert(opportunityList);
        
        //CREATE CONTRACT
        contractList = TestDataFactory.createContract(15, accountList[0], propertyList[0]);
        contractList[0].Opportunity__c = opportunityList[0].Id;
        contractList[1].Opportunity__c = opportunityList[9].Id;
        contractList[2].Opportunity__c = opportunityList[2].Id;
        contractList[3].Opportunity__c = opportunityList[3].Id;
        contractList[4].Opportunity__c = opportunityList[4].Id;
        contractList[5].Opportunity__c = opportunityList[5].Id;
        contractList[6].Opportunity__c = opportunityList[6].Id;
        contractList[7].Opportunity__c = opportunityList[7].Id;
        contractList[8].Opportunity__c = opportunityList[8].Id;
        contractList[9].Opportunity__c = opportunityList[1].Id;
        contractList[10].Opportunity__c = opportunityList[10].Id;
        contractList[11].Opportunity__c = opportunityList[11].Id;
        contractList[12].Opportunity__c = opportunityList[12].Id;
        
        for(Contract__c con : contractList){
            con.RecordTypeId = contractRecordTypeMapByName.get('CON - Retail Contract').getRecordTypeId();
            con.LeaseStatus__c = 'A';
        }
        
        contractList[5].LeaseEndDate__c = Date.today();
        contractList[6].LeaseEndDate__c = Date.today().addDays(-1);
        contractList[7].LeaseEndDate__c = Date.today().addYears(1);
        contractList[8].LeaseEndDate__c = Date.today().addYears(1);
        
        Database.insert(contractList);
        
        //UPDATE SPACE
        for(Integer counter = 0; counter < opportunityList.size(); counter++){
            spaceList[counter].CurrentLease__c = contractList[counter].Id;
            spaceList[counter].LatestAchievedOpportunity__c = opportunityList[counter].Id;
            spaceList[counter].CurrentForecastedOpportunity__c = opportunityList[counter].Id;
        }
        
        database.update(spaceList);
        
        //CREATE SPACE BUDGET AND FORECAST RECORD
        spaceBudgetCreateRec = TestDataFactory.createSpaceBudget(15, spaceList[0]);
        Database.insert(spaceBudgetCreateRec);      
    }
    
    @isTest
    private static void checkStatus() {
        Space__c spaceTemp;
        Set<Id> spaceIdSet = new Set<Id>();
        List<Space__c> spaceList = new List<Space__c>();
        Map<Id, Space__c> oldSpaceMap;
        Map<Id, Space__c> spaceMap = new Map<Id, Space__c>();
        
        oldSpaceMap = new Map<Id, Space__c>([SELECT Id, CurrentLease__c, HeldVacantSpace__c, Status__c, OccupancyStatus__c, 
                                                LatestAchievedOpportunity__c, CurrentLeaseExpiryDate__c,
                                                CurrentForecastedOpportunity__r.CurrentLeaseVirtualVacancy__c, 
                                                LatestBudget__r.PromotionalAllowance__c, CurrentForecastedOpportunity__c,
                                                LatestForecast__r.CapitalSiteEstablishment__c
                                             FROM Space__c]);
                                             
        spaceList = oldSpaceMap.values();
                     
        for(Space__c spa : oldSpaceMap.values()){
            spaceIdSet.add(spa.Id);
        }
                     
        Test.startTest();
            spaceMap = SpaceOccupancyUpdateHelper.updateOccupancyStatus(spaceIdSet, oldSpaceMap.values(), oldSpaceMap);
        Test.stopTest();
        
        for(Integer counter = 0; counter < spaceList.size(); counter++){
            spaceTemp = spaceList[counter];
            
            if(spaceMap.containsKey(spaceTemp.Id)){
                spaceTemp = spaceMap.get(spaceTemp.Id);
                
                if(counter == 0){
                    system.assertEquals(Constants.SPACE_OCCUPANCYSTATUS_VACANCY, spaceTemp.OccupancyStatus__c);
                } else if(counter == 1){
                    system.assertEquals(Constants.SPACE_OCCUPANCYSTATUS_LBNT, spaceTemp.OccupancyStatus__c);
                }  else if(counter == 2){
                    system.assertEquals(Constants.SPACE_OCCUPANCYSTATUS_LEASINGISSUES, spaceTemp.OccupancyStatus__c);
                } else if(counter == 3){
                    system.assertEquals(Constants.SPACE_OCCUPANCYSTATUS_HELDVACANCIES, spaceTemp.OccupancyStatus__c);
                } else if(counter == 4){
                    system.assertEquals(Constants.SPACE_OCCUPANCYSTATUS_PROJECTSHOPS, spaceTemp.OccupancyStatus__c);
                } else if(counter == 5){
                    system.assertEquals(Constants.SPACE_OCCUPANCYSTATUS_EXPAIRINGLEASES, spaceTemp.OccupancyStatus__c);
                } else if(counter == 6){
                    system.assertEquals(Constants.SPACE_OCCUPANCYSTATUS_HOLDOVERS, spaceTemp.OccupancyStatus__c);
                }/* else if(counter == 7){
                    system.assertEquals(Constants.SPACE_OCCUPANCYSTATUS_LEASINGISSUES, spaceTemp.OccupancyStatus__c);
                }*/
            }
        }
    }
}