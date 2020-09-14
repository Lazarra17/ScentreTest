public class ApproveSummaryTracking {
	
    @AuraEnabled
    public static LightningResponse getChangedItem(Id oppoId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(ApproveSummaryTracking.class.getName());
        LightningResponse response = new LightningResponse();
        List<ApproveStatusController.ApprovalTracking> aTracking = new List<ApproveStatusController.ApprovalTracking>();
        //usageClause = 'this is a test';
        if (oppoId != null) {
            //Opportunity oppo = [select id, ProposedStartDate__c, NationalFitoutPeriod__c from Opportunity where id =: OppObj];
            //List<OpportunityAuditHistory__c> oAHs = [Select id, ModifiedFieldName__c, CreatedDate from OpportunityAuditHistory__c where Opportunity__c =: oppoId and OpportunityApprovalStatus__c != '' order by createddate];
            List<OpportunityAuditHistory__c> oAHs = [Select id, ModifiedFieldName__c, NewValue__c, PreviousValue__c, CreatedDate from OpportunityAuditHistory__c where Opportunity__c =: oppoId and OpportunityApprovalStatus__c != '' order by createddate];
            //get field set
            List<Schema.FieldSetMember> fieldSetMemberList =  ApproveStatusController.readFieldSet('HistoryTracking','Opportunity');
            String selectedField = '';
            for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList) {
                selectedField = selectedField + ', ' + fieldSetMemberObj.getFieldPath();
            }
            String oppoSoql = 'Select Id ' + selectedField + ', currencyIsoCode From Opportunity where id = \'' + oppoId + '\'';
            sObject sobj = Database.query(oppoSoql);
            Opportunity oppo = (Opportunity)sobj;
			for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList)
            {
                Datetime min;
                Datetime max;
                String minOldValue;
                String maxNewValue;
                Integer initialCheck = -1;
                for (Integer i=0; i < oAHs.size(); i++) {
                    if (oAHs.get(i).ModifiedFieldName__c == fieldSetMemberObj.getFieldPath()) {
                        initialCheck = initialCheck + 1;
                        if (initialCheck == 0) {
                            min = oAHs.get(i).CreatedDate;
                            max = oAHs.get(i).CreatedDate;
                            minOldValue = oAHs.get(i).PreviousValue__c;
                            maxNewValue = oAHs.get(i).NewValue__c;
                        } else {
                            if (oAHs.get(i).CreatedDate < min) {
                                min = oAHs.get(i).CreatedDate;
                                minOldValue = oAHs.get(i).PreviousValue__c;
                            } else if (oAHs.get(i).CreatedDate > max) {
                                max = oAHs.get(i).CreatedDate;
                                maxNewValue = oAHs.get(i).NewValue__c;
                            }
                        }
                    }
                }
                //System.debug('getType' + fieldSetMemberObj.getType());
                ApproveStatusController.ApprovalTracking aT1 = new ApproveStatusController.ApprovalTracking();
                aT1.label = fieldSetMemberObj.getLabel();
				aT1.apiName = String.valueOf(fieldSetMemberObj.getType());          
                if (minOldValue != null && maxNewValue != null && minOldValue != maxNewValue) {
                    aT1.isChanged = true;
                    aT1.oldValue = minOldValue;
                    String formatedData = ApproveStatusController.formatData(maxNewValue, String.valueOf(fieldSetMemberObj.getType()), oppo.CurrencyIsoCode);
                    System.debug('formatedData' + formatedData);
                    aT1.newValue = formatedData;
                	aTracking.add(aT1);   
                } else {
                    aT1.isChanged = false;
                    String formatedData = ApproveStatusController.formatData(String.valueOf(oppo.get(fieldSetMemberObj.getFieldPath())), String.valueOf(fieldSetMemberObj.getType()), oppo.CurrencyIsoCode);
                   	System.debug('formatedData' + formatedData);
                    aT1.newValue = formatedData;
                    aTracking.add(aT1);
                }
            }
        }
        String latestApprovedCapital = '';     
        String totalForecastCapital = '';
        ApproveStatusController.ApprovalTracking tFC;
        for (ApproveStatusController.ApprovalTracking aT : aTracking) {
            if (aT.label == 'Latest Approved Capital') {
                latestApprovedCapital = aT.newValue.trim();
            }
            if (aT.label == 'Total Forecast Capital') {
                totalForecastCapital = aT.newValue.trim();
            }
        }
        for (ApproveStatusController.ApprovalTracking aT : aTracking) {
        	if (latestApprovedCapital != totalForecastCapital && aT.label == 'Total Forecast Capital') {
            	aT.isChanged = true;
        	}   
        }
        response.returnValue = JSON.serialize(aTracking);
        errorHandler.save();
        return response;
    }
}