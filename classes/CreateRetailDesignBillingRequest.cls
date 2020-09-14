public class CreateRetailDesignBillingRequest {
    /**
* @Author: Chen Chen
* @Parameter: List of case Ids
* @Description: called in the process builder to create nso billing case 
*/
    @InvocableMethod 
    public static void retailDesignBillingCase(List<Id> caseRecordSet) {
        List<Case> newCases = new List<Case>();
        List<Case> sNewCases = new List<Case>();
        List<Case> originCases = [Select Id, RecordTypeId, RecordType.Name, Space__c, Contract__c,Opportunity__c, Opportunity__r.DevelopmentType__c, JDESentStatus__c, InspectionType__c, TechParentIsVoluntaryWorks__c, Type From Case Where Id in: caseRecordSet];
        List<RecordType> recordTypeCases = [Select Id, Name From RecordType where sobjecttype =: Constants.OBJECT_CASE];
        Map<Id, String> recordIdToName = new Map<Id, String>();
        String retailDesignBillingId = '';
        for (RecordType recordType : recordTypeCases) {
            recordIdToName.put(recordType.Id, recordType.Name);
            if (recordType.Name == Constants.RETAIL_DESIGN_BILLING) {
                retailDesignBillingId = recordType.Id;
            }
        }
        
        //Validate cases
        List<Case> compareCases = [SELECT Id, CreatedDate, Opportunity__c, InspectionType__c, Type FROM Case WHERE CreatedDate = LAST_N_DAYS:60];
        List<Case> validatedCases = new List<Case>();
        for (Case oCase : originCases) {
            String inpsectionType = '';
            if (oCase.RecordTypeId != null && recordIdToName.get(oCase.RecordTypeId) != null) {
                String recordTypeName = recordIdToName.get(oCase.RecordTypeId);
                if (Constants.INSPECTION_REPORT == recordTypeName) {
                    inpsectionType = Constants.DSIR;
                } else if (Constants.RETAIL_DESIGN_INSTRUCTION == recordTypeName) {
                    inpsectionType = Constants.DSMT;
                } else if (Constants.STATEMENT_OF_COMPLETION == recordTypeName) {
                    inpsectionType = Constants.DSSO;
                }
            }
            System.debug('inpsectionType ' + inpsectionType);
            // check if it is volunteer work
            if (oCase.TechParentIsVoluntaryWorks__c != null && oCase.TechParentIsVoluntaryWorks__c) {
                //goes into queue
                System.debug('oCase volunteer work' + oCase);
                validatedCases.add(oCase);
            } else {
                Boolean IsAdd = true;
                for (Case cCase: compareCases) {
                    if (cCase.Id != oCase.Id && cCase.Opportunity__c == oCase.Opportunity__c && cCase.InspectionType__c == inpsectionType) {
                        System.debug('oCase 60 days check' + oCase);
                        IsAdd = false;
                    }
                }
                if (IsAdd) {
                    if (oCase.Opportunity__c != null && (oCase.Opportunity__r.DevelopmentType__c == '' || oCase.Opportunity__r.DevelopmentType__c == null)) {
                        System.debug('oCase developmentType' + oCase);
                        validatedCases.add(oCase);
                    }
                }
            }
        }
        if (validatedCases.size() > 0) {
            for (Case originCase : validatedCases) {
                Case retailDesingBillingCase = new Case();
                retailDesingBillingCase.Space__c = originCase.Space__c;
                retailDesingBillingCase.RecordTypeId = retailDesignBillingId;
               
                if (originCase.RecordType.Name == Constants.INSPECTION_REPORT) {
                    retailDesingBillingCase.Subject = Constants.CASE_SUBJECT_RDB_IR;
                } else if (originCase.RecordType.Name == Constants.RETAIL_DESIGN_INSTRUCTION){
                    retailDesingBillingCase.Subject = Constants.CASE_SUBJECT_RDB_RDI;
                } else if (originCase.RecordType.Name == Constants.STATEMENT_OF_COMPLETION){
                    retailDesingBillingCase.Subject = Constants.CASE_SUBJECT_RDB_SOC;
                }
                
                retailDesingBillingCase.Type = Constants.RETAIL_DESIGN_BILLING;
                retailDesingBillingCase.Status = Constants.SPACE_STATUS_NEW;
                if (originCase.Contract__c != null) {
                    retailDesingBillingCase.Contract__c = originCase.Contract__c;
                }
                
                //NEEL 05092018 - this is made mandatory for Retail Design to have an Opportunity to process the request in JDE - START
                if (originCase.Opportunity__c != null) {
                    retailDesingBillingCase.Opportunity__c = originCase.Opportunity__c;
                }
                // END
                
                retailDesingBillingCase.ParentId = originCase.Id;
                if (originCase.RecordTypeId != null && recordIdToName.get(originCase.RecordTypeId) != null) {
                    String recordTypeName = recordIdToName.get(originCase.RecordTypeId);
                    if (Constants.INSPECTION_REPORT == recordTypeName) {
                        retailDesingBillingCase.InspectionType__c = Constants.DSIR;
                    } else if (Constants.RETAIL_DESIGN_INSTRUCTION == recordTypeName) {
                        retailDesingBillingCase.InspectionType__c = Constants.DSMT;
                    } else if (Constants.STATEMENT_OF_COMPLETION == recordTypeName) {
                        retailDesingBillingCase.InspectionType__c = Constants.DSSO;
                    }
                }
                System.debug(retailDesingBillingCase.Status);
                newCases.add(retailDesingBillingCase);
            }
        }
        insert newCases;
        for (Case uCase : newCases) {
            uCase.Status = Constants.COMPLETED;
            uCase.JDESentStatus__c = Constants.OPPO_JDE_STATUS_READY;
            sNewCases.add(uCase);
        }
        for (Case urCase : originCases) {
            urCase.TechBillingTriggered__c = true;
            sNewCases.add(urCase);
        }
        update sNewCases;
    }
}