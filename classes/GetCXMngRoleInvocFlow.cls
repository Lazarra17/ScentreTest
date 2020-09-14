/*
* @author:              Kyle Tan
* @description:         method for getting CX Manager Role used in Credit Note flow
*/
global class GetCXMngRoleInvocFlow{
    @InvocableMethod
    public static List<String> getCXMngRoleId(List<Id> contractIDLst) {
        List<String> returnedStrLst = new List<String>();
        String roleName = Constants.TEAM_ROLE_CXMNG;
        String returnedStr = CaseBL.getRoleId(contractIDLst,roleName);
        if(String.isNotBlank(returnedStr)){
            returnedStrLst.add(returnedStr);
        }
        return returnedStrLst;
    }
}