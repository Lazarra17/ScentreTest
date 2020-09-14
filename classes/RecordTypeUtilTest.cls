/*
 *    @Author         Dani Joseph Policarpio
 *    @Created Date   April 27, 2018
 *    @Description    Test class for RecordTypeUtil Apex Class
 *    @History        Dani Joseph Policarpio    April 27, 2018    Created
*/
@isTest
public class RecordTypeUtilTest {
    /*
     *    @Author         Dani Joseph Policarpio
     *    @Created Date   April 27, 2018
     *    @Description    Verify Successful retrieval of Contact RecordType by Id
     *    @History        Dani Joseph Policarpio    April 27, 2018    Created
    */
    static testMethod void verifySuccessContactGetRecordTypeByName(){
        String strObject = 'Contact';
        Map<String,Schema.RecordTypeInfo> mapRecordType = new Map<String,Schema.RecordTypeInfo> ();
        
        Test.startTest(); 
            mapRecordType = RecordTypeUtil.getAllRecordTypesByName(strObject);

            mapRecordType = RecordTypeUtil.getAllRecordTypesByName(strObject);
        Test.stopTest();
        
        system.assert(mapRecordType.size() > 0);
    }
    
    /*
     *    @Author         Dani Joseph Policarpio
     *    @Created Date   April 27, 2018
     *    @Description    Verify successful retrieval of Account RecordType by Name
     *    @History        Dani Joseph Policarpio    April 27, 2018    Created
    */
    static testMethod void verifySuccessAccountContactGetRecordTypeByName(){
        String strObject = 'Account';
        Map<String,Schema.RecordTypeInfo> mapRecordType = new Map<String,Schema.RecordTypeInfo> ();
        
        Test.startTest(); 
            mapRecordType = RecordTypeUtil.getAllRecordTypesByName(strObject);

            mapRecordType = RecordTypeUtil.getAllRecordTypesByName(strObject);
        Test.stopTest();
        
        system.assert(mapRecordType.size() > 0);
    }

    /*
     *    @Author         Dani Joseph Policarpio
     *    @Created Date   April 27, 2018
     *    @Description    Verify successful retrieval of Contact RecordType by Id
     *    @History        Dani Joseph Policarpio    April 27, 2018    Created
    */
    static testMethod void verifySuccessContactGetRecordTypeById(){
        String strObject = 'Contact';
        Map<Id,Schema.RecordTypeInfo> mapRecordType = new Map<Id,Schema.RecordTypeInfo> ();
        
        Test.startTest(); 
            mapRecordType = RecordTypeUtil.getAllRecordTypesById(strObject);
        Test.stopTest();
        
        system.assert(mapRecordType.size() > 0);
    }       
    
    /*
     *    @Author         Dani Joseph Policarpio
     *    @Created Date   April 27, 2018
     *    @Description    Verify successful retrieval of Account RecordType by Id
     *    @History        Dani Joseph Policarpio    April 27, 2018    Created
    */
    static testMethod void verifySuccessAccountGetRecordTypeById(){
        String strObject = 'Account';
        Map<Id,Schema.RecordTypeInfo> mapRecordType = new Map<Id,Schema.RecordTypeInfo> ();
        
        Test.startTest(); 
            mapRecordType = RecordTypeUtil.getAllRecordTypesById(strObject);
        Test.stopTest();
        
        system.assert(mapRecordType.size() > 0);
    }   
    
    /*
     *    @Author         Dani Joseph Policarpio
     *    @Created Date   April 27, 2018
     *    @Description    Verify unsuccessful retrieval of a RecordType by Id
     *    @History        Dani Joseph Policarpio    April 27, 2018    Created
    */
    static testMethod void verifyFailedGetRecordTypeById(){
        String strObject = 'Acc';
        Map<Id,Schema.RecordTypeInfo> mapRecordType = new Map<Id,Schema.RecordTypeInfo> ();
        
        Test.startTest(); 
            mapRecordType = RecordTypeUtil.getAllRecordTypesById(strObject);
        Test.stopTest();
        
        system.assert(mapRecordType == null);
    }   
    
        /*
     *    @Author         Dani Joseph Policarpio
     *    @Created Date   April 27, 2018
     *    @Description    Verify unsuccessful retrieval of a RecordType by Name
     *    @History        Dani Joseph Policarpio    April 27, 2018    Created
    */
    static testMethod void verifyFailedGetRecordTypeByName(){
        String strObject = 'Acc';
        Map<String,Schema.RecordTypeInfo> mapRecordType = new Map<String,Schema.RecordTypeInfo> ();
        
        Test.startTest(); 
            mapRecordType = RecordTypeUtil.getAllRecordTypesByName(strObject);
        Test.stopTest();
        
        system.assert(mapRecordType == null);
    }   
    
}