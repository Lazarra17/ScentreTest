/**
* @author:          Shrikant Hase
* @description:     Test class for Covid Case Related List Controller
**/
@isTest
private class CovidCaseRelatedListControllerTest {
	
    @testSetup
    private static void testSetup(){
        Property__c testProperty = New Property__c();
        List<Space__c> testSpace = New List<Space__c>();
        Account testAccount = New Account();
        Case testCase = New Case();
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
		Map<String, Schema.RecordTypeInfo> caseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.OBJECT_CASE);
        
        //CREATE PROPERTY
        testProperty = TestDataFactory.createPropertyRecord();
        database.insert(testProperty);
        
        //CREATE NATIONAL ACCOUNT
        testAccount = TestDataFactory.createAccount(1, testProperty.Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId());
        database.insert(testAccount);
        
        //CREATE SPACE
        testSpace = TestDataFactory.createSpace(1, testProperty);
        database.insert(testSpace);
        
        //CREATE CASE
        testCase.Space__c = testSpace[0].Id;
        testCase.Status = 'Pending Approval';
        testCase.Description = 'Test';
        testCase.ReviewDate__c = date.today();
        testCase.EffectiveDate__c = date.today() + 5;
        testCase.TECH_Is_SDIC_Task_Completed__c = false;
        testCase.RecordTypeId = caseRecordTypeMapByName.get(CONSTANTS.LVI_COVID19).getRecordTypeId();
        testCase.Type = CONSTANTS.CASE_TYPE_LV18MISCELLANEOUS;
        testCase.SubType__c = CONSTANTS.CASE_SUBTYPE_COVID_RENT_REQUEST;
        testCase.AccountId = testAccount.Id;
        insert testCase;
        
        //CREATE NOTES
        for(Integer i = 0; i < 4; i++){
            ContentNote note = New ContentNote();
            note.Title = 'test' + i;
            String body = 'testing' + i;
            note.Content = blob.valueOf(body);
            CovidCaseRelatedListController.createNewNote(note, testCase.Id);
        }
    }
    
    /*
    * @author:              Shrikant Hase
    * @description:         this method tests files and notes related list are visible for admin user
    */
    private static testMethod void getUserAccessibilitySysAdmTest(){
        Profile adminProfileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR OR Name =: Constants.SCG_SYS_ADM LIMIT 1];
        User testAdminUser = TestDataFactory.createUniqueTestUser('John', 'Doe', adminProfileRec.Id);
        Case caseRec = [Select Id From Case LIMIT 1];
        
        system.runAs(testAdminUser) {
            Test.startTest();
                CovidCaseRelatedListController.getUserAccessibility(caseRec.Id, testAdminUser.Id);
            Test.stopTest();
        }
    }
    
    /*
    * @author:              Shrikant Hase
    * @description:         this method tests files and notes related list are visible for case team users where related account
    * 						is a national account.
    */
    private static testMethod void getUserAccessibilityCaseTeamMemberTest(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        database.insert(testUser);
        Account accRec = [Select Id From Account LIMIT 1];
        accRec.Is_National_Account__c = true;
        database.update(accRec);
        Case caseRec = [Select Id From Case LIMIT 1];
        CaseTeamRole role = [select Id from CaseTeamRole limit 1];
        insert new CaseTeamMember(ParentId = caseRec.Id, MemberId = testUser.Id, TeamRoleId = role.Id);
        
        system.runAs(testUser) {
            Test.startTest();
                CovidCaseRelatedListController.getUserAccessibility(caseRec.Id, testUser.Id);
            Test.stopTest();
        }
    }
    
    /*
    * @author:              Shrikant Hase
    * @description:         this method tests files and notes related list are visible for some specific users
    */
    private static testMethod void getUserAccessibilitySpecificUserTest(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.RETAIL_LEASING LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('Andrew', 'Hulls', profileRec.Id);
        Case caseRec = [Select Id From Case LIMIT 1];
        
        system.runAs(testUser) {
            Test.startTest();
                CovidCaseRelatedListController.getUserAccessibility(caseRec.Id, testUser.Id);
            Test.stopTest();
        }
    }
    
    /*
    * @author:              Shrikant Hase
    * @description:         this method tests files and notes related list are not visible for user who are not case team
    * 						team members and but related account is a national account.
    */
    private static testMethod void getUserAccessibilityNationalAccountTest(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Account accRec = [Select Id From Account LIMIT 1];
        accRec.Is_National_Account__c = true;
        database.update(accRec);
        Case caseRec = [Select Id From Case LIMIT 1];
        
        system.runAs(testUser) {
            Test.startTest();
                CovidCaseRelatedListController.getUserAccessibility(caseRec.Id, testUser.Id);
            Test.stopTest();
        }
    }
    
    /*
    * @author:              Shrikant Hase
    * @description:         this method tests files and notes related list are visible for property team users where account related to case is not a national account.
    */
    private static testMethod void getUserAccessibilityPropertyTeamTest(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        database.insert(testUser);
        Case caseRec = [Select Id From Case LIMIT 1];
        Property__c propRec = [Select Id from Property__c LIMIT 1];
        insert new PropertyTeam__c(Property__c = propRec.Id, TeamMember__c = testUser.Id);
        
        system.runAs(testUser) {
            Test.startTest();
                CovidCaseRelatedListController.getUserAccessibility(caseRec.Id, testUser.Id);
            Test.stopTest();
        }
    }
    
    /*
    * @author:              Shrikant Hase
    * @description:         this method tests files and notes related list are not visible for users not part of property team
    * 						as well as where account related to case is not a national account.
    */
    private static testMethod void getUserAccessibilityNoPropTeamTest(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Case caseRec = [Select Id From Case LIMIT 1];
        Property__c propRec = [Select Id from Property__c LIMIT 1];
        
        system.runAs(testUser) {
            Test.startTest();
                CovidCaseRelatedListController.getUserAccessibility(caseRec.Id, testUser.Id);
            Test.stopTest();
        }
    }
    
    /*
    * @author:              Shrikant Hase
    * @description:         this method tests that files related to case are retrieved properly.
    */
    private static testMethod void getRelatedFilesTest(){
        Profile adminProfileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR OR Name =: Constants.SCG_SYS_ADM LIMIT 1];
        User testAdminUser = TestDataFactory.createUniqueTestUser('John', 'Doe', adminProfileRec.Id);
        Case caseRec = [Select Id From Case LIMIT 1];
        
        system.runAs(testAdminUser) {
            Test.startTest();
                CovidCaseRelatedListController.getRelatedFiles(caseRec.Id);
            Test.stopTest();
        }
    }
    
    /*
    * @author:              Shrikant Hase
    * @description:         this method tests that notes related to case are retrieved properly.
    */
    private static testMethod void getRelatedNotesTest(){
        Profile adminProfileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR OR Name =: Constants.SCG_SYS_ADM LIMIT 1];
        User testAdminUser = TestDataFactory.createUniqueTestUser('John', 'Doe', adminProfileRec.Id);
        Case caseRec = [Select Id From Case LIMIT 1];
        
        system.runAs(testAdminUser) {
            Test.startTest();
                CovidCaseRelatedListController.getRelatedNotes(caseRec.Id);
            Test.stopTest();
        }
    }
    
    /*
    * @author:              Shrikant Hase
    * @description:         this method tests that user can create new note for the related case.
    */
    private static testMethod void createNewNoteTest(){
        Profile adminProfileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR OR Name =: Constants.SCG_SYS_ADM LIMIT 1];
        User testAdminUser = TestDataFactory.createUniqueTestUser('John', 'Doe', adminProfileRec.Id);
        ContentNote noteRec = New ContentNote(Title = 'Test', Content = blob.valueOf('testing'));
        Case caseRec = [Select Id From Case LIMIT 1];
        
        system.runAs(testAdminUser) {
            Test.startTest();
                CovidCaseRelatedListController.createNewNote(noteRec, caseRec.Id);
            Test.stopTest();
        }
    }
    
}