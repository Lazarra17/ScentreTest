global class ChatterForRiskApprovalGrantedOpp {
	@InvocableMethod
    public static void chatterPostToRetailAdmin(List<Id> oppIds) {
                
        List<ChatterPostUtil.chatterNotificationWrapper> chatterLst = ChatterPostUtil.ChatterPostRiskApprovedOpp(oppIds);
        
        if(chatterLst.size() > 0){
            ChatterPostUtil.chatterpostBulk(chatterLst);
        }

    }
}