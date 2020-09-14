/*
* @author:              Kyle Tan
* @description:         method for getting Revenue Assurance Role used in Credit Note flow
*/
global class GetRevAssuRoleInvocFlow{
    @InvocableMethod
    public static List<String> getRevAssuRoleId(List<Id> contractIDLst) {
        List<String> returnedStrLst = new List<String>();
        String roleName = Constants.TEAM_ROLE_REVASSU_ADMIN;
        String returnedStr = CaseBL.getRoleId(contractIDLst,roleName);
        if(String.isNotBlank(returnedStr)){
            returnedStrLst.add(returnedStr);
        }
        return returnedStrLst;
    }
}