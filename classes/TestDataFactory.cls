/**
** Comments: This utility class contains reusable methods in creating test data for test classes.
** Date Provided: 13-04-2018
** Owner: Accenture PLC
** Confidential. This document incorporates information that is proprietary to Accenture. 
** The Accenture information in this document is supplied in confidence and, except for any purposes agreed by the parties, 
** should not be disclosed, duplicated or otherwise revealed in whole or in part without the prior written consent of Accenture
**/
@isTest
public class TestDataFactory{
    
    /*
* @author:         Kyle Tan
* @description:    create account
*/
    public static Account createAccount(Integer counter, Id propertyId, Id recordTypeId){        
        Account acc = new Account(
            Name = 'Test Account ' + (counter + 1),
            Type = 'Retailer',
            Property__c = propertyId,
            TradingName__c = 'ABCZ ' + (counter + 1),
            RecordTypeId = recordTypeId,
            ShippingCountry = 'Australia',
            ShippingStreet = '1234 Test Street Drive',
            ShippingCity = 'Sydney',
            ShippingState = 'Queensland',
            ShippingPostalCode = '1234',
            Category__c = 'S420',
            LesseeName__c = 'Test Lessee ' + (counter + 1),
            SuperfineCategory__c = 'S421'); //Used in OppLineItemTriggerHandlerTest
        
        
        return acc;
    }
    public static Account createAccount(Integer counter){        
        Account acc = new Account(
            Name = 'Test Account ' + (counter + 1),
            Type = 'Retailer',
            TradingName__c = 'ABCZ ' + (counter + 1),
            ShippingCountry = 'Australia',
            ShippingStreet = '12345 Test Street Drive',
            ShippingCity = 'Sydney',
            ShippingState = 'Queensland',
            ShippingPostalCode = '2000',
            Category__c = 'S420',
            LesseeName__c = 'Test Lessee ' + (counter + 1),
            SuperfineCategory__c = 'S421');
        
        return acc;
    }
    /*
* @author:            Kyle Tan
* @description:       return account list
*/
    public static List<Account> createAccountBulk(Integer counter, Id propertyId, Id recordTypeId){
        List<Account> accountList = new List<Account>();
        Account acc;
        
        for(Integer i = 0; i < counter ; i++) {
            acc = new Account();
            acc.Name = 'Test Account ' + (i + 1);
            acc.Type = 'Retailer';
            acc.Property__c = propertyId;
            acc.TradingName__c = 'ABCZ ' + (i + 1);
            acc.RecordTypeId = recordTypeId;
            acc.ShippingCountry = 'Australia';
            acc.ShippingStreet = '1234 Test Street Drive';
            acc.ShippingCity = 'Sydney';
            acc.ShippingState = 'Queensland';
            acc.ShippingPostalCode = '1234';
            acc.BillingCountry = 'Australia';
            acc.BillingStreet = '1234 Test Street Drive';
            acc.BillingCity = 'Sydney';
            acc.BillingState = 'Queensland';
            acc.BillingPostalCode = '1234';
            acc.BillingEmailAddress__c = 'testemail@address.com';
            acc.ACN__c = 'ACN' + (i + 1);
            acc.Category__c = 'S420';
            acc.SuperfineCategory__c = 'S421';
            acc.LesseeName__c = 'Test Lessee ' + (i + 1);
            
            accountList.add(acc);
        }
        
        return accountList;
    }
    
    /*
* @author:                 Kyle Tan
* @description:            create account with ParentId
*/
    public static Account createAccountwithParent(Integer counter, Id propertyId, Id recordTypeId, Id parentId){
        Account acc = new Account(
            Name = 'Test Account with Parent ' + (counter + 1),
            Type = 'Retailer',
            ParentId = parentId,
            Property__c = propertyId,
            TradingName__c = 'XYZA ' + (counter + 1),
            RecordTypeId = recordTypeId,
            ShippingCountry = 'Australia',
            ShippingStreet = '1234 Test Street Drive',
            ShippingCity = 'Syndey',
            ShippingState = 'Queensland',
            ShippingPostalCode = '1234',
            Category__c = 'S420',
            SuperfineCategory__c = 'S421',
            LesseeName__c='Test Lessee ' + (counter + 1));
        
        return acc;
    }
    
    public static Contact createContact(String name, Account acc){        
        Contact con = new Contact();
        con.AccountId = acc.id;
        con.FirstName = name;
        con.LastName = name;
        con.Title = 'Sample Position';
        con.email = 'test@test.test';
        
        return con;
    }    
    
    public static Contact createContact(String name, Account acc, Id recordTypedId){
        //Map<String,Id> contactRecordTypes = getRecordType('Contact');
        Contact con = new Contact();
        //con.RecordTypeId = recordTypedId;
        con.AccountId = acc.id;
        con.LastName = name;
        con.Title = 'Sample Position';
        con.email = 'test@test.test';
        
        return con;
    }
    
    public static List<PricebookEntry> createStandardPriceBookEntry(Integer num, Product2 prod){
        List<PricebookEntry> standardPbEntryList = new List<PricebookEntry>();
        for(Integer i=0;i<num;i++){
            PricebookEntry standardPbEntry = new PricebookEntry();
            standardPbEntry.IsActive = true;
            standardPbEntry.Pricebook2Id = Test.getStandardPricebookId();
            standardPbEntry.Product2Id = prod.Id;
            standardPbEntry.UnitPrice = 10000.00;
            standardPbEntry.CurrencyIsoCode = 'AUD';
            standardPbEntry.UseStandardPrice = false;
            standardPbEntryList.add(standardPbEntry);
        }
        return standardPbEntryList;
    } 
    
    public static List<PricebookEntry> createPriceBookEntry(Integer num, Pricebook2 pb, Product2 prod){
        List<PricebookEntry> pbEntryList= new List<PricebookEntry>();
        for(Integer i=0;i<num;i++){
            PricebookEntry pbEntry = new PricebookEntry();
            pbEntry.IsActive = true;
            pbEntry.Pricebook2Id = Test.getStandardPricebookId();
            pbEntry.Product2Id = prod.Id;
            pbEntry.UnitPrice = 10500.00;
            pbEntry.CurrencyIsoCode = 'AUD';
            pbEntry.UseStandardPrice = true; 
            pbEntryList.add(pbEntry);
        }
        return pbEntryList;
    }
    
    public static List<Campaign> createCampaign(Integer num){
        List<Campaign> campList = new List<Campaign>();
        for(Integer i=0;i<num;i++){
            Campaign camp = new Campaign();
            camp.Name = 'Campaign Name'+i;
            camp.Type = 'National Campaigns';
            campList.add(camp);
        }
        return campList;
    }
    
    public static List<CampaignMember> createCampaignMember(Integer num, Campaign camp){
        List<CampaignMember> campMemList = new List<CampaignMember>();
        for(Integer i=0;i<num;i++){
            CampaignMember campMem = new CampaignMember();
            campMem.CampaignId = camp.Id;
            campMemList.add(campMem);
        }
        return campMemList;
    }
    
    public static List<Opportunity> createOpportunity(Integer num, String name, String stageName, Account acc, Pricebook2 pb){
        List<Opportunity> oppList = new List<Opportunity>();
        
        for(Integer i=0;i<num;i++){
            Opportunity opp = new Opportunity();
            opp.StageName = stageName;
            opp.AccountId = acc.Id;
            opp.Name = name+i;
            opp.Closedate = date.today()+5;
            opp.Pricebook2 = pb;
            opp.AnnualMinimumRent__c = 5;
            opp.PercentageRentPercent__c = 5;
            opp.PercentageRentPercent__c = 40;
            opp.ProposedStartDate__c = date.today();
            opp.ProposedEndDate__c = date.today() + 10;
            opp.ProposedRentCommencementDate__c = date.today();
            opp.RentInAdvance__c = 5;
            opp.SecurityDeposit__c = 5;
            opp.Property__c = acc.Property__c;
            opp.Pricebook2Id = Test.getStandardPricebookId();
            oppList.add(opp);
        }
        
        return oppList;
    }
    
    public static List<Lead> createLead(Integer num, Id recordTypeId, Property__c property, Space__c space){
        List<Lead> leadList = new List<Lead>();
        
        for(Integer i=0; i < num; i++){
            Lead l = new Lead();
            //l.RecordTypeId = recordTypeId;
            l.LastName = generateRandomString(15)+i;
            l.FirstName = generateRandomString(15)+i;
            l.Company = 'test Company ' +i;
            l.Status = 'New';
            l.Email = 'test'+i+'@test.com'; 
            l.State = 'New South Wales';
            l.Phone = '12345678'+i;
            l.Property__c = property.Id;
            l.Space__c = space.Id;
            l.Street = '123 ABC' + i;
            l.City = 'Sydney' + i;
            l.Country = 'Australia';
            l.PostalCode = '1234' + i;
            l.State = 'Queensland';
            l.Category__c = 'S420';
            l.SuperfineCategory__c = 'S421';
            l.LesseeName__c = 'Test Lessee Name';
            l.Usage__c = 'Test Usage';
            leadList.add(l);
        }
        
        return leadList;
    }
    
    public static List<Contact> createContactList(Integer num, String name, Account acc, Id recordTypeId){
        List<Contact> conList = new List<Contact>();
        
        for(Integer i=0;i<num;i++){
            Contact con = new Contact();
            //con.RecordTypeId = recordTypeId;
            con.AccountId = acc.id;
            con.LastName = name+num;
            con.Phone = '040720068'+i;
            con.Title = 'Sample Position';
            con.Email = 'test' + i + '@test.test';
            conList.add(con);
        }
        
        return conList;
    }
    public static List<Property__c> createProperty(Integer counterLimit, Pricebook2 pb) {
        Property__c propertyRecord;
        List<Property__c> propertyList = new List<Property__c>();
        
        for(Integer counter = 0; counter < counterLimit; counter++) {
            propertyRecord = new Property__c();
            propertyRecord.Name = 'Test Property ' + (counter + 1);
            propertyRecord.PropertyShortName__c = 'ABC ' + (counter + 1);
            propertyRecord.PriceBook__c = pb.Id;
            propertyRecord.CurrencyIsoCode = pb.CurrencyIsoCode;
            propertyList.add(propertyRecord);
        }
        return propertyList;
    }
    
    /*
* @author:                 Clark Garde
* @description:            create pricebook
*/
    public static List<Pricebook2> createPricebook(Integer counterLimit) {
        Pricebook2 pricebookRecord;
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        
        for(Integer counter = 0; counter < counterLimit; counter++) {
            pricebookRecord = new Pricebook2();
            pricebookRecord.Name = 'Test Pricebook';
            pricebookRecord.CurrencyIsoCode = 'AUD';
            pricebookRecord.IsActive = true;
            pricebookList.add(pricebookRecord);
        }
        return pricebookList;
    }
    /*
* @author:                 Clark Garde
* @description:            create Property with pricebook
*/
    public static List<Property__c> createProperty(Integer counterLimit) {
        Property__c propertyRecord;
        List<Property__c> propertyList = new List<Property__c>();
        
        for(Integer counter = 0; counter < counterLimit; counter++) {
            propertyRecord = new Property__c();
            propertyRecord.Name = 'Test Property ' + (counter + 1);
            propertyRecord.PropertyShortName__c = 'ABC ' + (counter + 1);
            propertyList.add(propertyRecord);
        }
        return propertyList;
    }
    
    public static List<Property__c> createProperty(Integer counterLimit, Space__c spa) {
        Property__c propertyRecord;
        List<Property__c> propertyList = new List<Property__c>();
        
        for(Integer counter = 0; counter < counterLimit; counter++) {
            propertyRecord = new Property__c();
            propertyRecord.Name = 'Test Property ' + (counter + 1);
            propertyRecord.PropertyShortName__c = 'ABC ' + (counter + 1);
            propertyList.add(propertyRecord);
        }
        return propertyList;
    }
    /*   public static List<Property__c> createProperty(Integer counterLimit, List<Space__c> spa) {
Property__c propertyRecord;
List<Property__c> propertyList = new List<Property__c>();

for(Integer counter = 0; counter < counterLimit; counter++) {
propertyRecord = new Property__c();
propertyRecord.Name = 'Test Property ' + (counter + 1);
propertyRecord.PropertyShortName__c = 'ABC ' + (counter + 1);
propertyList.add(propertyRecord);
}
return propertyList;
}
*/
    
    public static User sysAdministrator(){
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt', Email='kperry@acn.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='blahblahblah11@test.com');
        return u;
    }
    
    public static User createUniqueTestUser(String fName, String lName, Id profId){
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User tuser = new User(  firstname = fName,
                              lastName = lName,
                              email = uniqueName + '@test' + orgId + '.org',
                              Username = uniqueName + '@test' + orgId + '.org',
                              EmailEncodingKey = 'ISO-8859-1',
                              Alias = uniqueName.substring(18, 23),
                              TimeZoneSidKey = 'America/Los_Angeles',
                              LocaleSidKey = 'en_US',
                              LanguageLocaleKey = 'en_US',
                              ProfileId = profId,
                              IsActive = TRUE
                              
                             );
        
        
        
        return tuser;
    }    
    
    public static OpportunityContactRole createOpportunityContactRole(Opportunity opp, Contact con, String role){
        OpportunityContactRole oppConRole = new OpportunityContactRole(
            Role = role,
            Contactid = con.id,
            OpportunityId = opp.id
        );
        return oppConRole;
    }
    
    public static List<Case> createCase(Integer num, Contact con){
        List<Case> caseList = new List<Case>();
        for(Integer i=0;i<num;i++){
            Case cas = new Case();
            cas.ContactId = (con != null)? con.Id : null;
            cas.Status = 'New';
            cas.Origin = 'Phone';
            caseList.add(cas);
        }
        return caseList;
    }
    
    private static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
    
    /*
* Method Name:         createPrecedentClause
* Last Modified Date:  5/8/2018
* Last Modified By:    Kyle Tan
* Description:         create Precedent Clause that is linked to an account
*/    
    public static PrecedentClause__c createPrecedentClause(Integer counter, Id accountId) {
        PrecedentClause__c precedentClauseRecord = new PrecedentClause__c(
            Account__c = accountId,
            Comments__c = 'Test Comments' + counter,
            Description__c = 'Test Description' + counter,
            EffectiveToDate__c = date.today(),
            Status__c = 'Active',
            Type__c = 'Usage',
        	Nil_Holdover_Increase__c = true);
        
        return precedentClauseRecord;
    }
    
    /*
* @author:             Kyle Tan
* @description:        create opportunity that is linked to an account
*/    
    public static List<Opportunity> createOpportunity(List<Account> accountList) {
        Opportunity opportunityRecord;
        List<Opportunity> opportunityList = new List<Opportunity>();
        
        for(Integer counter = 0; counter < accountList.size(); counter++) {
            opportunityRecord = new Opportunity();
            opportunityRecord.Name = 'Test Name' + counter;
            opportunityRecord.AccountId = accountList.get(counter).Id;
            opportunityRecord.StageName = Constants.UNDERSTAND_NEGOTIATE;
            opportunityRecord.CloseDate = date.today() + 10;
            opportunityRecord.ProposedStartDate__c = date.today();
            opportunityRecord.ProposedEndDate__c = date.today() + 10;
            opportunityRecord.TermYr__c = 2;
            opportunityRecord.Property__c = accountList.get(counter).Property__c;
            opportunityList.add(opportunityRecord);
            
        }
        return opportunityList;
    }
    
    
    
    public static Opportunity createOpportunityRecord(Integer counter, List<Account> accountList) {
        Opportunity opportunityRecord;
        opportunityRecord = new Opportunity();
        opportunityRecord.Name = 'Test Name' + counter;
        opportunityRecord.AccountId = accountList.get(counter).Id;
        opportunityRecord.StageName = Constants.UNDERSTAND_NEGOTIATE;
        opportunityRecord.CloseDate = date.today() + 10;
        opportunityRecord.ProposedStartDate__c = date.today();
        opportunityRecord.ProposedEndDate__c = date.today() + 10;
        opportunityRecord.TermYr__c = 2;
        opportunityRecord.Property__c = accountList.get(counter).Property__c;
        return opportunityRecord;
    }
    
    public static List<Opportunity> createOpportunity(Integer count, Account acc, List<Property__c> propertyList, List<Space__c> spaceList) {
        Opportunity opportunityRecord;
        List<Opportunity> opportunityList = new List<Opportunity>();
        
        for(Integer counter = 0; counter < count; counter++) {
            opportunityRecord = new Opportunity();
            opportunityRecord.Name = 'Test Name' + counter;
            opportunityRecord.AccountId = acc.Id;
            opportunityRecord.StageName = Constants.UNDERSTAND_NEGOTIATE;
            opportunityRecord.CloseDate = date.today() + 10;
            opportunityRecord.ProposedStartDate__c = date.today();
            opportunityRecord.ProposedEndDate__c = date.today() + 10; 
            opportunityRecord.TermYr__c = 2;
            opportunityRecord.Property__c= acc.Property__c;          
            opportunityRecord.Space__c = spaceList.get(counter).Id;
            opportunityList.add(opportunityRecord);
        }
        return opportunityList;
    }
    public static List<Opportunity> createOpportunity(Integer count, Account account) {
        Opportunity opportunityRecord;
        List<Opportunity> opportunityList = new List<Opportunity>();
        
        for(Integer counter = 0; counter < count; counter++){
            opportunityRecord = new Opportunity();
            opportunityRecord.Name = 'Test Name ' + counter;
            opportunityRecord.AccountId = account.Id;
            opportunityRecord.StageName = Constants.UNDERSTAND_NEGOTIATE;
            opportunityRecord.CloseDate = date.today() + 10;      //      opportunityRecord.CurrentLeaseVirtualVacancy__c = 'VH - Virtual Vacancy High (Within 3 weeks)';
            opportunityRecord.CurrencyIsoCode = 'AUD';
            opportunityRecord.ProposedStartDate__c = date.today();
            opportunityRecord.ProposedEndDate__c = date.today() + 10;
            opportunityRecord.ProposedRentCommencementDate__c = date.today();
            opportunityRecord.RentInAdvance__c = 100;
            opportunityRecord.SecurityDeposit__c = 100;
            opportunityRecord.Property__c = account.Property__c;
            
            opportunityList.add(opportunityRecord);   
        }
        
        return opportunityList;
    }
    public static List<Opportunity> createOpportunity(Integer count, Account acc, Property__c prop,Space__c spa) {
        Opportunity opportunityRecord;
        List<Opportunity> opportunityList = new List<Opportunity>();
        
        for(Integer counter = 0; counter < count; counter++){
            opportunityRecord = new Opportunity();
            opportunityRecord.Name = 'Test Name ' + counter;
            opportunityRecord.AccountId = acc.Id;
            opportunityRecord.StageName = Constants.UNDERSTAND_NEGOTIATE;
            opportunityRecord.CloseDate = date.today() + 10;
            opportunityRecord.ProposedStartDate__c = date.today();
            opportunityRecord.ProposedRentCommencementDate__c = date.today();
            opportunityRecord.RentInAdvance__c = 100;
            opportunityRecord.SecurityDeposit__c = 100;
            opportunityRecord.Property__c = acc.Property__c;
            opportunityRecord.Space__c = spa.Id;
            
            opportunityList.add(opportunityRecord);   
        }
        
        return opportunityList;
    }
    
    /*
* @author:             Miguel Paguio
* @description:        create opportunity that has a property id and account id
*/    
    public static List<Opportunity> createOpportunity(Integer count, Account account, Property__c property) {
        Opportunity opportunityRecord;
        List<Opportunity> opportunityList = new List<Opportunity>();
        
        for(Integer counter = 0; counter < count; counter++){
            opportunityRecord = new Opportunity();
            opportunityRecord.Name = 'Test Name ' + counter;
            opportunityRecord.AccountId = account.Id;
            opportunityRecord.StageName = Constants.UNDERSTAND_NEGOTIATE;
            opportunityRecord.Property__c = account.Property__c;
            opportunityRecord.CloseDate = date.today() + 10;
            opportunityRecord.PromotionalAllowance__c = 1000;
            //opportunityRecord.Property__r.Name = 'Test';
            opportunityRecord.DealType__c = Constants.OPP_LINEITEM_NET;
            opportunityList.add(opportunityRecord);   
        }
        
        return opportunityList;
    }
    
    public static List<Opportunity> createOpportunity(Integer count, Account account, Property__c property, User users) {
        Opportunity opportunityRecord;
        List<Opportunity> opportunityList = new List<Opportunity>();
        
        for(Integer counter = 0; counter < count; counter++){
            opportunityRecord = new Opportunity();
            opportunityRecord.Name = 'Test Name ' + counter;
            opportunityRecord.AccountId = account.Id;
            opportunityRecord.StageName = Constants.UNDERSTAND_NEGOTIATE;
            opportunityRecord.Property__c = account.Property__c;
            opportunityRecord.CloseDate = date.today() + 10;
            opportunityRecord.PromotionalAllowance__c = 1000;
            opportunityRecord.ApprovalStatus__c = 'Pending Initial Approval';
            opportunityRecord.GroupGeneralManagerLARS__c = users.Id;
            opportunityList.add(opportunityRecord);   
        }
        
        return opportunityList;
    }
    
    /*
* @author:             Kyle Tan
* @description:        create multiple opportunities with one account
*/    
    public static List<Opportunity> createOpportunity(Integer opportunitySize, Id accountId) {
        Opportunity opportunityRecord;
        List<Opportunity> opportunityList = new List<Opportunity>();
        
        for(Integer counter = 0; counter < opportunitySize; counter++) {
            opportunityRecord = new Opportunity();
            opportunityRecord.Name = 'Test Name' + counter;
            opportunityRecord.AccountId = AccountId;
            opportunityRecord.StageName = Constants.UNDERSTAND_NEGOTIATE;
            opportunityRecord.CloseDate = date.today() + 10;
            opportunityRecord.ProposedStartDate__c = date.today();
            opportunityRecord.ProposedEndDate__c = date.today() + 10;
            opportunityRecord.TermYr__c = 2;
            opportunityRecord.CurrencyIsoCode = 'AUD';
            opportunityList.add(opportunityRecord);
        }
        
        return opportunityList;
    }
    public static List<Opportunity> createOpportunity(Integer opportunitySize, Id accountId, PrecedentClause__c precRec) {
        Opportunity opportunityRecord;
        List<Opportunity> opportunityList = new List<Opportunity>();
        
        for(Integer counter = 0; counter < opportunitySize; counter++) {
            opportunityRecord = new Opportunity();
            opportunityRecord.Name = 'Test Name' + counter;
            opportunityRecord.AccountId = AccountId;
            //opportunityRecord.StageName = Constants.UNDERSTAND_NEGOTIATE;
            opportunityRecord.StageName = Constants.OPPORTUNITYSTAGE_ISSUE_LEASE;
            opportunityRecord.CloseDate = date.today() + 10;
            opportunityRecord.ProposedStartDate__c = date.today();
            opportunityRecord.ProposedEndDate__c = date.today() + 10;
            opportunityRecord.TermYr__c = 2;
            opportunityRecord.CurrencyIsoCode = 'NZD';
            opportunityRecord.NationalAgreement__c = precRec.Id;
            //10705
            opportunityRecord.ProposedRentCommencementDate__c = date.today();
            opportunityRecord.RentInAdvance__c = 5;
            opportunityRecord.SecurityDeposit__c = 5;
            opportunityRecord.PromoLevyIncluded__c = 'No';
            //10705
            opportunityList.add(opportunityRecord);
        }
        
        return opportunityList;
    }
    public static List<ClauseLibrary__c> createClauseLibrary(Integer count){
        List<ClauseLibrary__c> clauseLibList = new List<ClauseLibrary__c>();
        
        for(Integer counter = 0; counter < count; counter++){
            ClauseLibrary__c clauseLibRecord = new ClauseLibrary__c();
            clauseLibRecord.Name = 'Clause Library' + (counter +1);
            clauseLibRecord.Type__c = 'Usage';
            clauseLibRecord.ClauseDetails__c = 'This is a clause detail';
            clauseLibRecord.RiskApplies__c = true;
            clauseLibRecord.ActivatedDate__c = System.today();
            clauseLibRecord.Status__c = Constants.ACTIVE;
            clauseLibRecord.SubType__c = 'Usage';
            clauseLibRecord.RiskClauseApprovers__c = 'Chief Operating Officer';
            clauseLibList.add(clauseLibRecord);
        }
        
        return clauseLibList;
    }
    public static List<OpportunityClause__c> createOpportunityClause(Integer count, Opportunity opp, ClauseLibrary__c clauseLib){
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>();
        
        for(Integer counter = 0; counter < count; counter++){
            OpportunityClause__c oppClauseRecord = new OpportunityClause__c();
            oppClauseRecord.Name = 'Opportunity Clause' + (counter + 1);
            oppClauseRecord.ClauseDetails__c = 'Sample detail';
            oppClauseRecord.ReferencedClause__c = clauseLib.Id ;
            oppClauseRecord.RiskApplies__c = true;
            oppClauseRecord.Opportunity__c = opp.Id;
            oppClauseRecord.Approved__c = false;
            oppClauseRecord.ReasonRecommendation__c = 'Sample';
            oppClauseRecord.Type__c = 'Usage';
            oppClauseList.add(oppClauseRecord);
        }
        
        return oppClauseList;
    }
    public static List<OpportunityClause__c> createOpportunityClause(Integer count, Opportunity opp){
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>();
        
        for(Integer counter = 0; counter < count; counter++){
            OpportunityClause__c oppClauseRecord = new OpportunityClause__c();
            oppClauseRecord.Name = 'Opportunity Clause' + (counter + 1);
            oppClauseRecord.ClauseDetails__c = 'Sample detail';
            oppClauseRecord.RiskApplies__c = true;
            oppClauseRecord.Opportunity__c = opp.Id;
            
            oppClauseList.add(oppClauseRecord);
        }
        
        return oppClauseList;
    }
    public static List<OpportunityClause__c> createOpportunityClause(Integer count, Opportunity opp, ClauseLibrary__c clauseLib, PrecedentClause__c precClause){
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>();
        
        for(Integer counter = 0; counter < count; counter++){
            OpportunityClause__c oppClauseRecord = new OpportunityClause__c();
            oppClauseRecord.Name = 'Opportunity Clause' + (counter + 1);
            oppClauseRecord.ClauseDetails__c = 'Sample detail';
            oppClauseRecord.RiskApplies__c = true;
            oppClauseRecord.Opportunity__c = opp.Id;
            
            oppClauseList.add(oppClauseRecord);
        }
        
        return oppClauseList;
    }
    
    public static List<Space__c> createSpace(Integer count, Property__c property){
        Space__c spaceTemp;
        List<Space__c> spaceList = new List<Space__c>();
        
        for(Integer counter = 0; counter < count; counter++){
            spaceTemp = new Space__c();
            spaceTemp.Name = 'Sp' + (counter);
            //spaceTemp.SpaceUID__c = 'Space' + (counter + 1);
            spaceTemp.Property__c = property.Id;
            spaceTemp.Type__c = '1';
            spaceTemp.Status__c = 'New';
            spaceTemp.OccupancyStatus__c = Constants.SPACE_OCCUPANCYSTATUS_LBNT;
            spaceTemp.BillingCategory__c = 'NA';
            spaceTemp.RentableArea__c = 555.00;
            spaceTemp.UsableArea__c = 555.00;
            // -- 5/2/2019
            spaceTemp.MainFloor__c = '0';
            
            spaceList.add(spaceTemp);
        }
        
        return spaceList;
    }
    public static List<Space__c> createSpace(Integer count, List<Property__c> propertyList){
        Space__c spaceTemp;
        List<Space__c> spaceList = new List<Space__c>();
        
        for(Integer counter = 0; counter < count; counter++){
            spaceTemp = new Space__c();
            spaceTemp.Name = 'Space' + (counter);
            //spaceTemp.SpaceUID__c = 'Space' + (counter + 1);
            spaceTemp.Property__c = propertyList.get(counter).Id;
            spaceTemp.Type__c = '1';
            spaceTemp.Status__c = 'New';
            spaceTemp.OccupancyStatus__c = Constants.SPACE_OCCUPANCYSTATUS_LBNT;
            spaceTemp.BillingCategory__c = 'NA';
            
            // -- 5/2/2019
            spaceTemp.MainFloor__c = '0';
            
            spaceList.add(spaceTemp);
        }
        
        return spaceList;
    }
    public static List<Space__c> createSpace(Integer count){
        Space__c spaceTemp;
        List<Space__c> spaceList = new List<Space__c>();
        
        for(Integer counter = 0; counter < count; counter++){
            spaceTemp = new Space__c();
            spaceTemp.Name = 'Space' + (counter);
            //spaceTemp.SpaceUID__c = 'Space' + (counter + 1);
            //spaceTemp.Property__c = propertyList.get(counter).Id;
            spaceTemp.Type__c = '1';
            spaceTemp.Status__c = 'New';
            spaceTemp.OccupancyStatus__c = '2 - Leasing Issues';
            spaceTemp.BillingCategory__c = 'Not Applicable';
            
            // -- 5/2/2019
            spaceTemp.MainFloor__c = '0';
            
            spaceList.add(spaceTemp);
        }
        
        return spaceList;
    }
    
    public static List<Space__c> createSpace (Integer count, Property__c property, Opportunity opp, Contract__c contract){
        Space__c spaceTemp;
        List<Space__c> spaceList = new List<Space__c>();
        
        for(Integer counter = 0; counter < count; counter++){
            spaceTemp = new Space__c();
            spaceTemp.Name = 'Spa' + (counter + 1);
            //spaceTemp.SpaceUID__c = 'Space' + (counter + 1);
            spaceTemp.Property__c = property.Id;
            if(opp != null){
                spaceTemp.CurrentForecastedOpportunity__c = opp.Id;
            }  
            spaceTemp.Type__c = '1';
            spaceTemp.DevelopmentType__c = 'Operational';
            spaceTemp.HeldVacantSpace__c = false;
            spaceTemp.Status__c = 'At Risk';             
            spaceTemp.DevelopmentType__c = 'Operational';
            spaceTemp.CurrentLease__c = contract.id;
            spaceTemp.BillingCategory__c = 'Not Applicable';
            //spaceTemp.OccupancyStatus__c = '2 - Leasing Issues';
            //spaceTemp.CurrentLeaseExpiryDate__c = Date.today();
            
            // -- 5/2/2019
            spaceTemp.MainFloor__c = '0';
            
            spaceList.add(spaceTemp);
        }
        
        return spaceList;
    }
    public static List<Contract__c> createContract(Integer count, Account acc){
        Contract__c contractTemp;
        List<Contract__c> contrList = new List<Contract__c>();
        
        for(Integer counter = 0; counter < count; counter++){
            contractTemp = new Contract__c();
            contractTemp.Name = 'Test Contract' + (counter + 1);
            contractTemp.Account__c=acc.id;
            contractTemp.AccountName__c = acc.Name;
            contractTemp.JDELeaseNumber__c = '5566';
            contractTemp.LeaseEndDate__c = System.Today().addMonths(4);
            
            contrList.add(contractTemp);
        }
        
        return contrList;
    }
    public static List<Contract__c> createContract(Integer count, Account acc, Property__c prop, Opportunity opp){
        Contract__c contractTemp;
        List<Contract__c> contrList = new List<Contract__c>();
        
        for(Integer counter = 0; counter < count; counter++){
            contractTemp = new Contract__c();
            contractTemp.Name = 'Test Contract' + (counter + 1);
            contractTemp.Account__c=acc.id;
            contractTemp.JDELeaseNumber__c = '5566';
            contractTemp.LeaseEndDate__c = System.Today().addMonths(4);
            contractTemp.Property__c = prop.Id;
            contractTemp.Opportunity__c = opp.Id;
            contractTemp.LeaseStatus__c = 'D';
            
            
            contrList.add(contractTemp);
        }
        
        return contrList;
    }
    public static List<Contract__c> createContract(Integer count, Account acc, Property__c prop){
        Contract__c contractTemp;
        List<Contract__c> contrList = new List<Contract__c>();
        
        for(Integer counter = 0; counter < count; counter++){
            contractTemp = new Contract__c();
            contractTemp.Name = 'Test Contract' + (counter + 1);
            contractTemp.Account__c=acc.id;
            contractTemp.JDELeaseNumber__c = '5566';
            contractTemp.LeaseEndDate__c = System.Today().addMonths(4);
            contractTemp.Property__c = prop.Id;
            contractTemp.LeaseStatus__c = CONSTANTS.CONTRACT_STATUS_FUTURE_DnC;
            
            contrList.add(contractTemp);
        }
        
        return contrList;
    }
    public static List<Space__c> createSpace(Integer count, Account acc, Property__c property, Contract__c contract){
        Space__c spaceTemp;
        List<Space__c> spaceList = new List<Space__c>();
        
        for(Integer counter = 0; counter < count; counter++){
            spaceTemp = new Space__c();
            spaceTemp.Name = 'Spa' + (counter + 1);
            spaceTemp.CurrentLease__c = contract.id;
            spaceTemp.Property__c = property.Id;
            spaceTemp.BackupRetailer__c = acc.Id;
            spaceTemp.BillingCategory__c = 'NA';
            spaceTemp.Type__c = '4';
            
            // -- 5/2/2019
            spaceTemp.MainFloor__c = '0';
            spaceTemp.RentableArea__c = 0;
            spaceTemp.UsableArea__c = 0;
            
            spaceList.add(spaceTemp);
        }
        
        return spaceList;
    }
    public static List<Space__c> createSpace(Integer count, Account acc, Property__c property){
        Space__c spaceTemp;
        List<Space__c> spaceList = new List<Space__c>();
        
        for(Integer counter = 0; counter < count; counter++){
            spaceTemp = new Space__c();
            spaceTemp.Name = 'Spa' + (counter + 1);
            spaceTemp.Property__c = property.Id;
            spaceTemp.BackupRetailer__c = acc.Id;
            spaceTemp.BillingCategory__c = 'NA';
            spaceTemp.Type__c = '3';
            
            // -- 5/2/2019
            spaceTemp.MainFloor__c = '0';
            spaceTemp.RentableArea__c = 0;
            spaceTemp.UsableArea__c = 0;
            
            spaceList.add(spaceTemp);
        }
        
        return spaceList;
    }
    
    
    public static List<SpaceBudgetAndForecast__c> createSpaceBudget(Integer count, Space__c spaceRec){
        SpaceBudgetAndForecast__c spaceBudgetTemp;
        List<SpaceBudgetAndForecast__c> spaceBudgetList = new List<SpaceBudgetAndForecast__c>();
        
        for(Integer counter = 0; counter < count; counter++){
            spaceBudgetTemp = new SpaceBudgetAndForecast__c();
            spaceBudgetTemp.Name = 'SpaceBudget' + (counter + 1);
            spaceBudgetTemp.Space__c = spaceRec.Id;
            spaceBudgetTemp.BudgetedDealType__c = 'Net';
            spaceBudgetTemp.ModelType__c = 'Budget';
            spaceBudgetTemp.VacancyProvision__c = 1000;
            spaceBudgetTemp.EffectiveDate__c = Date.today();
            spaceBudgetTemp.AnnualisedPVRentSemiGross__c = 1000;
            spaceBudgetTemp.AnnualisedPVRentNet__c = 1000;
            spaceBudgetTemp.AnnualisedPVRentGross__c = 1000;
            spaceBudgetTemp.PromotionalAllowance__c = 1000;
            spaceBudgetTemp.CapitalSiteEstablishment__c = 1000;
            
            spaceBudgetList.add(spaceBudgetTemp);
        }
        
        return spaceBudgetList;
    }
    
    public static Pricebook2 createPricebook(){        
        Pricebook2 priceBook = new Pricebook2(
            Name = 'Test Pricebook ',
            CurrencyIsoCode = 'AUD',
            IsActive    = TRUE);
        
        return priceBook;
    }
    
    
    //added for 10705
    public static BillCode__c createBillCode(){        
        BillCode__c Bcode = new BillCode__c();
        Bcode.Active__c = True;
        //Bcode.Name = BC-000001 ;
        Bcode.BillCode__c = 'ABCD' ;
        Bcode.BillCodeDescription__c = 'test description';     
        Bcode.CurrencyIsoCode = 'AUD';
        
        return Bcode;
    }
    //end 10705
    
    /*
* Method Name:     createProduct
* Last Modified Date:   5/11/2018
* Last Modified By:   Dani Joseph Policarpio
* Description:      create Product with specific Product Name and Product Family
*/   
    public static Product2 createProduct(String prodName, String prodFam){
        Product2 prod = new Product2();
        prod.Name = prodName;
        prod.CurrencyIsoCode = 'AUD';
        prod.Family = prodFam;
        prod.IsActive = true;
        prod.ProductCode = 'RNT';
        prod.ApprovalStatus__c = 'New';
        prod.SpaceBillingCategory__c = 'EX';
        prod.DealType__c = 'Semi Gross';
        prod.SpaceType__c = '2';
        prod.DefaultPrice__c = 1000;
        
        return prod;
    }
    
    public Static void testSetupMeathod(){
        test.startTest();
        Property__c  property = new Property__c();
        property.Name = 'Test Property';
        insert property;
        
        Account acc = new Account(
            Name = 'Test Account ',
            Type = 'Retailer',
            TradingName__c = 'ABCZ ' ,
            ShippingCountry = 'Australia',
            ShippingStreet = '12345 Test Street Drive',
            ShippingCity = 'Sydney',
            ShippingState = 'Queensland',
            ShippingPostalCode = '2000',
            Category__c = 'S420',
            LesseeName__c = 'Test Lessee ' ,
            SuperfineCategory__c = 'S421',
            Property__c = property.id);
        insert acc;
        
        Space__c spaceTemp = new Space__c();
        spaceTemp.Name = 'TestSp';
        spaceTemp.Property__c = property.Id;
        spaceTemp.Type__c = '1';
        spaceTemp.Status__c = 'New';
        spaceTemp.OccupancyStatus__c = Constants.SPACE_OCCUPANCYSTATUS_LBNT;
        spaceTemp.BillingCategory__c = 'NA';
        spaceTemp.RentableArea__c = 555.00;
        spaceTemp.UsableArea__c = 555.00;
        spaceTemp.MainFloor__c = '0';
        insert spaceTemp;
        
        
        Opportunity opportunityRecord = new Opportunity();
        opportunityRecord.Space__c =spaceTemp.Id;
        opportunityRecord.Name = 'Test Name ';
        opportunityRecord.AccountId = acc.Id;
        opportunityRecord.StageName = Constants.UNDERSTAND_NEGOTIATE;
        opportunityRecord.CloseDate = date.today() + 10;     
        opportunityRecord.CurrencyIsoCode = 'AUD';
        opportunityRecord.ProposedStartDate__c = date.today();
        opportunityRecord.ProposedEndDate__c = date.today() + 10;
        opportunityRecord.ProposedRentCommencementDate__c = date.today();
        opportunityRecord.RentInAdvance__c = 100;
        opportunityRecord.SecurityDeposit__c = 100;
        opportunityRecord.Property__c = acc.Property__c;
        insert opportunityRecord;
        
        
        Case caseRec = new Case();
        caseRec.Space__c = spaceTemp.Id;
        caseRec.Status = 'Pending Approval';
        caseRec.Description = 'Test';
        caseRec.ReviewDate__c = date.today();
        caseRec.EffectiveDate__c = date.today() + 5;
        caseRec.TECH_Is_SDIC_Task_Completed__c = false;
        insert caseRec;
               
        Profile pf= [Select Id from profile where Name='System Administrator'];

        User u = new user();
        u.LastName = 'Test Code1';
        u.Email = 'test@test.com';
        u.Alias = 'Tcode';
        u.Username = 'test12001121@test.com';
        u.CommunityNickname = 'test11213';
        u.LocaleSidKey = 'en_US';
        u.TimeZoneSidKey = 'GMT';
        u.ProfileID = pf.Id;
        u.LanguageLocaleKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        insert u;
        
        PropertyTeam__c propertyTeam = new PropertyTeam__c();
        propertyTeam.Role__c = 'Retail Manager';
        propertyTeam.Property__c = property.Id;
        propertyTeam.TeamMember__c = u.Id;
        propertyTeam.StartDate__c = Date.today();
        propertyTeam.EndDate__c = Date.today() + 60;
        insert propertyTeam;
        
        list<Task> lisTask = new list<Task>( );
        Task t=new Task();
        t.status='Completed';
        t.Priority='low';
        t.subject='Add Attach or Complete SDIC';
        t.WhatId =opportunityRecord.id;
        lisTask.add(t);
       
        
        Task t1 = new Task();
        t1.status='Completed';
        t1.Priority='low';
        t1.subject='Add Attach or Complete SDIC';
        t1.WhatId =caseRec.id;
         lisTask.add(t1); 
        insert lisTask;
        test.stopTest();
        
    }
    
    
    
    
    /*
* @author:         Kyle Tan
* @description:    create multiple products
*/
    public static List<Product2> createProduct(Integer counter){
        List<Product2> productList = new List<Product2>();
        Product2 prod;
        
        for(Integer i = 0; i < counter; i++) {
            prod = new Product2();
            prod.Name = 'Test' + i;
            prod.CurrencyIsoCode = 'AUD';
            prod.Family = 'Rent';
            prod.IsActive = true;
            prod.DealType__c = Constants.OPP_LINEITEM_NET;
            prod.ProductCode = Constants.OTG;
            prod.SpaceBillingCategory__c = 'NR';
            prod.SpaceType__c = '1';
            prod.ApprovalStatus__c = 'Pending Approval';
            prod.DefaultPrice__c = 1000;
            
            
            
            productList.add(prod);
        }
        
        return productList;
    }
    
    /*
* Method Name:     createPriceBookEntryRecord
* Last Modified Date:   5/11/2018
* Last Modified By:   Dani Joseph Policarpio
* Description:      create Standard PriceBookEntry with specific Product Name and Pricebook
*/  
    public static PricebookEntry createPriceBookEntryRecord(String pbeName, Product2 prod, Pricebook2 pb){
        PricebookEntry pbEntry = new PricebookEntry();
        pbEntry.IsActive = true;
        pbEntry.Pricebook2Id = Test.getStandardPricebookId();
        pbEntry.Product2Id = prod.Id;
        pbEntry.UnitPrice = 10000.00;
        pbEntry.UseStandardPrice = false;
        return pbEntry;
    }
    
    /*
* Method Name:     createOpportunityLineItem
* Last Modified Date:   5/11/2018
* Last Modified By:   Dani Joseph Policarpio
* Description:      create OpportunityLineItem with specific Sales Price
*/  
    public static OpportunityLineItem createOpportunityLineItem(Integer counter, Opportunity opp, Product2 prod, PricebookEntry pbe) {
        OpportunityLineItem opportunityLineItemRecord = new OpportunityLineItem ();
        opportunityLineItemRecord.OpportunityId = opp.Id;
        opportunityLineItemRecord.Product2Id = prod.Id;
        opportunityLineItemRecord.PricebookEntryId = pbe.Id;
        opportunityLineItemRecord.UnitPrice = 100;
        opportunityLineItemRecord.IsActive__c = true;
        
        return opportunityLineItemRecord;
    }
    
    public static OpportunityLineItem createOpportunityLineItem(Integer counter, Opportunity opp, PricebookEntry pbe) {
        OpportunityLineItem opportunityLineItemRecord = new OpportunityLineItem ();
        opportunityLineItemRecord.OpportunityId = opp.Id;
        opportunityLineItemRecord.Product2Id = pbe.Product2Id;
        opportunityLineItemRecord.PricebookEntryId = pbe.Id;
        opportunityLineItemRecord.UnitPrice = 100;
        opportunityLineItemRecord.IsActive__c = true;
        opportunityLineItemRecord.Flexi_Rent__c = false;
        return opportunityLineItemRecord;
    }
    
    /*
* Method Name:     createOpportunity
* Last Modified Date:   5/11/2018
* Last Modified By:   Dani Joseph Policarpio
* Description:      create an Opportunity record 
*/   
    public static Opportunity createOpportunityRecord(Integer num, String name, String stageName, Account acc, Pricebook2 pb){
        Opportunity opp = new Opportunity();
        opp.StageName = stageName;
        opp.AccountId = acc.Id;
        opp.Name = name+num;
        opp.CloseDate = date.today()+15;
        opp.Pricebook2 = pb;
        opp.PercentageRentIncluded__c = true; //Used in OppLineItemTriggerHandlerTest
        opp.PercentageRentPercent__c = 1; //Used in OppLineItemTriggerHandlerTest
        opp.ProposedStartDate__c = date.today()+15; //Used in OppLineItemTriggerHandlerTest
        opp.ProposedRentCommencementDate__c = date.today()+5; //Used in OppLineItemTriggerHandlerTest
        opp.RentInAdvance__c = 1000; //Used in OppLineItemTriggerHandlerTest
        opp.SecurityDeposit__c = 1000; //Used in OppLineItemTriggerHandlerTest
        opp.AnnualMinimumRent__c = 1000; //Used in OppLineItemTriggerHandlerTest
        opp.Property__c = acc.Property__c;
        return opp;
    }
    
    /*
* Method Name:     createPropertyRecord
* Last Modified Date:   5/11/2018
* Last Modified By:   Dani Joseph Policarpio
* Description:      create a Property record 
*/ 
    public static Property__c createPropertyRecord() {
        Property__c propertyRecord;
        propertyRecord = new Property__c();
        propertyRecord.Name = 'Test Property';
        propertyRecord.PropertyShortName__c = 'ABC';
        
        
        return propertyRecord;
    }
    
    
    /*
* @author:         Kyle Tan
* @description:    create property ownership records
*/
    public static List<PropertyOwnership__c> createPropertyOwnership(Integer counter, Id propertyId, Id accountId) {
        List<PropertyOwnership__c> propertyOwnershipList = new List<PropertyOwnership__c>();
        PropertyOwnership__c propertyOwnershipRec;
        
        for(Integer i = 0; i < counter; i++) {
            propertyOwnershipRec = new PropertyOwnership__c();
            propertyOwnershipRec.ABN__c = 'Test ABN ' + i;
            propertyOwnershipRec.Account__c = accountId;
            propertyOwnershipRec.Active__c = true;
            propertyOwnershipRec.HoldingCompanyName__c = 'Test ' + i;
            propertyOwnershipRec.Ownership__c = 10;
            propertyOwnershipRec.Type__c = CONSTANTS.BANK_GUARANTEE_ENTITY;
            propertyOwnershipRec.EffectiveFrom__c = date.today();
            propertyOwnershipRec.EffectiveTo__c = date.today() + 10;
            propertyOwnershipRec.Property__c = propertyId;
            propertyOwnershipList.add(propertyOwnershipRec);
        }
        
        return propertyOwnershipList;
    }
    
    /*
* @author:         Miguel Paguio
* @description:    Create PropertyMaps Records
*/
    public static List<PropertyMaps__c> createPropertyMaps(Integer counter, Id propertyId) {
        List<PropertyMaps__c> propertyMapsList = new List<PropertyMaps__c>();
        PropertyMaps__c propertyMapsRec;
        for(Integer i = 0; i < counter; i++) {
            propertyMapsRec = new PropertyMaps__c(); 
            propertyMapsRec.Name = 'Test';
            propertyMapsRec.Floor__c = '0';
            propertyMapsRec.URL__c = 'www.salesforce.com';
            propertyMapsRec.Property__c = propertyId;
            propertyMapsList.add(propertyMapsRec);
        }
        
        return propertyMapsList;
    }
    
    /**
* @author: Yana Navarro
* @description: Create Task Template and Condition record
* @param: String objectType
* @param: String assigneeRole
* @param: Id dependentTaskTemplate
* @param: String opportunityStage
* @param: String taskName
* @return: TaskTemplateAndCondition__c
**/
    public static TaskTemplateAndCondition__c createTaskTemplate(
        String objectType, String assigneeRole, Id dependentTaskTemplate, String opportunityStage, String taskName, String taskType, String assigneeTeam,
        String BusinessUnit){
            TaskTemplateAndCondition__c taskTemplate = new TaskTemplateAndCondition__c();
            
            taskTemplate.IsActive__c = true;
            taskTemplate.Object__c = objectType;
            taskTemplate.OpportunityStage__c = opportunityStage;
            taskTemplate.DependentTask__c = dependentTaskTemplate;
            taskTemplate.AssignTo__c = assigneeRole;
            taskTemplate.DueDate__c = 1;
            taskTemplate.TaskDescription__c = 'Test task template';
            taskTemplate.TaskName__c = taskName;
            taskTemplate.TaskType__c = taskType;
            tasktemplate.JVApproval__c = 'Independent';
            taskTemplate.BusinessUnit__c = businessUnit;
            taskTemplate.LeaseType__c = 'New Retailer; New Lease';
            taskTemplate.SpecialtyLeaseType__c = 'Default';
            taskTemplate.ApplicableCountry__c = 'AUD; NZD';
            taskTemplate.IsStageChange__c = true;
            taskTemplate.AssigneesTeam__c = assigneeTeam;
            taskTemplate.SkipWeekends__c = true;
            
            return taskTemplate;
        }
    
    public static TaskTemplateAndCondition__c createCaseTaskTemplate(String objectType, String assigneeRole, String taskName, String taskType, String assigneeTeam,
                                                                     String caseRecordTypeName, Id dependentTaskTemplate){
                                                                         TaskTemplateAndCondition__c taskTemplate = new TaskTemplateAndCondition__c();
                                                                         
                                                                         taskTemplate.IsActive__c = true;
                                                                         taskTemplate.Object__c = objectType;
                                                                         taskTemplate.AssignTo__c = assigneeRole;
                                                                         taskTemplate.AssigneesTeam__c = assigneeTeam;
                                                                         taskTemplate.DueDate__c = 1;
                                                                         taskTemplate.TaskDescription__c = 'Test task template';
                                                                         taskTemplate.TaskName__c = taskName;
                                                                         taskTemplate.TaskType__c = taskType;
                                                                         taskTemplate.CaseRecordType__c = caseRecordTypeName;
                                                                         taskTemplate.DependentTask__c = dependentTaskTemplate;
                                                                         taskTemplate.ApplicableCountry__c = 'AUD; NZD';
                                                                         taskTemplate.SkipWeekends__c = true;
                                                                         
                                                                         return taskTemplate;
                                                                     }
    
    /**
* @author: Yana Navarro
* @description: Create Property Team record
* @param: Id propertyId
* @param: String role
* @param: Id teamMember
* @param: Id recordTypeId
* @return: PropertyTeam__c
**/
    public static PropertyTeam__c createPropertyTeam(Id propertyId, String role, Id teamMember, Id recordTypeId){
        PropertyTeam__c propertyTeam = new PropertyTeam__c();
        
        propertyTeam.RecordTypeId = recordTypeId;
        propertyTeam.Role__c = role;
        propertyTeam.Property__c = propertyId;
        propertyTeam.TeamMember__c = teamMember;
        propertyTeam.StartDate__c = Date.today();
        propertyTeam.EndDate__c = Date.today() + 60;
        
        return propertyTeam;
    }
    /**
*@author:      Kyle Tan
**/
    
    public static PrecedentClause__c createPrecedentClause(Integer counter, Id accountId, Id recordTypeId) {
        PrecedentClause__c precedentClauseRecord = new PrecedentClause__c(
            Account__c = accountId,
            Comments__c = 'Test Comments' + counter,
            Description__c = 'Test Description' + counter,
            EffectiveToDate__c = date.today(),
            Status__c = 'Active',
            Type__c = 'Usage', 
            RecordTypeId = recordTypeId, 
            PromoPercentage__c = 80,
            CurrentMinimumThreshold__c = 1000.50,
            CurrentMaximumThreshold__c = 1989.99,
            StandardReviewTypes__c = 'CPI+1.5');
        
        return precedentClauseRecord;
    }
    
    public static PrecedentClause__c createPrecedentClause(Integer counter, Id accountId, Id recordTypeId, ClauseLibrary__c clLib) {
        PrecedentClause__c precedentClauseRecord = new PrecedentClause__c(
            Account__c = accountId,
            Comments__c = 'Test Comments' + counter,
            Description__c = 'Test Description' + counter,
            EffectiveToDate__c = date.today(),
            Status__c = 'Active',
            Type__c = 'Usage', 
            RecordTypeId = recordTypeId, 
            PromoPercentage__c = 80,
            CurrentMinimumThreshold__c = 1000.50,
            CurrentMaximumThreshold__c = 1989.99,
            StandardReviewTypes__c = 'CPI+1.5');
        precedentClauseRecord.ReferencedClause__c = clLib.Id;
        
        return precedentClauseRecord;
    }
    /**
* @author:     Kyle Tan
**/
    public static AccountContactRelation createACR(Account acc, Contact con) {
        AccountContactRelation ACRRec = new AccountContactRelation();
        ACRRec.AccountId = acc.Id;
        ACRRec.ContactId = con.Id;
        ACRRec.StartDate = date.today();
        ACRRec.EndDate = date.today() + 5;
        ACRRec.Comments__c = 'Test Comments';
        return ACRRec;
    }
    
    public static Case createCaseRelatedToContract(Contract__c contractRec, Id recordTypeId, Space__c spaceRec){
        Case caseRec = new Case();
        caseRec.Contract__c = contractRec.Id;
        caseRec.RecordTypeId = recordtypeId;
        caseRec.Type = 'Lease Area Variation';
        caseRec.Space__c = contractRec.Space__c;
        caseRec.Description = 'Test';
        caseRec.ReviewDate__c = date.today();
        caseRec.EffectiveDate__c = date.today() + 5;
        caseRec.Subject = 'Lease Area Variation';
        caseRec.InvoiceNumber__c = '12341234';
        caseRec.BillCode__c = 'Test bill code';
        caseRec.TotalAmountExcludingGST__c = 10;
        caseRec.GSTAmount__c = 1000;
        caseRec.ReasonForCreditNote__c = 'Test Reason';
        return caseRec;
    }
    
    public static Task createTaskRelatedToOpp(Id oppId, Contact contactRec){
        Task taskRec = new Task();
        taskRec.WhoId = contactRec.Id;
        taskRec.WhatId = oppId;
        taskRec.Subject = 'Call';
        taskRec.ActivityDate = date.today();
        taskRec.Status = Constants.OPEN;
        return taskRec;
    }
    
    public static Task createTask(Id recordTypeId, Id whatId, Id whoId, String subject, String taskType){
        Task taskRec = new Task();
        taskRec.WhoId = whoId;
        taskRec.WhatId = whatId;
        taskRec.Subject = subject;
        taskRec.ActivityDate = date.today();
        taskRec.Status = Constants.OPEN;
        taskRec.TaskType__c = taskType;
        taskRec.RecordTypeId = recordTypeId;
        
        return taskRec;
    }
    
    public static Task createTask(Id whatId, Id whoId, String subject, Date activityDate, String taskType){
        Task taskRec = new Task();
        taskRec.WhoId = whoId;
        taskRec.WhatId = whatId;
        taskRec.Subject = subject;
        taskRec.ActivityDate = activityDate;
        taskRec.Status = Constants.COMPLETED;
        taskRec.TaskType__c = taskType;
        return taskRec;
    }
    
    public static Case createCase(Contract__c contractRec, Space__c spaceRec, Id recordTypeId){
        Case caseRec = new Case();
        caseRec.Contract__c = contractRec.Id;
        caseRec.RecordTypeId = recordtypeId;
        caseRec.Space__c = spaceRec.Id;
        caseRec.Status = 'Pending Approval';
        caseRec.Description = 'Test';
        caseRec.ReviewDate__c = date.today();
        caseRec.EffectiveDate__c = date.today() + 5;
        return caseRec;
    }
    
    
    /* public static Case createRDBCase(Contract__c contractRec,Opportunity oppRec,Space__c spaceRec, Id recordTypeId){
Case caseRec = new Case();
caseRec.Contract__c = contractRec.Id;
caseRec.RecordTypeId = recordtypeId;
caseRec.Space__c = spaceRec.Id;
caseRec.Status = 'Completed';
caseRec.Description = 'Test';
caseRec.ReviewDate__c = date.today();
caseRec.EffectiveDate__c = date.today() + 5;
return caseRec;

}*/
    
    public static Affiliation__c createAffiliation(Account accountRec, Account primaryAcc, Contact con, String affType, String status) {
        Affiliation__c affRec = new Affiliation__c();
        affRec.Account__c = accountRec.Id;
        affRec.PrimaryAffiliationAccount__c = primaryAcc.Id;
        affRec.Contact__c = con.Id;
        affRec.Status__c = status;
        affRec.Type__c = affType;
        return affRec;
    }
    
    /**
* @author: Melissa Carino
* @description: Create AccountTeamMemberRecord
* @param: Id AccountRecId
* @param: Id UserRec
**/
    public static AccountTeamMember createAccountTeamMember(Id AccountRecId, Id UserRec){
        AccountTeamMember AccTeamMember = new AccountTeamMember();
        AccTeamMember.AccountId = AccountRecId;
        AccTeamMember.UserId = UserRec;
        AccTeamMember.TeamMemberRole = Constants.TEAM_ROLE_RDAM;
        return AccTeamMember;
    }
    
    /**
* @author: Melissa Carino
* @description: Create String value of Payload
* @param: Integer counter
**/
    public static List<string> lstPayload(Integer counter){
        List<string> lstsPayload = new List<string>();
        for(Integer i = 0; i < counter; i++) {
            string payload = 'test'+ counter;
            lstsPayload.add(payload);
        }
        return lstsPayload;
    }
    /**
* @author: Melissa Carino
* @description: Create Opportunities for each account with Stage Issue Lease
* @param: List of Account - accountList
**/
    
    public static List<Opportunity> createIssueLeaseOpportunity(List<Account> accountList, Pricebook2 pb, Space__c space, Property__c PropertyRec, Id RecTypeid) {
        Opportunity opportunityRecord;
        List<Opportunity> opportunityList = new List<Opportunity>();
        
        for(Integer counter = 0; counter < accountList.size(); counter++) {
            opportunityRecord = new Opportunity();
            opportunityRecord.Name = 'Test Name' + counter;
            opportunityRecord.AccountId = accountList.get(counter).Id;
            //opportunityRecord.StageName = Constants.OPPORTUNITYSTAGE_ISSUE_LEASE;
            opportunityRecord.PromoLevyIncluded__c = 'No';
            opportunityRecord.StageName = Constants.UNDERSTAND_NEGOTIATE;
            opportunityRecord.Space__c = space.id;
            opportunityRecord.CloseDate = date.today() + 10;
            opportunityRecord.ProposedStartDate__c = date.today();
            opportunityRecord.ProposedEndDate__c = date.today() + 10; 
            opportunityRecord.TermYr__c = 2;
            opportunityRecord.AnnualMinimumRent__c = 100;
            opportunityRecord.PercentageRentPercent__c = 5;
            opportunityRecord.RentInAdvance__c = 500;
            opportunityRecord.SecurityDeposit__c = 1000;
            opportunityRecord.ProposedRentCommencementDate__c = date.today();
            //  opportunityRecord.Property__c = PropertyRec.id;
            opportunityRecord.Property__c = accountList[0].property__c;
            opportunityRecord.ProposedHandoverDate__c = date.today();
            opportunityRecord.RecordTypeId = RecTypeid;
            opportunityRecord.DealType__c = 'Semi Gross';
            opportunityRecord.InitialCostEstimate__c = 100;
            
            opportunityList.add(opportunityRecord);
            
        }
        return opportunityList;
    }
    /**
* @author: Melissa Carino
* @description: Create Opportunity Clause
* @param: Opp
**/
    public static OpportunityClause__c CreateOppClause (Opportunity Opp){
        OpportunityClause__c OppClause = new OpportunityClause__c();
        OppClause.Name = 'Test';
        OppClause.Type__c = 'Usage';
        Oppclause.Approved__c = True;
        Oppclause.Opportunity__c = Opp.id;
        
        return OppClause;
    }
    /**
* @author: Melissa Carino
* @description: Create Custom Pricebook
* @param: NA
**/
    public static Pricebook2 createcustomPB(){
        Pricebook2 pb = new Pricebook2(Name = 'Miranda 2018', Description = 'Custom Pricebook', IsActive = true);
        
        return pb;
    }
    
    /**
* @author: Melissa Carino
* @description: Create Rent Review Product
* @param: NA
**/
    public static Product2 createRentReview(Pricebook2 pb){
        
        Product2 prod = new Product2(Name = 'Rent Review', Family = 'Rent Review', IsActive = true, ProductCode = 'RNT', ApprovalStatus__c = 'Approved',
                                     SpaceBillingCategory__c = Constants.SPACEBILLINGCATEGORY_NON_RETAIL,
                                     DealType__c = Constants.DEALTYPE_SEMI_GROSS, SpaceType__c = Constants.SPACETYPE_SHOP);
        
        return prod;
    }
    /**
* @author: Melissa Carino
* @description: Create case
* @param: NA
**/
    public static Case CreateCase(Account AccRec, Id RecTypeId, Id contractId){
        case caseRec = new case();
        caseRec.subject= 'Test';
        caseRec.AccountId = AccRec.id;
        caseRec.RecordTypeId = RecTypeId;
        
        caseRec.Contract__c = contractId;
        
        return caseRec;
        
    }
    
    public static SpaceGroup__c createSpaceGroup(Space__c parentSpace, Space__c childSpace){
        SpaceGroup__c spaceGroup = new SpaceGroup__c();
        spaceGroup.ParentSpace__c = parentSpace.Id;
        spaceGroup.ChildSpace__c = childSpace.Id;
        spaceGroup.Type__c = 'Development';
        spaceGroup.Name = 'Test Space Group Name';
        spaceGroup.Active__c = true;
        spaceGroup.EffectiveDate__c = date.today();
        spaceGroup.SpaceGroupNumber__c = 1;
        
        
        return spaceGroup;
    }
    
    public static ContentVersion createContentVersion(String title, String docCategory, String docType){
        ContentVersion cv=new Contentversion();
        cv.title = title;
        cv.PathOnClient = 'test';
        Blob b = Blob.valueOf('Unit Test Attachment Body');
        cv.versiondata = EncodingUtil.base64Decode('Unit Test Attachment Body');
        cv.DocumentCategory__c = docCategory;
        cv.DocumentType__c = docType;
        
        return cv;
    }
    
    public static ContentDocumentLink createContentDocumentLink(Id parentId, ContentVersion cVersion){
        ContentDocumentLink conDocLink = new ContentDocumentLink();
        
        conDocLink.ContentDocumentId = cVersion.ContentDocumentId;
        conDocLink.LinkedEntityId = parentId;
        conDocLink.ShareType = 'V';
        conDocLink.Visibility = 'AllUsers';
        
        return conDocLink;
    }
    
    public static List<SpaceProduct__c> createSpaceProduct(Integer count, Space__c spaceId, String productFamily, Product2 productId){
        List<SpaceProduct__c> spaceProductList = new List<SpaceProduct__c>();
        SpaceProduct__c spaceProductRec;
        for(Integer i = 0; i < count; i++){ 
            spaceProductRec = new SpaceProduct__c();
            spaceProductRec.Space__c = spaceId.Id;
            spaceProductRec.ProductFamily__c = CONSTANTS.RENT;
            spaceProductRec.Product__c = productId.Id;
            spaceProductRec.CurrencyIsoCode = 'AUD';
            spaceProductRec.EffectiveFromDate__c = date.today();
            spaceProductRec.EffectiveToDate__c = date.Today() + 30;
            spaceProductRec.SalesPrice__c = 10;
            spaceProductList.add(spaceProductRec);
        }
        return spaceProductList;
    }
    
    public static List<RelatedOpportunity__c> createRelatedOpportunity(Integer count, Opportunity primaryOpp) {
        List<RelatedOpportunity__c> relatedOppList = new List<RelatedOpportunity__c>();
        RelatedOpportunity__c relatedOppRec = new RelatedOpportunity__c();
        for(Integer i = 0; i < count; i++) {
            relatedOppRec.PrimaryOpportunity__c = primaryOpp.Id;
            relatedOppRec.CurrencyIsoCode = Constants.CURRENCYCODEAUD;
            relatedOppList.add(relatedOppRec);
        }
        return relatedOppList;
    }
    
    public static OpportunityTeamMember createOpportunityTeamMember(Opportunity oppRecord, User userRecord, String teamRole) {
        OpportunityTeamMember oppTeamMemberRec = new OpportunityTeamMember();
        oppTeamMemberRec = new OpportunityTeamMember();
        oppTeamMemberRec.OpportunityId = oppRecord.Id;
        oppTeamMemberRec.UserId = userRecord.Id;
        oppTeamMemberRec.TeamMemberRole = teamRole;
        oppTeamMemberRec.OpportunityAccessLevel = 'Edit';
        return oppTeamMemberRec;
    }
    
    public static List<OpportunityAuditHistory__c> createOpportunityAuditHistory(Opportunity opp, String modifiedFieldName, String newValue, String previousValue, String oppApprovalStatus, Integer count){
        List<OpportunityAuditHistory__c> oppAuditHistoryList = new List<OpportunityAuditHistory__c>();
        OpportunityAuditHistory__c oppAuditHistory = new OpportunityAuditHistory__c();
        for(Integer i = 0; i < count; i++) {
            oppAuditHistory.Opportunity__c = opp.Id;
            oppAuditHistory.ModifiedFieldName__c = modifiedFieldName;
            oppAuditHistory.NewValue__c = newValue;
            oppAuditHistory.PreviousValue__c = previousValue;
            oppAuditHistory.OpportunityApprovalStatus__c = oppApprovalStatus;
            oppAuditHistoryList.add(oppAuditHistory);
        }
        return oppAuditHistoryList;
        
    }
}