global class UpdateUsageClauseBatch implements Database.Batchable<sObject>{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id, Usage_Clause_Name__c, UsageClause__c FROM Opportunity';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity> scope){
        Set<Opportunity> oppsToUpdate = new Set<Opportunity>();
        List<Opportunity> oppsToUpdateList = new List<Opportunity>();
        Set<Id> oppIds = new Set<Id>();
        for(Opportunity opp : scope){
            oppIds.add(opp.Id);
        }
        
        
        List<OpportunityClause__c> oppClauses1 = [SELECT Id, Name, Opportunity__c, ClauseDetails__c, Type__c, ReferencedClause__c, ReferencedClause__r.Name FROM OpportunityClause__c WHERE Type__c = 'Usage' AND Opportunity__c IN :oppIds];
        Map<Id, List<OpportunityClause__c>> oppIdVsOppClauses = new Map<Id, List<OpportunityClause__c>>();

        for(OpportunityClause__c oppClauses : oppClauses1){
            if(oppIdVsOppClauses.containsKey(oppClauses.Opportunity__c)){
                oppIdVsOppClauses.get(oppClauses.Opportunity__c).add(oppClauses);
            }else{
                oppIdVsOppClauses.put(oppClauses.Opportunity__c, new List<OpportunityClause__c>());
                oppIdVsOppClauses.get(oppClauses.Opportunity__c).add(oppClauses);
            }
        }
        
            for(Opportunity opp : scope){
                if(!oppIdVsOppClauses.containsKey(opp.Id))
                    continue;
                
                for(OpportunityClause__c oppCl : oppIdVsOppClauses.get(opp.Id)){
                    if(oppCl.Opportunity__c == opp.Id && opp.UsageClause__c == oppCl.ClauseDetails__c){
                    		opp.Usage_Clause_Name__c = oppCl.ReferencedClause__r.Name;
                    		
                	}
                }
                oppsToUpdateList.add(opp);
            }
        
        
        if(oppsToUpdateList.size() > 0)
            Database.update(oppsToUpdateList, FALSE);
    }
    
    global void finish(Database.BatchableContext BC){}
}