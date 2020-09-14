public class OpportunityClauseBL {
    /** 
    * @Author: Lean Flores
    * @Para: Set<Id> Opportunity Id set, Opportunities to update ClauseSummary
    * @Desc: Contains SOQL queries. Use only when ClauseSummary__c update is needed
    */ 
    public static void updateOpportunityClauseSummary(Set<Id> oppIdSet) {
        Map<Id,List<String>> oppClauseSummaryMap = new Map<Id,List<String>>();
        
        for(OpportunityClause__c riskClause: [SELECT Id, Name, Opportunity__c FROM OpportunityClause__c WHERE RiskApplies__c=true AND Approved__c=false AND Opportunity__c IN:oppIdSet]) {
            if (oppClauseSummaryMap.containsKey(riskClause.Opportunity__c)) {
                oppClauseSummaryMap.get(riskClause.Opportunity__c).add(riskClause.Name);
            } else {
                oppClauseSummaryMap.put(riskClause.Opportunity__c, new List<String>{riskClause.Name});
            }
        }
        
        List<Opportunity> oppsToUpdate = [SELECT Id FROM Opportunity WHERE Id IN:oppIdSet];
        
        if (oppsToUpdate.size() > 0) {
            for (Opportunity opp : oppsToUpdate) {
                opp.ClauseSummary__c = '';
                if (oppClauseSummaryMap.containsKey(opp.Id)){
                    opp.ClauseSummary__c = String.join(oppClauseSummaryMap.get(opp.Id), ', ');
                }
                
            }
        
            Database.update(oppsToUpdate);
        }
    }
    
}