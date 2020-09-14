/*
* @author:              Sidney Garcia
* @description:         Apex Controller for OpportunityUnlockUpdateField.cmp
*/

public without sharing class OpportunityUnlockUpdateController {
    
    public class OpportunityPicklistsValuesWrapper{
        @AuraEnabled public List<String> opportunityStages = new List<String>();
        @AuraEnabled public List<String> reasonPicklist = new List<String>();
    }
    
    public class OpportunityStageAndLockStatusWrapper{
        @AuraEnabled public Boolean isUnlocked;
        @AuraEnabled public String stageName;
        @AuraEnabled public Boolean lockedOpp;
    }
    
    public class OpportunityWrapper{
       @AuraEnabled public Boolean isSuccess;
       @AuraEnabled public Boolean lockedOpp;
   } 
    
  /*  @AuraEnabled
    public static boolean lockOpportunity(Id oppId){
        List<Id> oppList = new List<Id>();
        oppList.add(oppId);
        Approval.LockResult[] lrList = Approval.lock(oppList, false);
        return true;
    } */
    
    @AuraEnabled
   public static LightningResponse unlockOpportunityRec(Id opportunityId, String stageName){
       /*System.debug('Inside After Save');
       List<Id> oppList = new List<Id>();
       Opportunity opp = new Opportunity();
       opp.id = opportunityId;
       oppList.add(opportunityId);
       Approval.UnlockResult[] unlockedRersult = Approval.unlock(oppList);
       system.debug('unlockedRersult: '+unlockedRersult);
       system.debug('IsLocked: '+Approval.isLocked(opp.Id));
       update opp;
       return true;*/
       
       LightningResponse response =new LightningResponse();
       ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(OpportunityUnlockUpdateController.class.getName());
       OpportunityWrapper wrapper = new OpportunityWrapper();
       
       wrapper.lockedOpp = Approval.isLocked(opportunityId);
       
       if (wrapper.lockedOpp) {
           try{
               Approval.UnlockResult unlockRes = Approval.Unlock(opportunityId);
               wrapper.isSuccess = unlockRes.isSuccess();
               
           } catch (System.Exception e) {
               response.status = Constants.FAILED;
               response.message = e.getMessage();
               errorHandler.createError(e);
           }          
       }
       
       response.returnValue = JSON.serialize(wrapper);
       errorHandler.save();
       return response;
   }
    
    @AuraEnabled
    public static LightningResponse getPicklistValues(){
        LightningResponse response =new LightningResponse(); 
        OpportunityPicklistsValuesWrapper wrapper = new OpportunityPicklistsValuesWrapper();
        //get stages
        Schema.DescribeFieldResult fieldResultStages = Opportunity.StageName.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResultStages.getPicklistValues();
        for(Schema.PicklistEntry f : ple)
        {	
            System.debug('Data=> '+ f);
            wrapper.opportunityStages.add(f.getValue());
        }
        System.debug('Data=> '+ wrapper.opportunityStages);
        //get reason picklist
        Schema.DescribeFieldResult fieldResultReason = Opportunity.ReasonForClosure__c.getDescribe();
        List<Schema.PicklistEntry> ple2 = fieldResultReason.getPicklistValues();
        for( Schema.PicklistEntry f : ple2)
        {
            System.debug('Data2=> '+ f);
            wrapper.reasonPicklist.add(f.getValue());
        }
        System.debug('Data2=> '+ wrapper.reasonPicklist);
        response.returnValue = JSON.serialize(wrapper);
        System.debug('Data2=> '+ response.returnValue);
        return response;
    }   
}