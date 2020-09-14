global class codeValidateOpportunity{
    @InvocableMethod
    public static List<string> validateRecord(List<Id> oppIds) {
        List<String> errorStr = new List<String>();
        Map<Id,List<OpportunityContactRole>> oppIdContRoleLstMap = new Map<Id,List<OpportunityContactRole>>();
        Set<String> finalApprStatusSet = new Set<String>{constants.RMAPPR_GRANTED,constants.RMRISK_APPRGRANTED, constants.PEND_FINALAPPROV,constants.FINALAPPR_REJ};
        List<String> guarantorRoles = new List<String>{constants.COMP_PERSONAL_GUARANTEES, constants.COMP_PARENT_GUARANTEES, constants.PERSONAL_GUARANTEES_FRANCHISEE};
        Map<ID, Opportunity> oppMap = new Map<ID, Opportunity>([select ApprovalStatus__c,id, NumberofGuarantors__c from opportunity where id in: oppIds]);
        for(OpportunityContactRole oppContRole : [select id,Opportunityid from OpportunityContactRole where Opportunityid  in: oppIds and role in: guarantorRoles]){
            if(oppIdContRoleLstMap.containsKey(oppContRole.Opportunityid )){
                (oppIdContRoleLstMap.get(oppContRole.Opportunityid)).add(oppContRole);
            }else{
                oppIdContRoleLstMap.put(oppContRole.Opportunityid , new List<OpportunityContactRole> {oppContRole});
            }
        }

        for (id oppid : oppIds){
            if(oppMap.containsKey(oppid)){
                if(finalApprStatusSet.contains(oppMap.get(oppid).ApprovalStatus__c)){
                    if(oppIdContRoleLstMap.containsKey(oppid)){
                        if(!(oppMap.get(oppid).NumberofGuarantors__c <= oppIdContRoleLstMap.get(oppid).size())){
                            errorStr.add(Label.noOfGuarantorErrMsg);
                            break;
                        }
                    }else if (!(!(oppIdContRoleLstMap.containsKey(oppid)) && oppMap.get(oppid).NumberofGuarantors__c <= 0)){
                        errorStr.add(Label.noOfGuarantorErrMsg);
                        break;
                    }
                }
            }
        }
        return errorStr;
    }
}