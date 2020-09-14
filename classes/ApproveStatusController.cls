public class ApproveStatusController {
	public Id OppObj {get;set;}
    
    public List<ApprovalTracking> getATracking() {  
        System.debug('InsidegetTracking==>');
        List<ApprovalTracking> aTracking = new List<ApprovalTracking>();
        //usageClause = 'this is a test';
        if (OppObj != null) {
            System.debug('InsidegetTracking==>');
            //Opportunity oppo = [select id, ProposedStartDate__c, NationalFitoutPeriod__c from Opportunity where id =: OppObj];
            //List<OpportunityAuditHistory__c> oAHs = [Select id, ModifiedFieldName__c, CreatedDate from OpportunityAuditHistory__c where Opportunity__c =: OppObj and OpportunityApprovalStatus__c != '' order by createddate];
            List<OpportunityAuditHistory__c> oAHs = [Select id, ModifiedFieldName__c, NewValue__c, PreviousValue__c, CreatedDate from OpportunityAuditHistory__c where Opportunity__c =: OppObj and OpportunityApprovalStatus__c != '' order by createddate];
            //get field set
            System.debug('InsidegetTracking==>' +oAHs);
            List<Schema.FieldSetMember> fieldSetMemberList =  readFieldSet('HistoryTracking','Opportunity');
            System.debug('InsidegetTracking==>' + fieldSetMemberList);
            String selectedField = '';
            for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList) {
                selectedField = selectedField + ', ' + fieldSetMemberObj.getFieldPath();
            }
            String oppoSoql = 'Select Id ' + selectedField + ', currencyIsoCode From Opportunity where id = \'' + OppObj + '\'';
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
                ApprovalTracking aT1 = new ApprovalTracking();
                aT1.label = fieldSetMemberObj.getLabel();
				minOldValue = minOldValue == null ? '' : minOldValue;  
                maxNewValue = maxNewValue == null ? '' : maxNewValue;
                if (minOldValue != null && maxNewValue != null && minOldValue != maxNewValue) {
                    
                    if(markFieldIsChanged(fieldSetMemberObj.getLabel()))
                    	aT1.isChanged = true;
                    
                    aT1.oldValue = minOldValue;
                    String formatedData = formatData(maxNewValue, String.valueOf(fieldSetMemberObj.getType()), oppo.CurrencyIsoCode);
                    aT1.newValue = formatedData;
                	aTracking.add(aT1);   
                } else {
                    aT1.isChanged = false;
                    String formatedData = formatData(String.valueOf(oppo.get(fieldSetMemberObj.getFieldPath())), String.valueOf(fieldSetMemberObj.getType()), oppo.CurrencyIsoCode);
                    aT1.newValue = formatedData;
                    aTracking.add(aT1);
                }
            }
        }
		// if Latest Approved Capital != Total Forecast Capital, hightlight Total Forecast Capital
		String latestApprovedCapital = '';     
        String totalForecastCapital = '';
        ApprovalTracking tFC;
        for (ApprovalTracking aT : aTracking) {
            if (aT.label == 'Latest Approved Capital' && aT.newValue != null) {
                latestApprovedCapital = aT.newValue.trim();
            }
            if (aT.label == 'Total Forecast Capital' && aT.newValue != null) {
                totalForecastCapital = aT.newValue.trim();
            }
            if (aT.label == 'Financials' && aT.newValue != null) {
                System.debug('aT.newValue ' + aT.newValue);
            }
        }
        for (ApprovalTracking aT : aTracking) {
        	if (latestApprovedCapital != totalForecastCapital && aT.label == 'Total Forecast Capital') {
            	aT.isChanged = true;
        	}   
        }
        return aTracking; 
    }
    
    public UsageCheck getUsageClause(){
        UsageCheck usageC = new UsageCheck();
        if (OppObj != null) {
            Opportunity oppo = [Select id, TechTrackingUsage__c from Opportunity where id =: OppObj];
            List<OpportunityClause__c> oClause = [Select id, ClauseDetails__c, Type__c  from OpportunityClause__c where Opportunity__c =: OppObj and Type__c = 'Usage'];
            if(oClause.size() > 0){
            if (oClause.size() > 0 && oClause.get(0).ClauseDetails__c != '' && oppo.TechTrackingUsage__c != null && oppo.TechTrackingUsage__c) {
                usageC.isChanged = true;
                
            } else {
                usageC.isChanged = false; 
            } 
            usageC.clauseDetails = oClause.get(0).ClauseDetails__c;
            }    
        }
        return usageC;
    }

    public class UsageCheck {
        public String clauseDetails {get; set;}
        public Boolean isChanged {get; set;}
    }
    
    public class ApprovalTracking {
        public String label {get;set;}
        public String oldValue {get;set;}
        public String newValue {get;set;}
        public Boolean isChanged {get;set;}
        public String apiName {get;set;}
    }
    
    public static List<Schema.FieldSetMember> readFieldSet(String fieldSetName, String ObjectName)
    {
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
    
        //system.debug('====>' + DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName));
    
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
    
        //List<Schema.FieldSetMember> fieldSetMemberList =  fieldSetObj.getFields();
        //system.debug('fieldSetMemberList ====>' + fieldSetMemberList);  
        return fieldSetObj.getFields(); 
    }
    
    public static String formatData(String input, String format, String currencyIsoCode) {
        if (format == 'CURRENCY' && input != null) {
            Decimal rA = Decimal.valueOf(input);
            List<String> args = new String[]{'0','number','###,###,##0.00'};
            input = currencyIsoCode + ' ' + String.format(rA.format(), args);
        } else if (format == 'PERCENT' && input != null) {
            input = input + '%';
        } else if (format == 'TEXTAREA' && input != null) {
            input = input.replace('\n', '<br/>');
        }
        return input;
    }
    
    private Boolean markFieldIsChanged(String fieldLabel){
        String LatestApprovedRent = 'Latest Approved Rent';
        String LatestApprovedCapital = 'Latest Approved Capital';
        
        if(fieldLabel.equalsIgnoreCase(LatestApprovedRent) || fieldLabel.equalsIgnoreCase(LatestApprovedCapital))
        return FALSE;
        
        return TRUE;
    }
}