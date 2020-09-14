/**
 * Save
 **/

global class PostChatterToOppRiskInvoc{
    @InvocableMethod
    public static void postChatterToOppRisk(List<Id> OpportunityLst) {
        Set<String> roleSet = new Set<String>();
        List<Id> userLstToChatter = new List<Id>();     
        List<Id> propIdLst = new List<Id>();
        List<Opportunity> oppLst = new List<Opportunity>();
        List<ChatterPostUtil.chatterNotificationWrapper> chatterLst = new List<ChatterPostUtil.chatterNotificationWrapper>();
        for(Opportunity opp : [select name,id,property__c from Opportunity where id in: OpportunityLst]){
            if(opp.property__c!=null){
                propIdLst.add(opp.property__c);
                oppLst.add(opp);
            }
        }

        for(OpportunityClause__c oppclause: [select id,ReferencedClause__c,ReferencedClause__r.RiskClauseNotifyUsers__c
        from OpportunityClause__c where opportunity__c in : OpportunityLst and 
        ReferencedClause__r.RiskClauseNotifyUsers__c != null]){
            roleSet.addall((oppclause.ReferencedClause__r.RiskClauseNotifyUsers__c).split(';'));  
        }
        
        for(propertyteam__c prop: [select id,teammember__c,role__c from propertyteam__c where property__c in: propIdLst and role__c in : roleSet and teammember__c != null AND Active__c=true AND TeamMember__r.IsActive=true]){
            userLstToChatter.add(prop.teammember__c);
            
        }
        //system.assertnotequals(userLstToChatter,userLstToChatter);
        chatterpostutil.chatterNotificationWrapper cp = chatterpostutil.ChatterPostToOppRisk(userLstToChatter,oppLst[0]);

        chatterLst.add(cp);
        if(chatterLst.size() > 0){
            ChatterPostUtil.chatterpostBulk(chatterLst);
        }       
    }
}