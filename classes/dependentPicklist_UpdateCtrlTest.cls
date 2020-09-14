@isTest
public class dependentPicklist_UpdateCtrlTest {

    @isTest
    static void getDependentMap_Test(){
        Case cs = new Case();
        dependentPicklist_UpdateCtrl.getDependentMap(cs, 'Type', 'SubType__c');
    } 
}