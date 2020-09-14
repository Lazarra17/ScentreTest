public class GetSimilarAccountController {

   /*@AuraEnabled
    public static list<Contract__c> getSimilarAccountsByCluster(Id recordId){
        List<Account> currentAccount=[Select ID,Name,Cluster__c from Account where Id=:recordId];
        List<Contract__c> contracts=getContractsByAccountCluster(recordId,currentAccount[0].Cluster__c);
        return contracts;
    }
   
    private static List<Contract__c> getContractsByAccountCluster (Id AccountID, string currentAccountCluster) {
        List<Contract__c> leases = [
            Select ID,Name,CurrentRent__c,Property__r.Name,CurrentRetailerTradingName__r.Name,Space__r.Name,LeaseEndDate__c,LeaseStartDate__c
            from Contract__c where CurrentRetailerTradingName__r.Cluster__c=:currentAccountCluster
            Order by CreatedDate Desc Limit 10
        ];
        system.debug('===leases');
        system.debug(leases);
        return leases;
    }
     @AuraEnabled
    public static list<Contract__c> getSimilarAccountsByCategory(Id recordId){
        List<Account> currentAccount=[Select ID,Name,Cluster__c,Category__c from Account where Id=:recordId];
        List<Contract__c> contractsCategory=getContractsByAccountCategory(recordId,currentAccount[0].Category__c);
        return contractsCategory;
    }
   
    private static List<Contract__c> getContractsByAccountCategory (Id AccountID, string currentAccountCategory) {
        List<Contract__c> leasesCategory = [
            Select ID,Name,CurrentRent__c,Property__r.Name,CurrentRetailerTradingName__r.Name,Space__r.Name,LeaseEndDate__c,LeaseStartDate__c,CurrentRetailerTradingName__r.Category__c
            from Contract__c where CurrentRetailerTradingName__r.Category__c=:currentAccountCategory
            Order by CreatedDate Desc Limit 10
        ];
        system.debug('===leases');
        system.debug(leasesCategory);
        return leasesCategory;
    }
     /* @AuraEnabled
    public static Decimal getAvgSQMRentByCluster(Id recordId){
        List<Account> currentAccount=[Select ID,Name,Cluster__c from Account where Id=:recordId];
        Decimal avgContractRent=getAvgSQMRentByAccountCluster(recordId,currentAccount[0].Cluster__c);
        return avgContractRent;
    }*/
        /*private static Decimal getAvgSQMRentByAccountCluster (Id AccountID, string currentAccountCluster) {
        List<AggregateResult> avgRent = [
            Select avg(CurrentRentSQM__c)
            from Contract__c where CurrentRetailerTradingName__r.Cluster__c=:currentAccountCluster
        ];
        return (Decimal)avgRent[0].get('expr0');
    }*/

    /*  @AuraEnabled
    public static Decimal getAvgRentByCluster(Id recordId){
        List<Account> currentAccount=[Select ID,Name,Cluster__c from Account where Id=:recordId];
        Decimal avgContractRent=getAvgRentByAccountCluster(recordId,currentAccount[0].Cluster__c);
        return avgContractRent;
    }   
    private static Decimal getAvgRentByAccountCluster (Id AccountID, string currentAccountCluster) {
        List<AggregateResult> avgRent = [
            Select avg(CurrentRent__c)
            from Contract__c where CurrentRetailerTradingName__r.Cluster__c=:currentAccountCluster
        ];
        return (Decimal)avgRent[0].get('expr0');
    }
      @AuraEnabled
    public static Decimal getAvgRentByCategory(Id recordId){
        List<Account> currentAccount=[Select ID,Name,Cluster__c from Account where Id=:recordId];
        Decimal avgContractRent=getAvgRentByAccountCategory(recordId,currentAccount[0].Category__c);
        return avgContractRent;
    }
   
    private static Decimal getAvgRentByAccountCategory (Id AccountID, string currentAccountCategory) {
        List<AggregateResult> avgRent = [
            Select avg(CurrentRent__c) 
            from Contract__c where CurrentRetailerTradingName__r.Category__c=:currentAccountCategory
        ];
        return (Decimal)avgRent[0].get('expr0');
    }*/
}