public class OpportunityChatterNotificationInvocable {
    @InvocableMethod
    public static void getchatternotificationdata(List<Opportunity> opportunityList) {
       if(!OpportunityList.isEmpty()&&OpportunityList.size()>0){
       List<ChatterPostUtil.chatterNotificationWrapper> chatterwrapperList = new List<ChatterPostUtil.chatterNotificationWrapper>();
           chatterwrapperList=OpportunityChatterNotificationHelper.preparedatafornotification(opportunityList);
           system.debug('chatterwrapperList*: '+ chatterwrapperList);
            if(!chatterwrapperList.isEmpty()&&chatterwrapperList.size()>0){
             ChatterPostUtil.chatterpostBulk(chatterwrapperList);
           }
       }
    }
    
    public static void getchatternotificationdataforTrigger(List<Opportunity> opportunityList) {
       if(!OpportunityList.isEmpty()&&OpportunityList.size()>0){
       List<ChatterPostUtil.chatterNotificationWrapper> chatterwrapperList = new List<ChatterPostUtil.chatterNotificationWrapper>();
           chatterwrapperList=OpportunityChatterNotificationHelper.preparedatafornotification(opportunityList);
           system.debug('chatterwrapperList*: '+ chatterwrapperList);
            if(!chatterwrapperList.isEmpty()&&chatterwrapperList.size()>0){
             ChatterPostUtil.chatterpostBulk(chatterwrapperList);
           }
       }
    }
}