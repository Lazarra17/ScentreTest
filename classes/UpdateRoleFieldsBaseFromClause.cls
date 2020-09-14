global class UpdateRoleFieldsBaseFromClause{
     
    
    @InvocableMethod
    public static void updateRoleFields(List<Id> OpportunityLst) {
        Map<Id, Schema.RecordTypeInfo> oppRecordTypeById;       
        oppRecordTypeById = RecordTypeUtil.getAllRecordTypesById(Constants.OPPORTUNITY);
        String newOppRecordTypeName;
        Set<String> allowedRetTypes = new Set<String>{constants.RET_FINALAPPROVAL, constants.RETAILRISKAPPROVAL, constants.RETAILINITAPPROVAL};
        Set<String> allowedComTypes = new Set<String>{constants.COMMRISKAPPROVAL, constants.COMMFINALAPPROVAL, constants.COMMINITAPPROVAL};
        Set<String> roleSet = new Set<String>();
        List<String> rangeRentDigits = new List<String>();
        List<String> rangeCapitalDigits = new List<String>();
        Set<Id> propIdSet = new Set<Id>();
        Map<String, Id> roleUserMap = new Map<String, Id>();
        Decimal cmRentfirst;
        Decimal cmRentSecond;
        Decimal cmCapfirst;
        Decimal cmCapSecond;
        String usrrole = '';
        String usrProfile = '';
        Decimal oppRentVariance;
        Decimal oppCapitalVariance;
        Map<Id,Set<String>> oppIdOppClauseSetMap = new Map<Id,Set<String>>();
        Map<Id, Id> topParentAccountMap  = new Map<Id,Id>();
        Set<String> accCategorySet = new Set<String>();
        Set<Id> contractOppIdSet = new Set<Id>();
        Set<Id> opportunityAccountIdSet = new Set<Id>();
        List<Contract__c> oppContractList = new List<Contract__c>();    
        Map<Id, Account> accountMap = new Map<Id, Account>();       
        List<OpportunityClause__c> highRiskOppClauseList;
        Map<Id, Map<Id, List<OpportunityClause__c>>> propIdOppIdOppClauseListMap;
        List<ChatterPostUtil.ChatterNotificationWrapper> chatterwrapperItemList = new List<ChatterPostUtil.ChatterNotificationWrapper>();

        Set<String> thresholdApprStatusSet = new Set<String>{constants.PENDING_INI_APRV,constants.INI_APPV_REJ,constants.INIAPPR_GRANTED,constants.RSKAPPR_GRANTED,constants.RMAPPR_GRANTED,constants.RMRISK_APPRGRANTED, constants.PEND_FINALAPPROV,constants.FINALAPPR_REJ};
        Set<String> initRetFinalAttrTypes = new Set<String>{constants.RETAILINITAPPROVAL,constants.RET_FINALAPPROVAL};
        Set<String> initComFinalAttrTypes = new Set<String>{constants.COMMINITAPPROVAL, constants.COMMFINALAPPROVAL};
            List<Opportunity> oppLst = [select ReceiveCertifiedLease__c,DealAchieved__c,AcceptedDisclosureStatement__c,NoofUnApprovedClause__c,Property__r.tier__c,Space__r.Status__c, Name,RentVarianceAmount__c,CapitalVarianceAmount__c,RCAsReviewed__c,AccountId,NoofRCA__c,risksummary__c,recordtypeid,GroupGeneralManagerLARS__c,approvalStatus__c,CapitalVariance__c,RentVariance__c,
                                        property__c,id,RMRetailAdmin__c,RMLARS__c,GMLARS__c,GMRetailAdmin__c,CorporateLegal__c,
                                        DirectorLARSNZDevelopment__c, COO__c,Tech_SpaceType__c, Category__c, MasterAccount__c, Tech_IsCreatedFromGroupRenew__c
                                        from Opportunity where id in: OpportunityLst];
        
        Set<Id> masterAccountSet = new Set<Id>();
        Map<Id,Id> parentAccountMap = new Map<Id,Id>();
        Map<Id,Id> grandParentAccountMap = new Map<Id,Id>();
        Map<Id,Id> parentAccLeasingLeadMap = new Map<Id,Id>();
        Map<Id,Id> grandParentAccLeasingLeadMap = new Map<Id,Id>();
        
        for(Opportunity op : oppLst){
            if(op.property__c!=null){
                propIdSet.add(op.property__c);
            }
            
            accCategorySet.add(op.Category__c);
            
            opportunityAccountIdSet.add(op.AccountId);
            
        }
               
        try{
            accountMap = DatabaseSOQLBank.getAccountById(opportunityAccountIdSet);
        } catch(Exception e){
            accountMap = null;
        }
        
        try{
            oppContractList = DatabaseSOQLBank.getContractByProperty(propIdSet);
        } catch(Exception e){
            oppContractList = null;
        }
        
        if(oppContractList != null){
            for(Contract__c con : oppContractList){
                if(con.Opportunity__c != null){
                    contractOppIdSet.add(con.Opportunity__c);
                    //accCategorySet.add(con.Opportunity__r.Category__c);
                }
            }
        }   
        
        if(accountMap != null){
            for(Account acc : accountMap.values()){
                if(acc.Category__c != null){
                    //accCategorySet.add(acc.Category__c);
                }
                if (acc.ParentId != null) {
                    parentAccountMap.put(acc.Id, acc.ParentId);
                }
                if (acc.Parent.ParentId != null) {
                    grandParentAccountMap.put(acc.Id, acc.Parent.ParentId);
                }
            }
        }
        
        List<AccountTeamMember> parentLeasingLeads = [SELECT Id, UserId, TeamMemberRole, AccountId FROM AccountTeamMember 
                                                      WHERE AccountId IN: parentAccountMap.values() AND TeamMemberRole='Leasing Lead'];
        
        List<AccountTeamMember> grandparentLeasingLeads = [SELECT Id, UserId, TeamMemberRole, AccountId FROM AccountTeamMember 
                                                           WHERE AccountId IN: grandParentAccountMap.values() AND TeamMemberRole='Leasing Lead'];
                                                               
        for (AccountTeamMember accTeamMember : parentLeasingLeads) {
            parentAccLeasingLeadMap.put(accTeamMember.AccountId, accTeamMember.UserId);
        }
        for (AccountTeamMember accTeamMember : grandparentLeasingLeads) {
            grandParentAccLeasingLeadMap.put(accTeamMember.AccountId, accTeamMember.UserId);
        }
        
        
        try{
            highRiskOppClauseList = DatabaseSOQLBank.getHighRiskOppClause(contractOppIdSet, accCategorySet);
        } catch(Exception e){
            highRiskOppClauseList = null;
        }
        
        if(highRiskOppClauseList != null){
            propIdOppIdOppClauseListMap = HighRiskOpportunityClauseUtility.getOppClausePerProperty(highRiskOppClauseList);
        }
        
        ////beyond this
        List<UserRole> usrroleLst = [Select id, name from UserRole where id =: userinfo.getUserRoleId()];
        List<Profile> usrProfileLst = [Select id, name from Profile where id =: userinfo.getProfileId()];        
        if(usrProfileLst.size()>0){
            usrProfile = usrProfileLst[0].name;
        }
        if(usrroleLst.size()>0){
            usrrole = usrroleLst[0].name;
        }

        
        //system.assertnotequals(opplstclause[0].ReferencedClause__r.RiskClauseApprovers__c,opplstclause[0].ReferencedClause__r.RiskClauseApprovers__c);
        for(OpportunityClause__c oppclause: [select Opportunity__c,Type__c,Approved__c,id,ReferencedClause__c,ReferencedClause__r.RiskClauseApprovers__c from OpportunityClause__c where opportunity__c in : OpportunityLst and RiskApplies__c=true AND ReferencedClause__r.RiskClauseApprovers__c != null]){
            if(String.isNotBlank(oppclause.ReferencedClause__r.RiskClauseApprovers__c) && 
               oppclause.ReferencedClause__r.RiskClauseApprovers__c != null && oppclause.Approved__c==false){
                   roleSet.addall((oppclause.ReferencedClause__r.RiskClauseApprovers__c).split(';'));
               }
            if(String.isNotBlank(oppclause.Type__c) && oppclause.Approved__c==false){
                if(oppIdOppClauseSetMap.containskey(oppClause.opportunity__c)){
                    oppIdOppClauseSetMap.get(oppClause.opportunity__c).add(oppClause.Type__c);
                }else{
                    oppIdOppClauseSetMap.put(oppClause.opportunity__c, new Set<String> {oppclause.Type__c});
                }
            }
            
        }
        for(propertyteam__c prop: [select id,teammember__c,role__c from propertyteam__c where property__c in: propIdSet and teammember__c != null AND teammember__r.IsActive=true AND Active__c=true]){
            roleUserMap.put(prop.role__c, prop.teammember__c);
        }
        //system.assertnotequals(roleSet,roleSet);
        System.debug('roleUserMap ' + roleUserMap);
        System.debug('roleSet ' + roleSet);
        System.debug('constants.TEAM_ROLE_GMLEASING ' + constants.TEAM_ROLE_GMLEASING);
        System.debug('roleSet.contains(constants.TEAM_ROLE_GMLEASING) ' + roleSet.contains(constants.TEAM_ROLE_GMLEASING));
        System.debug('roleUserMap.containskey(constants.TEAM_ROLE_GMLEASING ' + roleSet.contains(constants.TEAM_ROLE_GMLEASING));
        

        
        List<OpportunityApprovalMatrix__mdt> oppApprovalMatrix = [Select Tier__c, projectrole__c,RentAmountRange__c,CapitalAmountRange__c,FieldAPIName__c,id,CapitalRange__c,RentRange__c,Role__c,Type__c  from OpportunityApprovalMatrix__mdt];
        for(Opportunity opp: oppLst){
            
            for(OpportunityApprovalMatrix__mdt oppAppMatr : oppApprovalMatrix){
                opp.put(oppAppMatr.fieldAPIName__c,null);
            }
            if(propIdOppIdOppClauseListMap.containsKey(opp.Property__c)&&opp.Tech_SpaceType__c!=Constants.STOREROOM){
                HighRiskOpportunityClauseUtility.countRCA(opp, propIdOppIdOppClauseListMap.get(opp.Property__c));
            }else{
                opp.NoofRCA__c = 0;
            }
            if((opp.RCAsReviewed__c && opp.NoofRCA__c > 0) || opp.NoofRCA__c <= 0){
                opp.risksummary__c = '';
                if(oppRecordTypeById.containsKey(opp.RecordTypeId)){
                    newOppRecordTypeName = oppRecordTypeById.get(opp.RecordTypeId).getName();
                }
                
                for(OpportunityApprovalMatrix__mdt oppAppMatr : oppApprovalMatrix){
                    if(Constants.OPP_RETAIL_LEASING.equalsIgnoreCase(newOppRecordTypeName)){
                        opp = Opportunitybl.getUpdatedRoleOpportunity(thresholdApprStatusSet,opp,oppAppMatr,roleUserMap,allowedRetTypes,roleSet,Constants.OPP_RETAIL_LEASING,
                                                                      initRetFinalAttrTypes);
                    }
                    if(Constants.OPP_COMMERCIAL_LEASING.equalsIgnoreCase(newOppRecordTypeName) && roleUserMap.containskey(oppAppMatr.role__c)){
                        
                        opp = Opportunitybl.getUpdatedRoleOpportunity(thresholdApprStatusSet,opp,oppAppMatr,roleUserMap,allowedComTypes,roleSet,
                                                                      Constants.OPP_COMMERCIAL_LEASING, initComFinalAttrTypes);
                        
                    }
                    if(Constants.OPP_STORE_ROOM_LEASING.equalsIgnoreCase(newOppRecordTypeName) && roleUserMap.containskey(oppAppMatr.role__c)){
                        opp = Opportunitybl.getRoleStoreRoomOpportunity(opp,oppAppMatr,roleUserMap, usrrole, usrProfile);
                    }
                }
                if(oppIdOppClauseSetMap.containskey(opp.id)){
                    for(String sType : oppIdOppClauseSetMap.get(opp.id)){
                        opp.risksummary__c = opp.risksummary__c + sType + ', ';
                    }
                }
                if(String.isNotBlank(opp.risksummary__c)){
                    opp.risksummary__c = opp.risksummary__c.removeEnd(', ');
                }
            }
            // RPP-10589 START: LF 07/16/2019
            system.debug('RPP-10589 Parent Account leasing Lead: ' + parentAccLeasingLeadMap);
            system.debug('RPP-10589 GrandParent Account leasing Lead: ' + grandParentAccLeasingLeadMap);
            system.debug('RPP-10589 Opp Tech_IsCreatedFromGroupRenew__c: ' + opp.Tech_IsCreatedFromGroupRenew__c);
            
            Account acc = accountMap.containsKey(opp.AccountId) ? accountMap.get(opp.AccountId) : null;
           
            Id leasingLeadId = null;
            
            if (acc != null && parentAccLeasingLeadMap.containsKey(acc.ParentId)) {
                leasingLeadId = parentAccLeasingLeadMap.get(acc.ParentId);
            } else if (acc != null && grandParentAccLeasingLeadMap.containsKey(acc.Parent.ParentId)) {
                leasingLeadId = grandParentAccLeasingLeadMap.get(acc.Parent.ParentId);
            }
            
            if (opp.Tech_IsCreatedFromGroupRenew__c && leasingLeadId != null) {
                
                opp.RMLARS__c = leasingLeadId;
                
                if (roleUserMap.containsKey(Constants.TEAM_ROLE_REGLEAMGR_LARS)) {
                    opp.Tech_PropertyRM__c = roleUserMap.get(Constants.TEAM_ROLE_REGLEAMGR_LARS);
                }
                
            }
            system.debug('RPP-10589 RMLARS__c: ' + opp.RMLARS__c);
            system.debug('RPP-10589 Tech_PropertyRM__c: ' + opp.Tech_PropertyRM__c);
            
            // RPP-10589 END: LF 07/16/2019
            // add logic to post chatter message 
            if(!opp.RCAsReviewed__c&&opp.NoofRCA__c>0){
                Set<Id> mentionUsers = new Set<Id>();
                if(roleUserMap.containsKey(Constants.TEAM_ROLE_RMRA)){
                    mentionUsers.add(roleUserMap.get(Constants.TEAM_ROLE_RMRA));
                    //mentionUsers.add(opp.OwnerId);
                    List<String> parameters = new List<String>();
                    //parameters.add(roleUserMap.get(Constants.TEAM_ROLE_RMRA));
                    parameters.add(opp.Name);

                    // prepare data to post message
                    ChatterPostUtil.ChatterNotificationWrapper chatterwrapperItem = new ChatterPostUtil.ChatterNotificationWrapper();
                    chatterwrapperItem.subjectId = opp.id;
                    chatterwrapperItem.body=String.format(Label.ReviewRCAChatterMessage, parameters);
                    chatterwrapperItem.mentionedUsers=mentionUsers;
                    chatterwrapperItemList.add(chatterwrapperItem);
                }
            }
        }
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(UpdateRoleFieldsBaseFromClause.class.getName());
        if(oppLst.size() > 0) {
            try{
                database.update(oppLst);
            } catch(Exception e) {
                errorHandler.createError(e);
            }
            try{
                if(chatterwrapperItemList.size()>0&&!chatterwrapperItemList.isEmpty()){
                    System.debug('chatterwrapperItemList: '+ chatterwrapperItemList);
                    ChatterPostUtil.chatterpostBulk(chatterwrapperItemList);
                }
            } catch(Exception e) {
                errorHandler.createError(e);
            }
        }
        errorHandler.save();
    }
}