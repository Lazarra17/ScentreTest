public class ABNNameSearchController {
    
    public class ABNNameSearchWrapper{
        @AuraEnabled public ABNLookupHelper.ABNNameSearchResultWrapper abnTradingNameSearch=new ABNLookupHelper.ABNNameSearchResultWrapper();
        @AuraEnabled public ABNLookupHelper.ABNNameSearchResultWrapper abnLesseeNameSearch=new ABNLookupHelper.ABNNameSearchResultWrapper();
    }
    public class NZBNNameSearchWrapper{
        @AuraEnabled public List<ABNLookupHelper.nzbnTableColumn> nzbnTradingNameSearch=new List<ABNLookupHelper.nzbnTableColumn>();
        @AuraEnabled public List<ABNLookupHelper.nzbnTableColumn> nzbnLesseeNameSearch=new List<ABNLookupHelper.nzbnTableColumn>();
    }
    /**
    * @author:				Kyle Tan
    * @desc:				web service call to search ABN by trading name and lessee name
    **/
    @AuraEnabled
    public static LightningResponse getABNNameList(String tradingName,String lesseeName){
        LightningResponse response = new LightningResponse();
        ABNNameSearchWrapper wrapper = new ABNNameSearchWrapper();
        if(tradingName != null){
            try {
                List<ABNLookupHelper.ABNNameWrapper> wrapperRecordNames = new List<ABNLookupHelper.ABNNameWrapper>();
                ABNLookupHelper.ABNNameSearchResultWrapper abnTradingNameSearchTemp = ABNLookupHelper.getABNNameSearchResult(tradingName);
                Integer counter = 0;
                for(ABNLookupHelper.ABNNameWrapper tempWrapperRecord:abnTradingNameSearchTemp.Names) {
                    if(counter < 10) {
                        if(Constants.TRADING_NAME.equalsIgnoreCase(tempWrapperRecord.NameType) || Constants.BUSINESS_NAME.equalsIgnoreCase(tempWrapperRecord.NameType)) {
                            wrapperRecordNames.add(tempWrapperRecord);
                            counter++;
                        }
                    } else {
                        break;
                    }
                }
                abnTradingNameSearchTemp.Names = wrapperRecordNames;
                wrapper.abnTradingNameSearch = abnTradingNameSearchTemp;
            } catch(Exception e) {
                response.status = Constants.FAILED;
                response.message = 'Invalid Search Key';
            }
        }
        if(lesseeName != null){
            try {
                List<ABNLookupHelper.ABNNameWrapper> wrapperRecordNames = new List<ABNLookupHelper.ABNNameWrapper>();
                ABNLookupHelper.ABNNameSearchResultWrapper abnLesseeNameSearchTemp = ABNLookupHelper.getABNNameSearchResult(lesseeName);
                Integer counter = 0;
                for(ABNLookupHelper.ABNNameWrapper tempWrapperRecord:abnLesseeNameSearchTemp.Names) {
                    if(counter < 10) {
                        if(Constants.ENTITY_NAME.equalsIgnoreCase(tempWrapperRecord.NameType)) {
                            wrapperRecordNames.add(tempWrapperRecord);
                            counter++;
                        }
                    } else {
                        break;
                    }
                }
                abnLesseeNameSearchTemp.Names = wrapperRecordNames;
                wrapper.abnLesseeNameSearch = abnLesseeNameSearchTemp;
                //wrapper.abnLesseeNameSearch = ABNLookupHelper.getABNNameSearchResult(lesseeName);
            } catch(Exception e) {
                response.status = Constants.FAILED;
                response.message = 'Invalid Search Key';
            }
        }
        if(Constants.SUCCESS.equalsIgnoreCase(response.status)){
            if(wrapper.abnTradingNameSearch != null || wrapper.abnLesseeNameSearch != null) {
                response.returnValue = JSON.serialize(wrapper);
            }
        }
        System.debug('Response 1' + response);
        return response;
    }
    /**
    * @author:				Kyle Tan
    * @desc:				web service call to search NZBN by name
    **/
    @AuraEnabled
    public static LightningResponse getNZBNNameList(String tradingName,String lesseeName){
        LightningResponse response = new LightningResponse();
        NZBNNameSearchWrapper wrapper = new NZBNNameSearchWrapper();
        ABNLookupHelper.NZBNNameSearchResultWrapper nzbnTradingNameList  = new ABNLookupHelper.NZBNNameSearchResultWrapper();
        ABNLookupHelper.NZBNNameSearchResultWrapper nzbnLesseeNameList  = new ABNLookupHelper.NZBNNameSearchResultWrapper();
        
        if(tradingName != null){
            nzbnTradingNameList = ABNLookupHelper.getNZBNNameSearchResult(tradingName);
        } else {
            response.status = Constants.FAILED;
            response.message = 'Invalid Search Key';
        }
        if(lesseeName != null){
            nzbnLesseeNameList = ABNLookupHelper.getNZBNNameSearchResult(lesseeName);
        } else {
            response.status = Constants.FAILED;
            response.message = 'Invalid Search Key';
        }
        system.debug('nzbnTradingNameList-->' + nzbnTradingNameList);
        system.debug('nzbnLesseeNameList-->' + nzbnLesseeNameList);
        if(nzbnLesseeNameList != null || nzbnTradingNameList != null){
            if(nzbnTradingNameList.items != null && nzbnTradingNameList.items.size() > 0) {
                ABNLookupHelper.nzbnTableColumn tempRec = new ABNLookupHelper.nzbnTableColumn();
                for(ABNLookupHelper.NZBNItemNamesWrapper nzbnItemRec : nzbnTradingNameList.items) {
                    tempRec = new ABNLookupHelper.nzbnTableColumn();
                    tempRec.nzbn = nzbnItemRec.nzbn;
                    tempRec.entityName = nzbnItemRec.entityName;
                    tempRec.entityType = nzbnItemRec.entityType.name;
                    wrapper.nzbnTradingNameSearch.add(tempRec);
                }
            }
            if(nzbnLesseeNameList.items != null && nzbnLesseeNameList.items.size() > 0) {
                ABNLookupHelper.nzbnTableColumn tempRec = new ABNLookupHelper.nzbnTableColumn();
                for(ABNLookupHelper.NZBNItemNamesWrapper nzbnItemRec : nzbnLesseeNameList.items) {
                    tempRec = new ABNLookupHelper.nzbnTableColumn();
                    tempRec.nzbn = nzbnItemRec.nzbn;
                    tempRec.entityName = nzbnItemRec.entityName;
                    tempRec.entityType = nzbnItemRec.entityType.name;
                    wrapper.nzbnLesseeNameSearch.add(tempRec);
                }
            }
            system.debug('wrapper-->' + wrapper);
            if(wrapper.nzbnTradingNameSearch != null || wrapper.nzbnLesseeNameSearch != null) {
                response.returnValue = JSON.serialize(wrapper);
            }
        }
        System.debug('Response ' + response);
        return response;
    }
    
    /**
     * @author:				Kyle Tan
     * @desc:				checks for active contracts linked to the account record
     **/
    @AuraEnabled
    public static LightningResponse isaccountvalidtoupdatedetails(String accountRecordId) {
        return ABNSearchController.isaccountvalidtoupdatedetails(accountRecordId);
    } 
}