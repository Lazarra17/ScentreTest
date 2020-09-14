public class HighRiskOpportunityClauseUtility{
    public static Map<Id, Map<Id, List<OpportunityClause__c>>> getOppClausePerProperty(List<OpportunityClause__c> oppClauseList){
        Map<Id, List<OpportunityClause__c>> oppIdOppClauseListMap = new Map<Id, List<OpportunityClause__c>>();
        Map<Id, Map<Id, List<OpportunityClause__c>>> propIdOppIdOppClauseListMap = new Map<Id, Map<Id, List<OpportunityClause__c>>>();
        
        for(OpportunityClause__c oppClause : oppClauseList){
            system.debug('oppClause : ' + oppClause);
            
            if(propIdOppIdOppClauseListMap.containsKey(oppClause.Opportunity__r.Property__c)){
                oppIdOppClauseListMap = propIdOppIdOppClauseListMap.get(oppClause.Opportunity__r.Property__c);
            } else {
                oppIdOppClauseListMap = new Map<Id, List<OpportunityClause__c>>();
            }
            
            if(oppIdOppClauseListMap.containsKey(oppClause.Opportunity__c)){
                oppIdOppClauseListMap.get(oppClause.Opportunity__c).add(oppClause);
            } else {
                oppIdOppClauseListMap.put(
                    oppClause.Opportunity__c, new List<OpportunityClause__c>{
                        oppClause
                            }
                );
            }
            
            propIdOppIdOppClauseListMap.put(oppClause.Opportunity__r.Property__c, oppIdOppClauseListMap);
        }
        
        return propIdOppIdOppClauseListMap;
    }
    
    public static Opportunity countRCA(Opportunity opportunity, Map<Id, List<OpportunityClause__c>> oppIdOppClauseListMap){
        Integer rcaCount = 0;
        Opportunity oppTemp;
        
        for(Id oppId : oppIdOppClauseListMap.keySet()){
            if(opportunity.Id != oppId && oppIdOppClauseListMap.containskey(oppId) && oppIdOppClauseListMap.get(oppId).size() > 0){
                oppTemp = oppIdOppClauseListMap.get(oppId)[0].Opportunity__r;
                
                system.debug('oppTemp : ' + oppTemp);
                
                if(opportunity.Category__c != null && opportunity.Category__c.equalsIgnoreCase(oppTemp.Account.Category__c)){
                    rcaCount += oppIdOppClauseListMap.get(oppId).size();
                }
            }
        }
        
        system.debug('INSIDE  RCA: '+ rcaCount);
        
        if(opportunity.Tech_SpaceType__c != Constants.STOREROOM){
            opportunity.NoofRCA__c = rcaCount;
        }
        return opportunity;
    }
}