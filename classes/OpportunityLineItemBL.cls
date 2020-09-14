public class OpportunityLineItemBL {
    public static List<Opportunity> getOpportunitySecurityDeposit(List<OpportunityLineItem> opportunityLineItemList) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(OpportunityLineItemTriggerHandler.class.getName());
        List<Opportunity> opportunityToUpdateList = new List<Opportunity>();
        List<Opportunity> opportunityToAggregateList = new List<Opportunity>();
        List<AggregateResult> opportunityLineItemAggregateList = new List <AggregateResult>();
        
        for (OpportunityLineItem oliRec : opportunityLineItemList) {
            Opportunity opportunityRec = new Opportunity();
            opportunityRec.Id = oliRec.OpportunityId;
            opportunityToAggregateList.add(opportunityRec);
        }
        
        try{
            opportunityLineItemAggregateList = (DatabaseSOQLBank.getOpportunityLineItemAggregate(opportunityToAggregateList));
        } catch(Exception e) {
            opportunityLineItemAggregateList = null;
            errorHandler.createError(e);
        }
        
        for (AggregateResult aggregateRec : opportunityLineItemAggregateList) {
            Opportunity opportunityRec =  new Opportunity();
            opportunityRec.Id = String.valueof(aggregateRec.get(Constants.OPPORTUNITYID));
            if(opportunityRec.SecurityDeposit__c == 0 || opportunityRec.SecurityDeposit__c == null) {
                //opportunityRec.SecurityDeposit__c = Decimal.valueof(String.valueof(aggregateRec.get(Constants.TOTALPRICE))) / 6;
            }
            opportunityToUpdateList.add(opportunityRec);
        }
        errorHandler.save();
        return opportunityToUpdateList;
    }
    
    public static List<OpportunityLineItem> updateOppLineItems (Opportunity oppRec, List<OpportunityLineItem> oppLineItemList) {
        List<OpportunityLineItem> updatedOppLineItemList = new List<OpportunityLineItem>();
        
        if(oppRec != null && oppLineItemList.size() > 0) {
            for(OpportunityLineItem oppLineItemRec : oppLineItemList) {
                oppLineItemRec.EffectiveFromDate__c = oppRec.ProposedRentCommencementDate__c;
                updatedOppLineItemList.add(oppLineItemRec);
            }
        }
        
        return updatedOppLineItemList;
    }
}