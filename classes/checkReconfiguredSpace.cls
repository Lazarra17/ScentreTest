global class checkReconfiguredSpace{
    @InvocableMethod
    public static List<string> checkifReconfiguredSpace(List<Id> SpaceIds) {
        Boolean isConfigured = false;
         Set<Id> forecastOppSpaceIdSet = new Set<Id>{SpaceIds[0]};
        List<String> errorStr = new List<String>();
        Map<Id, List<SpaceGroup__c>> spaceGroupMap = new Map<Id, List<SpaceGroup__c>>();
        try{
            spaceGroupMap  = DatabaseSOQLBank.getSpaceGroupMap(forecastOppSpaceIdSet);
        } catch(Exception e) {
            spaceGroupMap  = null;
        }

        if(spaceGroupMap.containsKey(SpaceIds[0])) {
            isConfigured = SpaceBL.checkActiveConfigurations(spaceGroupMap.get(SpaceIds[0]), SpaceIds[0]);
        }
        if(isConfigured) {
            errorStr.add(Label.SpaceReconfig_ErrorMessage);
           }
        return errorStr;
    }
}