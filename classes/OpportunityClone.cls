public without sharing class OpportunityClone {
	@InvocableMethod
    public static List<String> oppoClone(List<List<String>> inputStrings) {
        System.debug('inputStrings ' + inputStrings);
        String typeVaration = '';
        List<Id> ids = new List<Id>();
        List<Id> contractIds = new List<Id>();
        if (inputStrings.size() == 1) {
            for (List<String> input : inputStrings) {
                System.debug('Input size === ' + input.size());
                if (input.size() == 3) {
                    for (String inputT : input) {
                        if (inputT.contains('Variation')) {
                            typeVaration = inputT;
                        } else {
                            Id inputId = inputT;
                            if (String.valueOf(inputId.getsobjecttype()) == 'Opportunity') {
                                ids.add(inputId);
                            } else if (String.valueOf(inputId.getsobjecttype()) == 'Contract__c') {
                                contractIds.add(inputId);
                            }
                                      
                        }
                    }
                }
            }
        }
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(OpportunityClone.class.getName());
        String whereClause = 'Id in :ids';
        String objectName = Constants.OPPORTUNITY;
        String soql = Utils.getCreatableFieldsSOQL(objectName, whereClause, ids, Constants.FIELD_SET_API_NAME_CLONE);
        System.debug('soql ' + soql);
        List<Opportunity> oppos = (List<Opportunity>)Database.query(soql);
        List<Contract__c> contracts = [Select Id, UsageClauseDetails__c, UsageClauseName__c, Account__c, CurrentRent__c, LeaseStartDate__c, LeaseEndDate__c, RentCommencementDate__c, CurrentContribution__c, SecurityAmount__c From Contract__c Where id in:contractIds];
        //clone oppo
        List<Account> oppAccount = [SELECT ID, ParentId FROM Account WHERE Id =: oppos.get(0).AccountId];
        Id parentAccountId = oppAccount[0].ParentId;
        List<PrecedentClause__c> precendenceClause = [SELECT Id, Name, Type__c, Account__c, Description__c 
                                                      	FROM PrecedentClause__c 
                                                      	WHERE Account__c =:parentAccountId
                                                     ];
        String newOppoId = '';
        Opportunity finalCloneOppo = null; 
        if (oppos.size() == 1) {
            Opportunity cloneOppo = oppos.get(0).clone(false, true, false, false);
            
            //Copy updated info from Contract
            if (contracts.get(0).CurrentRent__c > 0) {
            	cloneOppo.AnnualMinimumRent__c = contracts.get(0).CurrentRent__c;    
            }
            if (contracts.get(0).Account__c != null) {
                cloneOppo.accountId = contracts.get(0).Account__c;
            }
            //RPP-10989
            cloneOppo.Nil_Holdover_Increase__c = setNilHoldoverIncrease(cloneOppo.accountId);
            cloneOppo.FitoutContribution__c = contracts.get(0).CurrentContribution__c; //NEEL RPP-9305
            cloneOppo.SecurityDeposit__c = contracts.get(0).SecurityAmount__c;
            cloneOppo.ProposedEndDate__c = contracts.get(0).LeaseEndDate__c;
            cloneOppo.ProposedStartDate__c = contracts.get(0).LeaseStartDate__c;
            cloneOppo.ProposedRentCommencementDate__c = contracts.get(0).RentCommencementDate__c;
            if(contracts.get(0).UsageClauseDetails__c != NULL && contracts.get(0).UsageClauseDetails__c != ''){
            	cloneOppo.UsageClause__c = contracts.get(0).UsageClauseDetails__c;    
                cloneOppo.Usage_Clause_Name__c = contracts.get(0).UsageClauseName__c;
            }else if(precendenceClause.size() > 0){
                cloneOppo.UsageClause__c = precendenceClause[0].Description__c;
                cloneOppo.Usage_Clause_Name__c = precendenceClause[0].Name;
            }
            
            //Add for RPP-10158
            cloneOppo.JDESentStatus__c = '';
            if (contracts.get(0).LeaseEndDate__c != null && contracts.get(0).LeaseStartDate__c != null && 
                contracts.get(0).LeaseEndDate__c > contracts.get(0).LeaseStartDate__c) {
            	Date startDate = contracts.get(0).LeaseStartDate__c;
                Date startDateTemp = contracts.get(0).LeaseStartDate__c;
                Date endDate = contracts.get(0).LeaseEndDate__c;
                Integer oppYear = 0;
                Integer oppMonth = 0;
                Integer oppDay = 0;
                Integer monthBet = startDate.monthsBetween(endDate);
                oppYear = monthBet /12;
                oppMonth = Math.Mod(monthBet ,12);
                startDate = startDate.addYears(oppYear);
                startDate = startDate.addMonths(oppMonth);
                oppDay = startDate.daysBetween(endDate);
                if(oppDay < 0) {
                    oppYear -= 1;
                    startDateTemp = startDateTemp.addYears(oppYear);
                    oppMonth = startDateTemp.monthsBetween(endDate) - 1;
                    if(oppMonth>=12) {
                       oppYear = oppMonth / 12;
                       oppMonth = Math.Mod(oppMonth ,12);
                       startDateTemp = startDateTemp.addYears(1);
                    }
                    startDateTemp = startDateTemp.addMonths(oppMonth);
                    oppDay = startDateTemp.daysBetween(endDate);
                }
                //cloneOppo.TermDays__c = oppDay;
                //cloneOppo.TermMonths__c = oppMonth;
                //cloneOppo.TermYr__c = oppYear;   
            }
            
            //Default in Opportunity
            cloneOppo.ParentOpportunity__c = oppos.get(0).Id;
            cloneOppo.BestBet__c = FALSE;
            cloneOppo.BreakType__c = 'Natural';
            cloneOppo.DealAchieved__c = FALSE; //Added on 10.09.2018
            cloneOppo.DealAchievedDate__c = null;//Added on 10.09.2018
            cloneOppo.stagename = Constants.UNDERSTAND_NEGOTIATE;
            cloneOppo.TechByPassOnClone__c = TRUE;
            cloneOppo.SpecialityLeaseType__c = typeVaration;
            cloneOppo.PercentageRentIncluded__c = FALSE;
            cloneOppo.AcceptedDisclosureStatement__c = true;
            cloneOppo.ApprovalStatus__c = Constants.INIAPPR_GRANTED;
            if(oppos.get(0).PromoLevyIncluded__c != 'Yes')
            {
                cloneOppo.PromoLevyIncluded__c = 'No';
            }
            TriggerHandler.bypass('OpportunityTriggerHandler');
            TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
            try {
                Database.SaveResult srList = Database.insert(cloneOppo, false);
                System.debug('cloneOppo.ExistingContract__c === '+cloneOppo.ExistingContract__c);
                if (srList.isSuccess()) {
                    finalCloneOppo = cloneOppo;
                	newOppoId = cloneOppo.Id;
                } else{
                    for(Database.Error err : srList.getErrors()) {
                        errorHandler.createError(err.getMessage());
                    }
                }
            } catch (Exception e) {
                errorHandler.createError(e);
            }
        }
        
        //clone oppo contact roles
        List<OpportunityContactRole> contactRoles = [select id from OpportunityContactRole where opportunityId in: ids];
       	List<Id> oppoContactRoles = new List<Id>();
        if (contactRoles.size() > 0 && newOppoId != '') {
            for (OpportunityContactRole contactRole : contactRoles) {
                oppoContactRoles.add(contactRole.Id);
            }
            String whereClauseOppoCR = 'Id in: oppoContactRoles';
            String objectNameOCR = Constants.OPPORTUNITY_CONTACT_ROLE;
            String soqlOCR = Utils.getCreatableFieldsSOQL(objectNameOCR, whereClauseOppoCR, oppoContactRoles, Constants.FIELD_SET_API_NAME_CLONE);
            List<OpportunityContactRole> ocrs = (List<OpportunityContactRole>)Database.query(soqlOCR);
            List<OpportunityContactRole> cloneOcrs = new List<OpportunityContactRole>();
            for (OpportunityContactRole ocr : ocrs) {
                OpportunityContactRole cloneOcr = ocr.clone(false, true, false, false);
                cloneOcr.opportunityId = newOppoId;
                cloneOcrs.add(cloneOcr);
            }
            if (cloneOcrs.size() > 0) {
                try {
                    Database.SaveResult[] srList = Database.insert(cloneOcrs, false);
                } catch (Exception e) {
                    errorHandler.createError(e);
                }
            }
        }
        
        //clone oppo line item
        List<OpportunityLineItem> oppoProducts = [select id, ProductFamily__c, TechIsClone__c, opportunityId from OpportunityLineItem where opportunityId in: ids];
        List<Id> oppoPIds = new List<Id>();
        if (oppoProducts.size() > 0 && newOppoId != '') {
            for (OpportunityLineItem oppoProduct : oppoProducts) {
                oppoPIds.add(oppoProduct.Id);
            }
            String whereClauseOppoP = 'Id in: oppoPIds';
            String objectNamePP = Constants.OPPORTUNITY_LINE_ITEM;
            String soqlPP = Utils.getCreatableFieldsSOQL(objectNamePP, whereClauseOppoP, oppoPIds, Constants.FIELD_SET_API_NAME_CLONE);
            List<OpportunityLineItem> oppoLineItems = (List<OpportunityLineItem>)Database.query(soqlPP);
            List<OpportunityLineItem> cloneOppoLineItems = new List<OpportunityLineItem>();
            for (OpportunityLineItem oppoLineItem : oppoLineItems) {
                //exclude outgoing products
                OpportunityLineItem cloneOppoLineItem = oppoLineItem.clone(false, true, false, false);
                System.debug('cloneOppoLineItem ' + cloneOppoLineItem);
                cloneOppoLineItem.TechIsClone__c = TRUE;
                cloneOppoLineItem.opportunityId = newOppoId;
                if (cloneOppoLineItem.ProductFamily__c != Constants.FEES_CHARGES && cloneOppoLineItem.ProductFamily__c != Constants.CAPITAL) {
                	cloneOppoLineItems.add(cloneOppoLineItem);   
                }
            }
            if (cloneOppoLineItems.size() > 0) {
                try {
                    Database.SaveResult[] srList = Database.insert(cloneOppoLineItems, false);
                    System.debug('srList ' + srList.size() + ' ' + srList);
                } catch (Exception e) {
                    errorHandler.createError(e);
                }
            }
        }
        
        //clone oppo clauses
        /*List<OpportunityClause__c> oppoClauses = [select id from OpportunityClause__c where opportunity__c in: ids];
        List<Id> oppoClausesIds = new List<Id>();
        if (oppoClauses.size() > 0 && newOppoId != '') {
            for (OpportunityClause__c oppoClause : oppoClauses) {
                oppoClausesIds.add(oppoClause.Id);
            }
            String whereClausePC = 'Id in: oppoClausesIds';
            String objectNamePC = Constants.OPPORTUNITY_CLAUSE_API;
            String soqlPC = Utils.getCreatableFieldsSOQL(objectNamePC, whereClausePC, oppoClausesIds, Constants.FIELD_SET_API_NAME_CLONE);
            List<OpportunityClause__c> oppoCs = (List<OpportunityClause__c>)Database.query(soqlPC);
            List<OpportunityClause__c> cloneoppoCs = new List<OpportunityClause__c>();
            for (OpportunityClause__c oppoC : oppoCs) {
                OpportunityClause__c cloneOppoC = oppoC.clone(false, true, false, false);
                cloneOppoC.opportunity__c = newOppoId;
                cloneoppoCs.add(cloneOppoC);
            }
            if (cloneoppoCs.size() > 0) {
                try {
                    //Database.SaveResult[] srList = Database.insert(cloneoppoCs, false);
                    //System.debug('srList oppoclause ' + srList);
                } catch (Exception e) {
                    errorHandler.createError(e);
                }
            }
        }*/
        List<String> oppoNewId = new List<String>();
		oppoNewId.add(newOppoId);
		System.debug('oppoNewId ' + oppoNewId);      
        
 /*       if (finalCloneOppo != null) {
        	finalCloneOppo.StageName = Constants.PROPOSE_ACCEPT;
            try {
                Database.SaveResult srListOppo = Database.update(finalCloneOppo, false);
                System.debug('srListOppo ' + srListOppo);
            } catch (Exception e) {
                errorHandler.createError(e);
            }   
        }
        */
        //Reset account change field
        /*List<Account> accountsFromOppo = [Select Id, TechAffiliationIsChange__c From Account Where Id =: finalCloneOppo.AccountId];
        if (accountsFromOppo.size() == 1) {
            Account tempAccount = accountsFromOppo.get(0);
            tempAccount.TechAffiliationIsChange__c = False;
            try {
                Database.SaveResult srList = Database.update(tempAccount, false);
            } catch (Exception e) {
                errorHandler.createError(e);
            }
        }*/
        
        //Reset affiliation change field
        /*List<Affiliation__c> updatedAffiliations = new List<Affiliation__c>();
        List<Affiliation__c> affiliations = [Select Id, TechIsChange__c From Affiliation__c Where Account__c =: finalCloneOppo.AccountId];
        if (affiliations.size() > 0) {
            for (Integer i=0; i < affiliations.size(); i++) {
                Affiliation__c tempAffiliation = affiliations.get(i);
                tempAffiliation.TechIsChange__c = False;
                updatedAffiliations.add(tempAffiliation);
            }
            if (updatedAffiliations.size() > 0) {
                try {
                    Database.SaveResult[] srList = Database.update(updatedAffiliations, false);
                } catch (Exception e) {
                    errorHandler.createError(e);
                }
            }
        }*/
        errorHandler.save();
        return oppoNewId;
    }
    
    //RPP-10989 - START
    private static Boolean setNilHoldoverIncrease(Id accId){
        Boolean flag = false;
        List<PrecedentClause__c> clauseList = new List<PrecedentClause__c>();
        
        for(PrecedentClause__c clause : DatabaseSOQLBank.getNationalAgreementsOfAccount(accId)){
            if(clause.Nil_Holdover_Increase__c == true){
                flag = true;
            }
        }
        
        return flag;
    }
    //RPP-10989 - END
}