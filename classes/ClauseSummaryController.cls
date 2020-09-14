public class ClauseSummaryController {
    public class clauseDetailsWrapper {
        @AuraEnabled public List<OpportunityClause__c> opportunityClauseList = new List<OpportunityClause__c>();
    }
    
    @AuraEnabled
    public static LightningResponse getSelectedClauses(Id oppId){
        LightningResponse response =new LightningResponse(); 
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(ClauseSummaryController.class.getName());
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>();
        clauseDetailsWrapper clauseList = new clauseDetailsWrapper();
        try{
            oppClauseList = DatabaseSOQLBank.getSelectedClauseOfOpportunity(oppId);
        }
        catch(Exception e){
            response.status = Constants.FAILED;
            response.message = e.getMessage();
            errorHandler.createError(e);
        }
        if(oppClauseList != null || oppClauseList.size() > 0){
            clauseList.opportunityClauseList.addAll(oppClauseList);
            response.status = CONSTANTS.SUCCESS;
            response.returnValue = JSON.serialize(clauseList);
        }
        
        return response;
    }
}