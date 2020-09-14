trigger OpportunityTrigger on Opportunity (after delete, after insert, after update, before delete, before insert, before update) {
    Opportunity oldOpp;
    Set<String> approvalstatusvalues=new Set<String>();
    approvalstatusvalues.add(Constants.RM_APPV_REJ);
    approvalstatusvalues.add(Constants.INI_APPV_REJ);
    approvalstatusvalues.add(Constants.RISK_APPRV_REJ);
    approvalstatusvalues.add(Constants.FINALAPPR_REJ);
    approvalstatusvalues.add(Constants.STRAPPOVALREJ);
    
    approvalstatusvalues.add(constants.INIAPPR_GRANTED);
    
    approvalstatusvalues.add(constants.RSKAPPR_GRANTED);
    approvalstatusvalues.add(constants.STRAPPOVALGRANTED);
    
    if(Trigger.isUpdate){ 
        List<Opportunity> oppList = (List<Opportunity>) Trigger.new;
        for(Opportunity opp : oppList){
            oldOpp = (Opportunity) Trigger.oldMap.get(opp.Id);
            if(opp.ApprovalStatus__c != oldOpp.ApprovalStatus__c && (Constants.FINALAPPR_GRANT.equalsIgnoreCase(opp.ApprovalStatus__c)
            ||(approvalstatusvalues.contains(opp.ApprovalStatus__c)))){
                TriggerHandler.clearBypass('OpportunityTriggerHandler');
                break;
            }
        }
    }
    TriggerFactory.createAndExecuteHandler(OpportunityTriggerHandler.class);
}