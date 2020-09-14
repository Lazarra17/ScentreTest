global class GetFinanceRoleInvocFlow{
    @InvocableMethod
    public static List<String> getFinanceRoleId(List<Id> contractIDLst) {
        List<String> returnedStrLst = new List<String>();
        String roleName = constants.TEAM_ROLE_ACCREVPAYABLES; //12.06.2018 Neel updated
        String returnedStr = CaseBL.getRoleId(contractIDLst,roleName);
        if(String.isNotBlank(returnedStr)){
            returnedStrLst.add(returnedStr);
        }
        return returnedStrLst ;
    }
}