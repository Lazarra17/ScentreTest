global class GetTenCoordRoleInvocFlow{
    @InvocableMethod
    public static List<String> getFinanceRoleId(List<Id> contractIDLst) {
        List<String> returnedStrLst = new List<String>();
        String roleName = constants.TEAM_ROLE_TENCOORD;
        String returnedStr = CaseBL.getRoleId(contractIDLst,roleName);
        if(String.isNotBlank(returnedStr)){
            returnedStrLst.add(returnedStr);
        }
        return returnedStrLst ;
    }
}