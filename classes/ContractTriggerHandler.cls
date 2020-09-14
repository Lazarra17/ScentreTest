/**
* Class ContractTriggerHandler
*
* Trigger Handler for the Contract SObject. This class implements the ITrigger
* interface to help ensure the trigger code is bulkified and all in one place.
*/
public without sharing class ContractTriggerHandler extends TriggerHandler
implements ITrigger{
    public List<Contract__c> contracts = new List<Contract__c>();
    public List<Contract__c> newContract = new List<Contract__c>();
    public Map<Id, PrecedentClause__c> accIds = new Map<Id, PrecedentClause__c>();
    public Map<Id, Id> acctVsParentAcc = new Map<Id, Id>();
	public Map<Id, Opportunity> associatedOpptys = new Map<Id, Opportunity>();
    
    // Constructor
    public ContractTriggerHandler()
    {
    }
    
    /**
    * bulkBefore
    *
    * This method is called prior to execution of a BEFORE trigger. Use this to cache
    * any data required into maps prior execution of the trigger.
    */
    
    public void bulkBefore(){   
        newContract = (List<Contract__c>) Trigger.new;
        Set<Id> contractIds = new Set<Id>();
        Set<Id> contratcAccIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        
        for(Contract__c cont : newContract){
            contractIds.add(cont.Id);
            contratcAccIds.add(cont.Account__c);
            oppIds.add(cont.Opportunity__c);
        }
        
        associatedOpptys = new Map<Id, Opportunity>([SELECT Id, AccountId, Account.ParentId, Usage_Clause_Name__c, UsageClause__c FROM Opportunity WHERE Id IN :oppIds]);
		
		Map<Id, Account> associatedAccs = new Map<Id, Account>([SELECT Id, ParentId FROM Account WHERE Id IN :contratcAccIds]);
        
        Set<Id> parentAccIds = new Set<Id>();
        
        for(Opportunity opp : associatedOpptys.values()){
            parentAccIds.add(opp.Account.ParentId);
            acctVsParentAcc.put(opp.AccountId, opp.Account.ParentId);
        }
        
        List<PrecedentClause__c> precendenceClu = [SELECT Id, Name, Type__c, Account__c, Description__c 
                                                  	FROM PrecedentClause__c 
                                                   	WHERE Account__c IN :parentAccIds 
                                                   	AND Type__c = 'Usage' 
                                                   	AND Status__c = 'Active'
                                                  ];
        for(PrecedentClause__c pC : precendenceClu){
            accIds.put(pC.Account__c, pC);
        }
    }
    
    public void bulkAfter(){

    }
    
    public void beforeInsert(SObject so){
        Contract__c contract = (Contract__c) so;
        
        if(associatedOpptys.containsKey(contract.Opportunity__c)){
            if(associatedOpptys.get(contract.Opportunity__c).UsageClause__c != '' && associatedOpptys.get(contract.Opportunity__c).UsageClause__c != NULL){
                contract.UsageClauseDetails__c = associatedOpptys.get(contract.Opportunity__c).UsageClause__c;
                contract.UsageClauseName__c = associatedOpptys.get(contract.Opportunity__c).Usage_Clause_Name__c;
            }else if(acctVsParentAcc.containsKey(contract.Account__c)){
                if(accIds.containsKey(acctVsParentAcc.get(contract.Account__c))){
                	contract.UsageClauseDetails__c = accIds.get(acctVsParentAcc.get(contract.Account__c)).Description__c;
                	contract.UsageClauseName__c = accIds.get(acctVsParentAcc.get(contract.Account__c)).Name;    
                }
                
            }
                
        }else if(contract.Account__c != NULL && acctVsParentAcc.containsKey(contract.Account__c)){
            if(accIds.containsKey(acctVsParentAcc.get(contract.Account__c))){
            	contract.UsageClauseDetails__c = accIds.get(acctVsParentAcc.get(contract.Account__c)).Description__c;
            	contract.UsageClauseName__c = accIds.get(acctVsParentAcc.get(contract.Account__c)).Name;    
            }
        }
    }
    
    public void beforeUpdate(SObject oldSo, SObject so){
        Contract__c contract = (Contract__c) so;
        Contract__c oldContract = (Contract__c) oldSo;
        if (contract.LeaseStatus__c != 'E' && oldContract.LeaseStatus__c == 'F' && contract.LeaseStatus__c != oldContract.LeaseStatus__c) {
            contract.TechStatusChanged__c = true;
        }
        
        /*if(associatedOpptys.containsKey(contract.Opportunity__c)){
            if(associatedOpptys.get(contract.Opportunity__c).UsageClause__c != '')
            	contract.UsageClauseDetails__c = associatedOpptys.get(contract.Opportunity__c).UsageClause__c ;
            else
                contract.UsageClauseDetails__c = accIds.get(acctVsParentAcc.get(contract.Account__c)).Description__c;
        }else if(contract.Account__c != NULL){
            contract.UsageClauseDetails__c = accIds.get(acctVsParentAcc.get(contract.Account__c)).Description__c;
        }*/
    }
    
    public void beforeDelete(SObject so){
    }
    
    public void afterInsert(SObject so){
    }
    
    public void afterUpdate(SObject oldSo, SObject so)
    {
        
    }
    
    public void afterDelete(SObject so)
    {
    }
    
    /**
    * andFinally
    *
    * This method is called once all records have been processed by the trigger. Use this
    * method to accomplish any final operations such as creation or updates of other records.
    */
    
    public void andFinally(){
        
    }
}