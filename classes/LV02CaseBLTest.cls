/*
* @author:              Lean Flores
* @description:         Test class for LV02CaseBL
*/
@isTest
public class LV02CaseBLTest {
    @TestSetup private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Account accountRecord;
        PrecedentClause__c precedentClauseRecord;
        List<Property__c> propertyList = new List<Property__c>();
        List<Account> accountList = new List<Account>();
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        List<PrecedentClause__c> precedentClauseList = new List<PrecedentClause__c>();
        List<User> testUserList = new List<User>();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        
        testUserList.add(TestDataFactory.createUniqueTestUser('Test', 'User 1', profileRec.Id));
        testUserList.add(TestDataFactory.createUniqueTestUser('Test', 'User 2', profileRec.Id));
        
        Database.insert(testUserList);    
        
        //CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(10);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(10, pricebookList[0]);
        database.insert(propertyList);
        propertyList = [SELECT Id FROM Property__c LIMIT 1];
        
        //CREATE ACCOUNT
        accountList.addAll(TestDataFactory.createAccountBulk(100, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId()));
        accountList.addAll(TestDataFactory.createAccountBulk(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId()));
        accountList.addAll(TestDataFactory.createAccountBulk(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(accountList);
        //CREATE PRECEDENT CLAUSE
        accountRecord = [SELECT Id, Name FROM Account WHERE ParentId = null AND RecordTypeId = :accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId() LIMIT 1];
        
        //CREATE ACCOUNTTEAMMEMBER
        List<AccountTeamMember> AccTeamMemberList = new List<AccountTeamMember>();
        AccountTeamMember AccTeamMemberRec = TestDataFactory.createAccountTeamMember(accountList[0].id, testUserList[0].id);
        AccTeamMemberList.add(AccTeamMemberRec);
        database.insert(AccTeamMemberList);
        
        
        
        List<Contract__c> contrList = new List<Contract__c>();
        List<Space__c> spaceLst = TestDataFactory.createSpace(1, propertyList[0]);
        spaceLst[0].type__c = '1';
        database.insert(spaceLst);
        
        contrList = TestDataFactory.createContract(1, accountRecord);
        contrList[0].space__c = spaceLst[0].id;
        database.insert(contrList);
        
        Id internalTeamRecTypeId;
        List<PropertyTeam__c> propertyTeamList = new List<PropertyTeam__c>();
        Map<String,Schema.RecordTypeInfo> propertyTeamRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName('PropertyTeam__c');
        
        internalTeamRecTypeId = propertyTeamRecordTypeMap.get('PRT - Internal Team Member').getRecordTypeId();
        PropertyTeam__c propteam = TestDataFactory.createPropertyTeam(propertyList[0].id, constants.TEAM_ROLE_GMLEASING,  testUserList[0].Id, internalTeamRecTypeId);
        database.insert(propteam);
        
        List<Space__c> spaceList = TestDataFactory.createSpace(20, accountRecord, propertyList[0], contrList[0]);
        Database.insert(spaceList);
        
        //CREATE PROPERTYTEAM
        Map<String, Schema.RecordTypeInfo> PropertyTeamRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.PROPERTYTEAM);
        List<PropertyTeam__c> lstPropertyTeam = new List<PropertyTeam__c>();
        string teamrole = Constants.TEAM_ROLE_RDM;
        PropertyTeam__c PropertyTeamRec = TestDataFactory.createPropertyTeam(propertyList[0].id, teamrole, testUserList[0].id, PropertyTeamRecordTypeMapByName.get(CONSTANTS.PRT_INTERNAL_TEAM_MEMBER).getRecordTypeId());
        //system.debug('Active '+ PropertyTeamRec.Active__c);
        lstPropertyTeam.add(PropertyTeamRec);
        database.insert(lstPropertyTeam);
        //system.debug('Active '+ lstPropertyTeam[0].Active__c);
        //system.debug('EndDate '+ lstPropertyTeam[0].EndDate__c);
        //system.debug('StartDate '+ lstPropertyTeam[0].StartDate__c);
        
        //CREATE Case
        Map<String, Schema.RecordTypeInfo> CaseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.OBJECT_CASE);
        List<Case> lstCase = new List<Case>();
        Case CaseRec1 = TestDataFactory.createCase(contrList[0], spaceLst[0], CaseRecordTypeMapByName.get(CONSTANTS.CASE_RECORDTYPE_INSPECTIONREPORT).getRecordTypeId());
        lstCase.add(CaseRec1);
        Case CaseRec2 = TestDataFactory.createCase(contrList[0], spaceLst[0], CaseRecordTypeMapByName.get(CONSTANTS.RETAIL_DESIGN_BILLING).getRecordTypeId());
        lstCase.add(CaseRec2);
        Case CaseRec3 = TestDataFactory.createCase(contrList[0], spaceLst[0], CaseRecordTypeMapByName.get(CONSTANTS.STATEMENT_OF_COMPLETION).getRecordTypeId());
        lstCase.add(CaseRec3);
        database.insert(lstCase);
        
        
    }
    
    // RPP-10622 LF
    public static testMethod void testCopyVariationToOriginalOpp() {
        Test.startTest();        
        Map<String, Schema.RecordTypeInfo> CaseRecordTypeMapByDevName = RecordTypeUtil.getAllRecordTypesByDeveloperName(CONSTANTS.OBJECT_CASE);
        Account acc = [SELECT Id, Property__c, Property__r.Pricebook__c FROM Account WHERE RecordType.Name=:CONSTANTS.PROPERTY_BASED LIMIT 1];
        Property__c prop= [SELECT Id, PriceBook__c FROM Property__c WHERE Id=:acc.Property__c];
        Space__c spc = [SELECT Id FROM Space__c WHERE Property__c=:prop.Id LIMIT 1];
        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Id=:acc.Property__r.Pricebook__c];
        
        List<Product2> prodList = new List<Product2>();
        
        Product2 contingency = TestDataFactory.createProduct('Contingency', Constants.CAPITAL);
        contingency.CapitalCategory__c = 'Lessor Works';
        Product2 dcc = TestDataFactory.createProduct('D&C Costs (TW)', Constants.CAPITAL);
        dcc.CapitalCategory__c = 'D&C';
        Product2 dbc = TestDataFactory.createProduct('DA/BA/CDC fees', Constants.CAPITAL);
        dbc.CapitalCategory__c = 'Lessor Works';
        Product2 dmg = TestDataFactory.createProduct('Defit/Makegood', Constants.CAPITAL);
        dmg.CapitalCategory__c = 'Lessor Works';
        Product2 efs = TestDataFactory.createProduct('Engineering fees, Structural/Fire/Other', Constants.CAPITAL);
        efs.CapitalCategory__c = 'Lessor Works';
        Product2 rolo = TestDataFactory.createProduct('Extra Over Capped ROLO Costs', Constants.CAPITAL);
        rolo.CapitalCategory__c = 'Lessor Works';
        Product2 hCost = TestDataFactory.createProduct('Hoarding costs', Constants.CAPITAL);
        hCost.CapitalCategory__c = 'Lessor Works';
        Product2 olw = TestDataFactory.createProduct('Other Lessor Works', Constants.CAPITAL);
        olw.CapitalCategory__c = 'Lessor Works';
        
        
        prodList.add(contingency);
        prodList.add(dcc);
        prodList.add(dbc);
        prodList.add(dmg);
        prodList.add(efs);
        prodList.add(rolo);
        prodList.add(hCost);
        prodList.add(olw);
        
        insert prodList;
        
        List<PriceBookEntry> pbeList = new List<PriceBookEntry>();
        
        for (Product2 prod : prodList) {
            PriceBookEntry pbe = TestDataFactory.createPriceBookEntryRecord(prod.Name, prod, pb);
            PriceBookEntry pbe2 = TestDataFactory.createPriceBookEntryRecord(prod.Name, prod, pb);
            pbe2.Pricebook2Id = pb.Id;
            pbeList.addAll(new List<PriceBookEntry>{pbe, pbe2});
        }
        
        insert pbeList;
        
        
        
        Opportunity originalOpp = TestDataFactory.createOpportunityRecord(1, 'Original Opp', 'Understand & Negotiate', acc, pb);
        Opportunity variationOpp = TestDataFactory.createOpportunityRecord(1, 'Variation Opp', 'Understand & Negotiate', acc, pb);
        //OpportunityClause__c usageClause = createOpportunityClause(1, originalOpp);
        //OpportunityClause__c usageClause = createOpportunityClause(1, variationOpp);
        
        originalOpp.AnnualMinimumRent__c=100000;
        originalOpp.FitoutContribution__c=1000;
        originalOpp.ForecastRent__c=1000;
        originalOpp.TotalASRForecastCapital__c=1000;
        
        //variationOpp.DealAchieved__c=true;
        variationOpp.AnnualMinimumRent__c=1;
        variationOpp.FitoutContribution__c=1;
        
        insert (new List<Opportunity>{originalOpp, variationOpp}); 
        
        system.debug('RPP-10622 Original Opp: ' + originalOpp.Id);
        system.debug('RPP-10622 Variation Opp: ' + variationOpp.Id);
        
        List<OpportunityLineItem> capitalProducts = new List<OpportunityLineItem>();
        
        for (PriceBookEntry pbe : pbeList) {
            System.debug('Products: ' + pbe);
            
            if(pbe.Pricebook2Id == pb.Id) {
                OpportunityLineItem capProd = TestDataFactory.createOpportunityLineItem(1, originalOpp, pbe);
                capProd.UnitPrice = 1000;
                capProd.ProductFamily__c = Constants.CAPITAL;
                capProd.CapitalCategory__c = 'Lessor Works';
                capitalProducts.add(capProd);
                
                OpportunityLineItem capProd2 = TestDataFactory.createOpportunityLineItem(1, variationOpp, pbe);
                capProd2.ProductFamily__c = Constants.CAPITAL;
                capProd2.UnitPrice = 2000;
                capProd2.CapitalCategory__c = 'Lessor Works';
                capitalProducts.add(capProd2);
                
            }
            
            
            
        }
        
        
        insert capitalProducts;
        
        
        System.assertNotEquals(null, originalOpp.Id);
        //System.assert(originalOpp.DealAchieved__c, true);
        
        Case sampleCase = new Case(OldOpportunity__c=originalOpp.Id,
                                   Opportunity__c=variationOpp.Id,
                                   RecordTypeId=CaseRecordTypeMapByDevName.get(Constants.LV02_SPECIALTY_VARIATION).getRecordTypeId(),
                                   Status=Constants.CASE_STATUS_COMPLETED,
                                   Capital__c=true,
                                   Rent__c=true
                                  );
        
        List<Opportunity> origOpps = LV02CaseBL.updateOriginalOpps(new List<Case>{sampleCase});
        
        Opportunity variationOppFinal = [SELECT AnnualMinimumRent__c, ForecastRent__c, FitoutContribution__c, TotalASRForecastCapital__c, TotalForecastCapital__c,
                                         TotalLessorWorksCost__c, TotalDCCost__c, TotalFitoutContribution__c
                                         FROM Opportunity WHERE Id=:variationOpp.Id];        
        
        system.debug('RPP-10622 VAR OPP AnnualMinimumRent__c ' + variationOppFinal.AnnualMinimumRent__c);
        system.debug('RPP-10622 VAR OPP ForecastRent__c ' + variationOppFinal.ForecastRent__c);
        system.debug('RPP-10622 VAR OPP FitoutContribution__c ' + variationOppFinal.FitoutContribution__c);
        system.debug('RPP-10622 VAR OPP TotalASRForecastCapital__c ' + variationOppFinal.TotalASRForecastCapital__c);
        system.debug('RPP-10622 VAR OPP TotalForecastCapital__c ' + variationOppFinal.TotalForecastCapital__c);
        system.debug('RPP-10622 VAR OPP TotalLessorWorksCost__c ' + variationOppFinal.TotalLessorWorksCost__c);
        system.debug('RPP-10622 VAR OPP TotalDCCost__c ' + variationOppFinal.TotalDCCost__c);
        system.debug('RPP-10622 VAR OPP TotalFitoutContribution__c ' + variationOppFinal.TotalFitoutContribution__c);  
        
        Opportunity finalOpp = [SELECT AnnualMinimumRent__c, ForecastRent__c, FitoutContribution__c, TotalASRForecastCapital__c, TotalForecastCapital__c,
                                TotalLessorWorksCost__c, TotalDCCost__c, TotalFitoutContribution__c
                                FROM Opportunity WHERE Id=:originalOpp.Id];
        
        system.debug('RPP-10622 FINAL OPP AnnualMinimumRent__c ' + finalOpp.AnnualMinimumRent__c);
        system.debug('RPP-10622 FINAL OPP ForecastRent__c ' + finalOpp.ForecastRent__c);
        system.debug('RPP-10622 FINAL OPP FitoutContribution__c ' + finalOpp.FitoutContribution__c);
        system.debug('RPP-10622 FINAL OPP TotalASRForecastCapital__c ' + finalOpp.TotalASRForecastCapital__c);
        system.debug('RPP-10622 FINAL OPP TotalForecastCapital__c ' + finalOpp.TotalForecastCapital__c);
        system.debug('RPP-10622 FINAL OPP TotalLessorWorksCost__c ' + finalOpp.TotalLessorWorksCost__c);
        system.debug('RPP-10622 FINAL OPP TotalDCCost__c ' + finalOpp.TotalDCCost__c);
        system.debug('RPP-10622 FINAL OPP TotalFitoutContribution__c ' + finalOpp.TotalFitoutContribution__c);
        
        List<OpportunityLineItem> newCapitalProducts = [SELECT Id, Name, TotalPrice, CapitalCategory__c FROM OpportunityLineItem WHERE OpportunityId=:origOpps];
        
        for (OpportunityLineItem capitalProduct : newCapitalProducts) {
            system.debug('RPP-10622 Modified Capital Product: ' + capitalProduct.CapitalCategory__c);
        }
        
        
        // Locked Original Opp Test
        Approval.lock(originalOpp);
        
        System.assert(Approval.isLocked(originalOpp), 'Opportunity not locked for testing');
        
        //variationOpp.DealAchieved__c=true;
        variationOpp.AnnualMinimumRent__c=2;
        variationOpp.FitoutContribution__c=2;
        
        update variationOpp;
        
        origOpps = LV02CaseBL.updateOriginalOpps(new List<Case>{sampleCase});
        
        System.assert(Approval.isLocked(originalOpp), 'Opportunity was not re-locked for testing');
        
        variationOppFinal = [SELECT AnnualMinimumRent__c, ForecastRent__c, FitoutContribution__c, TotalASRForecastCapital__c, TotalForecastCapital__c,
                             TotalLessorWorksCost__c, TotalDCCost__c, TotalFitoutContribution__c
                             FROM Opportunity WHERE Id=:variationOpp.Id];        
        
        system.debug('RPP-10622 LOCKED VAR OPP AnnualMinimumRent__c ' + variationOppFinal.AnnualMinimumRent__c);
        system.debug('RPP-10622 LOCKED VAR OPP ForecastRent__c ' + variationOppFinal.ForecastRent__c);
        system.debug('RPP-10622 LOCKED VAR OPP FitoutContribution__c ' + variationOppFinal.FitoutContribution__c);
        system.debug('RPP-10622 LOCKED VAR OPP TotalASRForecastCapital__c ' + variationOppFinal.TotalASRForecastCapital__c);
        system.debug('RPP-10622 LOCKED VAR OPP TotalForecastCapital__c ' + variationOppFinal.TotalForecastCapital__c);
        system.debug('RPP-10622 LOCKED VAR OPP TotalLessorWorksCost__c ' + variationOppFinal.TotalLessorWorksCost__c);
        system.debug('RPP-10622 LOCKED VAR OPP TotalDCCost__c ' + variationOppFinal.TotalDCCost__c);
        system.debug('RPP-10622 LOCKED VAR OPP TotalFitoutContribution__c ' + variationOppFinal.TotalFitoutContribution__c);  
        
        finalOpp = [SELECT AnnualMinimumRent__c, ForecastRent__c, FitoutContribution__c, TotalASRForecastCapital__c, TotalForecastCapital__c,
                    TotalLessorWorksCost__c, TotalDCCost__c, TotalFitoutContribution__c
                    FROM Opportunity WHERE Id=:originalOpp.Id];
        
        system.debug('RPP-10622 LOCKED FINAL OPP AnnualMinimumRent__c ' + finalOpp.AnnualMinimumRent__c);
        system.debug('RPP-10622 LOCKED FINAL OPP ForecastRent__c ' + finalOpp.ForecastRent__c);
        system.debug('RPP-10622 LOCKED FINAL OPP FitoutContribution__c ' + finalOpp.FitoutContribution__c);
        system.debug('RPP-10622 LOCKED FINAL OPP TotalASRForecastCapital__c ' + finalOpp.TotalASRForecastCapital__c);
        system.debug('RPP-10622 LOCKED FINAL OPP TotalForecastCapital__c ' + finalOpp.TotalForecastCapital__c);
        system.debug('RPP-10622 LOCKED FINAL OPP TotalLessorWorksCost__c ' + finalOpp.TotalLessorWorksCost__c);
        system.debug('RPP-10622 LOCKED FINAL OPP TotalDCCost__c ' + finalOpp.TotalDCCost__c);
        system.debug('RPP-10622 LOCKED FINAL OPP TotalFitoutContribution__c ' + finalOpp.TotalFitoutContribution__c);	
        
        
        // Deal Achieved Opp Test
        Approval.unlock(originalOpp);
        originalOpp.DealAchieved__c=true;
        originalOpp.Space__c = spc.Id;
        originalOpp.Tech_isUpdateFromLV02__c=true;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        update originalOpp;
        system.assert(originalOpp.DealAchieved__c, 'Opportunity DealAchieved__c was not set to true');
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        variationOpp.AnnualMinimumRent__c=3;
        variationOpp.FitoutContribution__c=3;
        
        update variationOpp;
        
        origOpps = LV02CaseBL.updateOriginalOpps(new List<Case>{sampleCase});        
        
        variationOppFinal = [SELECT AnnualMinimumRent__c, ForecastRent__c, FitoutContribution__c, TotalASRForecastCapital__c, TotalForecastCapital__c,
                             TotalLessorWorksCost__c, TotalDCCost__c, TotalFitoutContribution__c
                             FROM Opportunity WHERE Id=:variationOpp.Id];        
        
        system.debug('RPP-10622 DA VAR OPP AnnualMinimumRent__c ' + variationOppFinal.AnnualMinimumRent__c);
        system.debug('RPP-10622 DA VAR OPP ForecastRent__c ' + variationOppFinal.ForecastRent__c);
        system.debug('RPP-10622 DA VAR OPP FitoutContribution__c ' + variationOppFinal.FitoutContribution__c);
        system.debug('RPP-10622 DA VAR OPP TotalASRForecastCapital__c ' + variationOppFinal.TotalASRForecastCapital__c);
        system.debug('RPP-10622 DA VAR OPP TotalForecastCapital__c ' + variationOppFinal.TotalForecastCapital__c);
        system.debug('RPP-10622 DA VAR OPP TotalLessorWorksCost__c ' + variationOppFinal.TotalLessorWorksCost__c);
        system.debug('RPP-10622 DA VAR OPP TotalDCCost__c ' + variationOppFinal.TotalDCCost__c);
        system.debug('RPP-10622 DA VAR OPP TotalFitoutContribution__c ' + variationOppFinal.TotalFitoutContribution__c);  
        
        finalOpp = [SELECT AnnualMinimumRent__c, ForecastRent__c, FitoutContribution__c, TotalASRForecastCapital__c, TotalForecastCapital__c,
                    TotalLessorWorksCost__c, TotalDCCost__c, TotalFitoutContribution__c, Tech_isUpdateFromLV02__c
                    FROM Opportunity WHERE Id=:originalOpp.Id];
        
        system.debug('RPP-10622 DA FINAL OPP AnnualMinimumRent__c ' + finalOpp.AnnualMinimumRent__c);
        system.debug('RPP-10622 DA FINAL OPP ForecastRent__c ' + finalOpp.ForecastRent__c);
        system.debug('RPP-10622 DA FINAL OPP FitoutContribution__c ' + finalOpp.FitoutContribution__c);
        system.debug('RPP-10622 DA FINAL OPP TotalASRForecastCapital__c ' + finalOpp.TotalASRForecastCapital__c);
        system.debug('RPP-10622 DA FINAL OPP TotalForecastCapital__c ' + finalOpp.TotalForecastCapital__c);
        system.debug('RPP-10622 DA FINAL OPP TotalLessorWorksCost__c ' + finalOpp.TotalLessorWorksCost__c);
        system.debug('RPP-10622 DA FINAL OPP TotalDCCost__c ' + finalOpp.TotalDCCost__c);
        system.debug('RPP-10622 DA FINAL OPP TotalFitoutContribution__c ' + finalOpp.TotalFitoutContribution__c);	        
        
        system.assert(!finalOpp.Tech_isUpdateFromLV02__c, 'Tech_isUpdateFromLV02__c was not set to false after update');
        
        Test.stopTest();
    }
    
    public static testMethod void testUnlockVarOpps() {
        
        Test.startTest();
        Map<String, Schema.RecordTypeInfo> CaseRecordTypeMapByDevName = RecordTypeUtil.getAllRecordTypesByDeveloperName(CONSTANTS.OBJECT_CASE);
        Account acc = [SELECT Id, Property__c, Property__r.Pricebook__c FROM Account WHERE RecordType.Name=:CONSTANTS.PROPERTY_BASED LIMIT 1];
        Opportunity variationOpp = TestDataFactory.createOpportunity(1, acc).get(0);
        insert variationOpp;
        
        Approval.lock(variationOpp);
        
        system.assert(Approval.isLocked(variationOpp), 'Opportunity not locked.');
        
        Case sampleCase = new Case(
                                   Opportunity__c=variationOpp.Id,
                                   RecordTypeId=CaseRecordTypeMapByDevName.get(Constants.LV02_SPECIALTY_VARIATION).getRecordTypeId(),
                                   Status=Constants.CASE_STATUS_NEW
                                  );
        insert sampleCase;
        
        sampleCase.Status = Constants.CASE_STATUS_COMPLETED_REJECTED;
        
        TriggerHandler.clearAllBypasses();
        update sampleCase;
        
        //LV02CaseBL.unlockVariationOpps(new List<Case>{sampleCase});
        
        Test.stopTest();
        
        system.assert(!Approval.isLocked(variationOpp), 'Opportunity is locked.');
        
        
    }
    
    
}