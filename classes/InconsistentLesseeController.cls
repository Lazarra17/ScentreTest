public class InconsistentLesseeController {
	/**
	 * @author:				Kyle Tan
	 * @desc:				query accounts
	 **/
    @AuraEnabled
    public static LightningResponse getLesseeNames(String tradingName, String lesseeName) {
        LightningResponse response = new LightningResponse();
        if(String.isNotBlank(tradingName) && String.isNotBlank(lesseeName)) {
            List<Account> accountList = new List<Account>();
            try {
                accountList = DatabaseSOQLBank.getAccountList(tradingName, lesseeName);
            } catch(Exception e) {
                response.status = Constants.FAILED;
                response.message = 'Error on searching';
            }
            if(accountList != null && accountList.size() > 0) {
                response.returnValue = JSON.serialize(accountList);
            }
        }
        return response;
    }
    
    /**
	 * @author:				Kyle Tan
	 * @desc:				get Prec Clause Rec Type Id
	 **/
    @AuraEnabled
    public static String getPrecClauseRecTypeId() {
        Map<String, Schema.RecordTypeInfo> precClauseRecTypeMap = RecordTypeUtil.getAllRecordTypesByName(Constants.PRECEDENT_CLAUSE_API);
        return precClauseRecTypeMap.get(Constants.NATIONAL_PRECEDENT_CLAUSES).getRecordTypeId();
    }
}