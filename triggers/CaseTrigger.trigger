trigger CaseTrigger on Case (after delete, after insert, after update, before delete, before insert, before update) {
    String caseRecordType;
    Set<String> noBypassRecordTypeSet = new Set<String>{
            constants.CENTRE_TEAM,	
            constants.LEASING_FINANCE,	
            constants.ANCILLARY_TAX_INVOICE,
        	constants.INSPECTION_REPORT,
            constants.RETAIL_DESIGN_INSTRUCTION,
            constants.STATEMENT_OF_COMPLETION,
            constants.SURRENDER_A_LEASE,
            constants.TERMINATE_A_LEASE,
            constants.ASSIGN_OF_A_LEASE,
            constants.MISCELLANEOUS_LEASE,
            constants.LEASING_CHECKSHEET,
            constants.MANAGE_BANK_GUARANTEE
            };
                Map<Id, Schema.RecordTypeInfo> caseRecordTypeMap = RecordTypeUtil.getAllRecordTypesById(Constants.OBJECT_CASE);
    System.debug('Start Trigger.new ' + Trigger.new);
    if(Trigger.new!=null){
        for(Case cas : (List<Case>) Trigger.new){
            if(caseRecordTypeMap.containsKey(cas.RecordTypeId)){
                caseRecordType = caseRecordTypeMap.get(cas.RecordTypeId).getName();
                //System.debug('caseRecordType ' + caseRecordType);
                if(noBypassRecordTypeSet.contains(caseRecordType)){
                    TriggerHandler.clearBypass('CaseTriggerHandler');
                    break;
                }
            }
        }
    }
    
    
    TriggerFactory.createAndExecuteHandler(CaseTriggerHandler.class);
}