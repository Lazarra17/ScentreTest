global class PostChatterToCaseInvoc {
    @InvocableMethod
    public static void postChatterToCase(List<Id> CaseListId) {
        Set<String> roleSet = new Set<String>();
        List<Id> caseOwnerIdList = new List<Id>();     
        List<Id> propIdLst = new List<Id>();
        Map<Id, Id> caseIdPropertyIdMap = new Map<Id, Id>();
        Map<Id, List<Id>> caseIdUsersToNotif = new Map<Id, List<Id>>();
        Map<Id, Map<String,Id>> propertyIdUsersMapMap = new Map<Id, Map<String,Id>>();
        Map<String, List<String>> cseRecTypeRolesMap = new Map<String, List<String>>();
        
        //System.debug('Case Id ' + CaseListId);
        //Instantiate a new ChatterNotification Wrapper list to be passed on ChatterPostUtil.ChatterPostBulk
        List<ChatterPostUtil.chatterNotificationWrapper> chatterLst = new List<ChatterPostUtil.chatterNotificationWrapper>();
        
        
        //System.debug('PropID ' + propIdLst);
        List<Case> caserecLst = [SELECT  Account.Name, Account.BillingStreet, Account.BillingCity, Account.BillingPostalCode, Account.BillingState, Account.BillingCountry,ReleaseOutgoingGuarantor__c,GuaranteeName__c,GuaranteeType__c,RentinAdvance__c,SecurityDeposit__c,
                                 Account.Phone,AccountId,Account.BillingAddress,
                                 SettlementDate__c,AssignmentDate__c,Account.LesseeName__c,Account.TradingName__c,
                                 Description,BasicMinimumRent__c,ReviewDate__c,EffectiveDate__c,ReasonForChange__c,
                                 ProposedRentableArea__c,Id,Space__c,Space__r.property__c,Space__r.Name,Space__r.property__r.Name,RecordType.Name, 
                                 CaseNumber, Type, InvoiceNumber__c, 
                                 Subject, createdBy.Name,  BillCode__c, 
                                 TotalAmountExcludingGST__c, GSTAmount__c,   ReasonForCreditNote__c,
                                 TechFinance__c,
                                 TechGMLeasing__c,
                                 TechRegionalLeasingManager__c,
                                 TechRegionalManager__c,
                                 TechRegionalManagerRetailAdmin__c,
                                 TechRevenueAssurance__c,
                                 TechNSOTeamCoordinator__c,
                                 SubType__c,
                                 SecurityDepositType__c,
                                 OutstandingDebtorBalance__c,
                                 SecurityDepositAmount__c,
                                 CurrentLeaseExpiryDate__c,
                                 ExistingChargeCommencementDate__c,
                                 LAType__c,
                                 SurrenderDate__c,
                                 SurrenderPayoutAmount__c,
                                 SurrenderPayoutAmountTBA__c,
                                 FitoutContributionAmount__c,
                                 TerminateLeaseDate__c,
                                 ReasonForTermination__c,
                                 UnexpiredFitoutAmount__c,
                                 InvoiceAmountCurrentYear__c,
                                 InvoiceAmountPriorYear__c,
                                 CurrentYear__c,
                                 PriorYear__c,
                                 GSTApplicable__c,
                                 ServiceTaxDate__c,
                                 AmountPayableTotal__c,
                                 Amount__c,Contract__c,
                                 Property__c,
                                 InvoiceDescription__c,InvoiceDate__c,
                                 Contract__r.Name,
                                 createdBy.Id,
                                 NewTradingName__c,
                                 SpaceType__c,
                                 Origin
                                 FROM Case WHERE Id in :CaseListId];
        
        for(Case cse : caserecLst){
            
            if(cse.space__c != null && cse.space__r.property__c != null){
                caseIdPropertyIdMap.put(cse.id,cse.space__r.property__c);
                //System.debug('caseIdPropertyIdMap ' + caseIdPropertyIdMap);
                if(cse.RecordType.Name == CONSTANTS.RETAIL_DESIGN_INSTRUCTION){//@[{![Case].TechNSOTeamCoordinator__c}], 
                    
                    if((Label.VoluntaryWorksRolesToChatter.split(';')).size()>0){
                        cseRecTypeRolesMap.put(cse.RecordType.Name,Label.VoluntaryWorksRolesToChatter.split(';'));
                    }
                    
                }else if(cse.RecordType.Name == CONSTANTS.UPDATE_PROMOTIONAL_ALLOWANCE){//@[{![Case].TechGMLeasing__c}],@[{![Case].TechRegionalLeasingManager__c}],  
                    if(cse.Origin == CONSTANTS.CASE_ORIGIN_DEVELOPMENT){
                        if((Label.updatePromoAllowDevtRoleToChatter.split(';')).size()>0){
                            cseRecTypeRolesMap.put(cse.RecordType.Name,Label.updatePromoAllowDevtRoleToChatter.split(';'));
                        }
                    }else{
                        if((Label.updatePromotionalAllowance.split(';')).size()>0){
                            cseRecTypeRolesMap.put(cse.RecordType.Name,Label.updatePromotionalAllowance.split(';'));
                        }
                    }
                }else if(cse.RecordType.Name == CONSTANTS.MISCELLANEOUS_SERVICE){//@[{![Case].TechRegionalManager__c}], cc: @[{![Case].TechCommercialRetailManager__c}], @[{![Case].TECH_CommercialPropertyManager__c}], @[{![Case].TechGMLeasing__c}],
                    if((Label.miscellaneousServiceRoleToChatter.split(';')).size()>0){
                        cseRecTypeRolesMap.put(cse.RecordType.Name,Label.miscellaneousServiceRoleToChatter.split(';'));
                    }
                    
                }else if(cse.RecordType.Name == CONSTANTS.VARIANCE_TO_RENT_COMMENCEMENT){//cc: @[{![Case].TechFinance__c}], @[{![Case].TechTenancyCoordinator__c}], @[{![Case].TechDirectorOfLeasing__c}],@[{![Case].TechRegionalManager__c}], @[{![Case].TechGMLeasing__c}], cc: @[{![Case].TechCommercialRetailManager__c}], @[{![Case].TECH_CommercialPropertyManager__c}], @[{![Case].TechGMLeasing__c}],@[{![Case].TechRegionalManager__c}], 
                    if(cse.SpaceType__c != '3'){
                        if((Label.varToRentCommenceRoleToChatter.split(';')).size()>0){
                            cseRecTypeRolesMap.put(cse.RecordType.Name,Label.varToRentCommenceRoleToChatter.split(';'));
                        }
                    }else{
                        if((Label.varToRentCommencementOffice.split(';')).size()>0){
                            cseRecTypeRolesMap.put(cse.RecordType.Name,Label.varToRentCommencementOffice.split(';'));
                        }
                    }
                }else if(cse.RecordType.Name == CONSTANTS.REQUEST_FOR_REFUND){//finance 
                    if((Label.reqForRefundRoleToChatter.split(';')).size()>0){
                        cseRecTypeRolesMap.put(cse.RecordType.Name,Label.reqForRefundRoleToChatter.split(';'));
                    }
                }else if(cse.RecordType.Name == CONSTANTS.CONDUCT_MARKET_REVIEW){//@[{![Case].TechRegionalLeasingManager__c}], @[{![Case].TechGMLeasing__c}], cc: @[{![Case].TechCommercialRetailManager__c}], @[{![Case].TechLeasingExecutive__c}], @[{![Case].TechDirectorOfLeasing__c}]
                    
                    if((Label.condMarketReviewRoleToChatter.split(';')).size()>0){
                        cseRecTypeRolesMap.put(cse.RecordType.Name,Label.condMarketReviewRoleToChatter.split(';'));
                    }               
                }else if(cse.RecordType.Name == CONSTANTS.CREDIT_NOTE){//@{![Case].TechLeasingExecutive__c}, {![Case].Tech_RetailExperienceManager__c}, {![Case].Tech_CommercialRetailManager__c}, {![Case].Tech_CXManager__c}
                    
                    if((Label.creditNoteRoleToChatter.split(';')).size()>0){
                        cseRecTypeRolesMap.put(cse.RecordType.Name,Label.creditNoteRoleToChatter.split(';'));
                    }
                }else if(cse.RecordType.Name == CONSTANTS.LEASE_AREA_VARIATION){ //@[{![Case].TechRegionalManagerRetailAdmin__c}], @[{![Case].TechRegionalLeasingManager__c}] , @[{![Case].TechCentreManager__c}], @[{![Case].TechCentreManager__c}], @[{![Case].TechLeasingFinanceAnalyst__c}], @[{![Case].TechLeasingExecutive__c}],
                    if((Label.leaseAreVarRoleToChatter.split(';')).size()>0){
                        cseRecTypeRolesMap.put(cse.RecordType.Name,Label.leaseAreVarRoleToChatter.split(';'));
                    }
                }else if(cse.RecordType.Name == CONSTANTS.MANAGE_BANK_GUARANTEE){
                    if(String.isNotBlank(cse.SubType__c)){
                        List<String> subtypereturnexchange=Label.CasesubTypeReturnExchange.split(';'); 
                        if(subtypereturnexchange.contains(cse.SubType__c)){
                            cseRecTypeRolesMap.put(cse.RecordType.Name,Label.SubtypereturnexchangeChatterRole.split(';'));
                        }else if(cse.SubType__c==CONSTANTS.CASE_SUBTYPE_CLAIM_ADMINISTRATION||cse.SubType__c==CONSTANTS.CASE_SUBTYPE_CLAIM){
                            cseRecTypeRolesMap.put(cse.RecordType.Name,Label.BnkGuaranteeClaimAdminRoleToChatter.split(';'));  
                        }else if(cse.SubType__c==CONSTANTS.CASE_SUBTYPE_TRANSFER){
                            cseRecTypeRolesMap.put(cse.RecordType.Name,Label.SubtypeTransferChatterRole.split(';'));  
                        }
                    }  
                }else if(cse.recordType.Name == CONSTANTS.SURRENDER_A_LEASE){
                    if((Label.surrenderLeaseRoleToChatter.split(';')).size()>0){
                        cseRecTypeRolesMap.put(cse.RecordType.Name,Label.surrenderLeaseRoleToChatter.split(';'));
                    }
                }else if(cse.recordType.Name == CONSTANTS.ASSIGN_OF_A_LEASE){
                    if((Label.assignmeantLeaseToChatter.split(';')).size()>0){
                        cseRecTypeRolesMap.put(cse.RecordType.Name,Label.assignmeantLeaseToChatter.split(';'));
                    }
                }else if(cse.recordType.Name == CONSTANTS.TERMINATE_A_LEASE){
                    if(String.isNotBlank(cse.SubType__c)){
                        if(cse.SubType__c==CONSTANTS.CASE_SUBTYPE_LEGALLOCKOUT){
                            cseRecTypeRolesMap.put(cse.RecordType.Name,Label.TerminateALeaseChatterRoleLegalLockout.split(';'));  
                        }else if(cse.SubType__c==CONSTANTS.CASE_SUBTYPE_LEASE_EXPIRED){
                            cseRecTypeRolesMap.put(cse.RecordType.Name,Label.TerminateALeaseChatterRoleLeaseExpired.split(';'));  
                        }else if(cse.SubType__c==CONSTANTS.CASE_SUBTYPE_PRE_EXPIRY_OF_LEASE){
                            cseRecTypeRolesMap.put(cse.RecordType.Name,Label.TerminateALeaseChatterRolePreexpiry.split(';'));  
                        }
                    }
                }else if(cse.recordType.Name == CONSTANTS.TRADING_NAME_CHANGE){
                    if((Label.TradingNameChangeRoleToChatter.split(';')).size()>0){
                        cseRecTypeRolesMap.put(cse.RecordType.Name,Label.TradingNameChangeRoleToChatter.split(';'));
                    }
                }else if(cse.recordType.Name == CONSTANTS.CENTRE_TEAM){
                    if(cse.SubType__c == CONSTANTS.CASE_SUBTYPE_BAD_DEBIT_WRITE_OFF){
                        if((Label.badDebtWriteOffRoleToChatter.split(';')).size()>0){
                            cseRecTypeRolesMap.put(cse.RecordType.Name,Label.badDebtWriteOffRoleToChatter.split(';'));
                        }
                    }else if(cse.SubType__c == CONSTANTS.CASE_SUBTYPE_HOARDING){
                        if((Label.hoardingRoleToChatter.split(';')).size()>0){
                            cseRecTypeRolesMap.put(cse.RecordType.Name,Label.hoardingRoleToChatter.split(';'));
                        }
                    }
                    else if(cse.SubType__c == CONSTANTS.CASE_SUBTYPE_MAILBOX_CHARGES){
                        if((Label.mailboxChargeRoleToChatter.split(';')).size()>0){
                            cseRecTypeRolesMap.put(cse.RecordType.Name,Label.mailboxChargeRoleToChatter.split(';'));
                        }
                    }
                    
                }else if(cse.recordType.Name == CONSTANTS.LEASING_FINANCE){
                    if((Label.LeasingFinanceRoleToChatter.split(';')).size()>0){
                        cseRecTypeRolesMap.put(cse.RecordType.Name,Label.LeasingFinanceRoleToChatter.split(';'));
                    }
                }else if(cse.recordType.Name == CONSTANTS.MISCELLANEOUS_LEASE){
                    if(String.isNotBlank(cse.SubType__c)){
                        if(cse.SubType__c==CONSTANTS.CASE_SUBTYPE_CENTRE){
                            if((Label.MiscellaneousLeaseCentreRoleToChatter.split(';')).size()>0){
                                cseRecTypeRolesMap.put(cse.RecordType.Name,Label.MiscellaneousLeaseCentreRoleToChatter.split(';'));  
                            }
                        }else if(cse.SubType__c==CONSTANTS.CASE_SUBTYPE_LEASING_FINANCE){
                            if((Label.MiscellaneousLeaseLeasingFinanceRoleToChatter.split(';')).size()>0){
                                cseRecTypeRolesMap.put(cse.RecordType.Name,Label.MiscellaneousLeaseLeasingFinanceRoleToChatter.split(';'));  
                            }
                        }
                    }
                }else if(cse.recordType.Name == CONSTANTS.ANCILLARY_TAX_INVOICE){
                    if((Label.AncillaryTaxInvoicesRoleToChatter.split(';')).size()>0){
                        cseRecTypeRolesMap.put(cse.RecordType.Name,Label.AncillaryTaxInvoicesRoleToChatter.split(';'));  
                    }
                }
            }  
        }
        
        for(propertyteam__c propTeam: [select property__c,id,teammember__c,role__c from propertyteam__c where property__c in: caseIdPropertyIdMap.values() and teammember__c != null AND teammember__r.IsActive=true AND Active__c=true]){
            if(propertyIdUsersMapMap.containskey(propTeam.property__c)){
                propertyIdUsersMapMap.get(propTeam.property__c).put(propTeam.role__c,propTeam.teammember__c);
            }else{
                propertyIdUsersMapMap.put(propTeam.property__c,new Map<String,Id>());
                propertyIdUsersMapMap.get(propTeam.property__c).put(propTeam.role__c,propTeam.teammember__c);
            }
        }
        
        for(Case cse2 : caserecLst){
            if(propertyIdUsersMapMap.containskey(caseIdPropertyIdMap.get(cse2.id)) && 
               cseRecTypeRolesMap.containskey(cse2.RecordType.Name)){
                   for(String role : cseRecTypeRolesMap.get(cse2.RecordType.Name)){
                       if(propertyIdUsersMapMap.get(caseIdPropertyIdMap.get(cse2.id)).containskey(role)){
                           if(caseIdUsersToNotif.containskey(cse2.id)){    
                               caseIdUsersToNotif.get(cse2.id).add(propertyIdUsersMapMap.get(caseIdPropertyIdMap.get(cse2.id)).get(role));
                           }else{
                               caseIdUsersToNotif.put(cse2.id,new List<Id>{propertyIdUsersMapMap.get(caseIdPropertyIdMap.get(cse2.id)).get(role)});
                           }
                       }
                   }
               }
        }    
        System.debug('Case ID Users ' + caseIdUsersToNotif);
        if(caseIdUsersToNotif.values().size()>0){
            for(Case cse3 : caserecLst){
                chatterpostutil.chatterNotificationWrapper cp = chatterpostutil.ChatterPostToCaseRecord(cse3, caseIdUsersToNotif);
                chatterLst.add(cp);
            } 
        }         
        if(chatterLst.size() > 0){
            ChatterPostUtil.chatterpostBulk(chatterLst);
        } 
    }
}