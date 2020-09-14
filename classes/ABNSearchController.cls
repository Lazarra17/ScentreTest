public class ABNSearchController {
    @AuraEnabled
    public static LightningResponse getABNDetails(String service, String searchValue){
        LightningResponse res = new LightningResponse();
        ABNLookupHelper.ABNsearchResultWrapper abnWrap;
        
        if((searchValue != null && service != null && !searchValue.containsWhitespace())){
            abnWrap = ABNLookupHelper.getABNSearchResult(service, searchValue);
            
            if(!String.isEmpty(abnWrap.message)){
                res.status = Constants.FAILED;
                res.message = abnWrap.message;
            }
        } else {
            res.status = Constants.FAILED;
            res.message = 'Invalid ABN or ACN';
        }
        
        if(Constants.SUCCESS.equalsIgnoreCase(res.status)){
            res.returnValue = JSON.serialize(abnWrap);
        }
        system.debug('RESULT: '+ res);
        return res;
    }
    
    @AuraEnabled
    public static LightningResponse getNZBNDetails(String searchValue){
        LightningResponse res = new LightningResponse();
        ABNLookupHelper.NZBNsearchResultWrapper nzbnWrap = new ABNLookupHelper.NZBNsearchResultWrapper();
        
        if(searchValue != null && !searchValue.containsWhitespace()){
            nzbnWrap = ABNLookupHelper.getNZBNSearchResult(searchValue);
        } else {
            res.status = Constants.FAILED;
            res.message = 'Invalid NZBN';
        }
        
        if(Constants.SUCCESS.equalsIgnoreCase(res.status)){
            res.returnValue = JSON.serialize(nzbnWrap);
        }
        return res;
    }
    @AuraEnabled
    public static LightningResponse isaccountvalidtoupdatedetails(String accountRecordId){
        LightningResponse res = new LightningResponse();
        Set<String> inactivecontractStatus=new Set<String>();
        inactivecontractStatus.add('Expired');
        
        if(accountRecordId!=null&&String.isNotBlank(accountRecordId)){
            Map<Id,Account> allchildaccountMap=new Map<Id,Account>([Select id from Account where parentId =: accountRecordId OR TechGrandParentId__c=: accountRecordId]); 
            Set<Id> accountIdset=new Set<Id>();
            accountIdset.addAll(allchildaccountMap.keySet());
            List<Contract__c> activecontractscount=[Select id from contract__c where Account__c in: accountIdset];
            List<AggregateResult> result=[Select count(id) totalactivecontracts from contract__c where Account__c in: accountIdset AND LeaseStatus__c NOT IN: inactivecontractStatus];
            Integer activecontractscountInt=0;
            if(!result.isEmpty()&&result.size()>0){
                activecontractscountInt=Integer.ValueOf(result[0].get('totalactivecontracts'));
            }
            
            res.returnValue=String.valueOf(activecontractscountInt);
            System.debug('INSIDE CONTROLLER '+ res.returnValue);
        }
        return res;
    }
}