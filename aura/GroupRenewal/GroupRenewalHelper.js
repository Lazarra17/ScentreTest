({
	prepareDrafts : function(component, contracts) {
        
        const dealTypes = component.get('v.dealTypes');
        const dealType = dealTypes.includes('Semi Gross') ? 'Semi Gross' : '';

        
        const draftOpps = contracts.map(function(contract) {
            
            let proposedStartDate = '';
            let leaseEndDate = '';
            
            if (contract.LeaseEndDate__c) {
                proposedStartDate = new Date(contract.LeaseEndDate__c);
                proposedStartDate.setDate(proposedStartDate.getDate() + 1);
                proposedStartDate = proposedStartDate.toISOString();
                leaseEndDate = proposedStartDate;
            }        
            
            return {
                isSelected: false,
                contractId : contract.Id,
                accountId : contract.Account__r ? contract.Account__r.Id : null,
                spaceId : contract.Space__r ? contract.Space__r.Id : null,
                propertyId : contract.Property__r ? contract.Property__r.Id : null,
                accountName : contract.Account__r ? contract.Account__r.Name : null,
                spaceName : contract.Space__r ? contract.Space__r.Name : null,
                propertyName : contract.Property__r ? contract.Property__r.Name : null,
                annualMinRent : '',
                forecastAchievedDate : '',
                proposedStartDate :proposedStartDate,
                termYears : '',
                termMonths : '',
                termDays : '',
                leaseEndDate : leaseEndDate,
                dealType : dealType,
                parentOpp : contract.Opportunity__c,
                oppRecordTypeId : contract.TECH_OpportunityRecordTypeId__c
            }; 
        });
    
		component.set('v.draftOpps', draftOpps);   	
	},
    prepareData : function(component, checkedOpps, primaryContact, groupRenewalAdmin) {
        console.log('groupRenewalAdmin: '+groupRenewalAdmin);
        console.log('primaryContact: '+primaryContact);
        const ownerId = component.get('v.oppOwnerId');
        const oppList = checkedOpps.map(function(oppDraft) {
            
            return {
                'sobjecttype' : 'Opportunity',                
                'AccountId' : oppDraft.accountId,
                'CloseDate' : oppDraft.forecastAchievedDate,
                'ExistingContract__c' : oppDraft.contractId,
                'Name' : 'Test',
                'ParentOpportunity__c' : oppDraft.parentOpp,    
                'Property__c' : oppDraft.propertyId,
                'ProposedStartDate__c' : oppDraft.proposedStartDate,
                'ProposedRentCommencementDate__c' : oppDraft.proposedStartDate,
                'RecordTypeId' : oppDraft.oppRecordTypeId,
                'RentInAdvance__c' : 0,
                'Space__c' : oppDraft.spaceId,
                'StageName' : 'Understand & Negotiate',
                'TermYr__c' : oppDraft.termYears,
                'TermMonths__c' : oppDraft.termMonths,
                'TermDays__c' : oppDraft.termDays,
                'Type' : 'New Lease',
                'AnnualMinimumRent__c' : oppDraft.annualMinRent,
                'DealType__c' : oppDraft.dealType,
                'PromoLevyIncluded__c' : 'Yes',
                'Tech_IsCreatedFromGroupRenew__c' : true,
                'OwnerId' : ownerId,
                'PrimaryContact__c' : primaryContact,
                'Group_Renewal_Retail_Admin__c' : groupRenewalAdmin
            };
        });
        return oppList;
    },
    isValidDate: function(date) {
        return date && Object.prototype.toString.call(date) === "[object Date]" && !isNaN(date);
    },
    errorHandler : function(message) {
        var idxStack = message.indexOf("STACK TRACE:");
        var msg = idxStack != -1 ? message.substring(0, idxStack-1) : message;
        var idx = msg.indexOf("first error:");
        var errMsg = idx != -1 ? msg.substring(idx + 13, msg.length) : 'Something went wrong. Please contact your System Administrator.';
        
        while(errMsg.includes('&quot;')){
            errMsg = errMsg.replace('&quot;', '');
        }
        
        if(errMsg.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
            errMsg = errMsg.replace('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', '');
            var messages = errMsg.split(':');
            var valMsg = '';
            for(var i=0; i< messages.length - 1; i++){
                valMsg = valMsg + messages[i];
            }
            errMsg = valMsg;
        }
        
        return errMsg;
    },
    showError : function(component, message) {
        $A.util.removeClass(component.find('errorMessage'), 'slds-hide');
        component.set('v.errMsg', this.errorHandler(message));
    }
})