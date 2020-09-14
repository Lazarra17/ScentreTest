global class GetRegLeaMgrRoleInvocFlow{
    @InvocableMethod
    public static List<String> getFinanceRoleId(List<Id> contractIDLst) {
        List<String> returnedStrLst = new List<String>();
        String roleName = constants.TEAM_ROLE_REGLEAMGR_LARS;
        String returnedStr = CaseBL.getRoleId(contractIDLst,roleName);
        if(String.isNotBlank(returnedStr)){
            returnedStrLst.add(returnedStr);
        }
        return returnedStrLst ;
    }
}