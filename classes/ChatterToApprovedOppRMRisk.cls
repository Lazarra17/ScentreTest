global class ChatterToApprovedOppRMRisk{
    @InvocableMethod
    public static void getFinanceRoleId(List<Id> oppIdLst) {
        Opportunity opp = [select ownerid,name,id,GMLARS__c,RMLARS__c,GMRetailAdmin__c,DirectorLARSNZDevelopment__c,CorporateLegal__c,Development_Executive__c,COO__c from 
        Opportunity where id in:oppIdLst];
        List<ChatterPostUtil.chatterNotificationWrapper> chatterLst = new List<ChatterPostUtil.chatterNotificationWrapper>();
        chatterLst.add(ChatterPostUtil.ChatterPostToApprovedOpp(opp));
        if(chatterLst.size() > 0){
            ChatterPostUtil.chatterpostBulk(chatterLst);
        }
    }
}