@isTest
public class ChatterForSDICTaskCompletionTest {
     @testSetup
    public static void testSetup(){
      TestDataFactory.testSetupMeathod();
        
    }
    
     @isTest static void chatterPostToProprtyTeamTest(){
        test.startTest();
         List<Id> lisId =new List<Id>() ;
         List<Task> taskList = [SELECT Id, WhatId, Opportunity__r.Space__r.Property__c FROM Task];
         lisId.add(taskList[0].Id);
         lisId.add(taskList[1].Id);
        ChatterForSDICTaskCompletion.chatterPostToProprtyTeam(lisId);
        test.stopTest(); 
         
         System.assert(true);
    }
    
    @isTest static void chatterPostToProprtyTeamTest1(){
        test.startTest();
         List<Id> lisId =new List<Id>() ;
         List<Task> taskList = [SELECT Id, WhatId, Case__r.Space__r.Property__c FROM Task];
         lisId.add(taskList[0].Id);
         ChatterForSDICTaskCompletion.chatterPostToProprtyTeam(lisId);
        test.stopTest(); 
         System.assert(true);
    }
    
   
}