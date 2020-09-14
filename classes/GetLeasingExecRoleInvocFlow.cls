/*
* @author:              Kyle Tan
* @description:         method for getting Leasing Executive Role used in Credit Note flow
*/
global class GetLeasingExecRoleInvocFlow{
    @InvocableMethod
    public static List<String> getLeasingExecRoleId(List<Id> contractIDLst) {
        List<String> returnedStrLst = new List<String>();
        String roleName = Constants.TEAM_ROLE_LEAS_EXEC;
        String returnedStr = CaseBL.getRoleId(contractIDLst,roleName);
        if(String.isNotBlank(returnedStr)){
            returnedStrLst.add(returnedStr);
        }
        return returnedStrLst;
    }
}