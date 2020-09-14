/*
* @author:              Neeladri Ghosh
* @description:         method for getting Commerical Retail Manager used in Credit Note flow
*/
global class GetCRMRole {
    @InvocableMethod
    public static List<String> getRevAssuRoleId(List<Id> contractIDLst) {
        List<String> returnedStrLst = new List<String>();
        String roleName = Constants.TEAM_ROLE_COMMRETMGR;
        String returnedStr = CaseBL.getRoleId(contractIDLst,roleName);
        if(String.isNotBlank(returnedStr)){
            returnedStrLst.add(returnedStr);
        }
        return returnedStrLst;
    }
}