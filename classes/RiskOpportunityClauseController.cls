public class RiskOpportunityClauseController {
	@AuraEnabled
	public static LightningResponse getOpportunityClause(Id opportunityId){
		LightningResponse res = new LightningResponse();
		ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(RiskOpportunityClauseController.class.getName());
		List<OpportunityClause__c> opportunityClauseList = new List<OpportunityClause__c>();
		
		try{
			opportunityClauseList = [SELECT Id, Name, LeasingComment__c
									 FROM OpportunityClause__c
									 WHERE Opportunity__c =: opportunityId];
									 
			res.returnValue = JSON.serialize(opportunityClauseList);
		} catch(Exception e){
			errorHandler.createError(e);
			res.status = Constants.SUCCESS;
			res.message = e.getMessage();
		}
		
		errorHandler.save();
		
		return res;
	}
	
	@AuraEnabled
	public static Boolean canUpdate(Opportunity opportunity){
		Boolean canUpdate = false;
		
		Profile prof = DatabaseSOQLBank.getProfile(UserInfo.getProfileId());
		
		if(opportunity.OwnerId == UserInfo.getUserId() || Constants.SYSTEM_ADMINISTRATOR.equalsIgnoreCase(prof.Name)){
			canUpdate = true;
		}
		
		return canUpdate;
	}
	
	@AuraEnabled
	public static LightningResponse updateOpportunityClause(String oppClauseListJSON){
		LightningResponse res = new LightningResponse();
		ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(RiskOpportunityClauseController.class.getName());
		List<OpportunityClause__c> opportunityClauseList;
		
		if(oppClauseListJSON != '' && oppClauseListJSON != null){
			opportunityClauseList 
				= (List<OpportunityClause__c>) JSON.deserialize(oppClauseListJSON, List<OpportunityClause__c>.class);
		}
			
		if(opportunityClauseList != null && opportunityClauseList.size() > 0){
			try{
				Database.update(opportunityClauseList);
			} catch(Exception e){
				errorHandler.createError(e);
			}
		}
		
		return res;
	}
}