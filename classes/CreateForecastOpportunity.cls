public class CreateForecastOpportunity {
    
    public static void checkSpaceCriteria(List<Space__c> spaceList){
        Map<Id, List<Account>> propertyIdVsAccount = new Map<Id, List<Account>>();
        List<Opportunity> forecastOpptysToCreate = new List<Opportunity>();
        Set<Id> propertyId = new Set<Id>();
        Set<Id> spaceIds = new Set<Id>();
        
        List<User> migrationUser = DatabaseSOQLBank.getdataMigrationUser();
        
        for(Space__c spc : spaceList){
            spaceIds.add(spc.Id);
            propertyId.add(spc.Property__c);                
        }
        
        for(Account forecastPropertyAccs : DatabaseSOQLBank.getForecastAccountForProperty(propertyId)){
            if(propertyIdVsAccount.containsKey(forecastPropertyAccs.Property__c)){
                propertyIdVsAccount.get(forecastPropertyAccs.Property__c).add(forecastPropertyAccs);
            }else{
                propertyIdVsAccount.put(forecastPropertyAccs.Property__c, new List<Account>());
                propertyIdVsAccount.get(forecastPropertyAccs.Property__c).add(forecastPropertyAccs);
            }
        }
        
        Id oppCommId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Commercial Leasing').getRecordTypeId();
        Id oppRetId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Retail Leasing').getRecordTypeId();
        
        for(Space__c spc : spaceList){
            if(spc.Status__c == Constants.SPACE_STATUS_INACTIVE || spc.Status__c == Constants.SPACE_STATUS_HELD){
                continue;
            }else if(spc.Type__c != '1' && spc.Type__c != '2' && spc.Type__c != '3'){
                continue;
            }else{
                Id accountId;
                
                System.debug('propertyIdVsAccount: '+propertyIdVsAccount);
                if(propertyIdVsAccount.size() == 0 || propertyIdVsAccount.get(spc.Property__c).size() == 0)
                    continue;
                
                if(propertyIdVsAccount.get(spc.Property__c).size() == 1){
                    accountId = propertyIdVsAccount.get(spc.Property__c)[0].Id;
                }else if(propertyIdVsAccount.get(spc.Property__c).size() > 1){
                    for(Account acc : propertyIdVsAccount.get(spc.Property__c)){
                        if(acc.Property__r.PropertyOwnershipType__c == Constants.MANAGED)
                            accountId = acc.Id;
                    }
                }
                
                Opportunity newForecastOppty = new Opportunity();
                newForecastOppty.Name = 'Test 1';
                newForecastOppty.Space__c = spc.Id;
                newForecastOppty.Property__c = spc.Property__c;
                newForecastOppty.AccountId = accountId;
                newForecastOppty.StageName = Constants.UNDERSTAND_NEGOTIATE;
                newForecastOppty.DealType__c = Constants.DEALTYPE_SEMI_GROSS;
                newForecastOppty.BestBet__c = FALSE;
                newForecastOppty.CloseDate = Date.newInstance(Date.today().year(), 12, 31);
                newForecastOppty.ProposedHandoverDate__c = Date.newInstance(Date.today().year(), 12, 31);
                newForecastOppty.OwnerId = migrationUser[0].Id;
                newForecastOppty.Created_from_Space_Creation__c = TRUE;
                
                if(spc.Type__c == '1' || spc.Type__c == '2')
                    newForecastOppty.RecordTypeId = oppRetId;
                else if(spc.Type__c == '3')
                    newForecastOppty.RecordTypeId = oppCommId;
                
                forecastOpptysToCreate.add(newForecastOppty);                
            }
        }
        
        if(forecastOpptysToCreate.size() > 0)
            Database.insert(forecastOpptysToCreate, FALSE);
    }
}