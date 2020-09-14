public class NextApprover {
    
    @AuraEnabled
    public static String getNextApprover(Id oppId) {
        
        Opportunity opp = [Select Id,ApprovalStatus__c,Pending_Approver__c From Opportunity Where ID =:  oppId];
        List<Opportunity> oppList = new List<Opportunity>();
        List<Opportunity> oppListTopdateBlank = new List<Opportunity>();
        System.debug('Dataa=> ' + opp.ApprovalStatus__c);
        if(opp.ApprovalStatus__c == 'Initial Approval Granted' || opp.ApprovalStatus__c ==  'Risk Approval Granted' || opp.ApprovalStatus__c == 'Final Approval Granted' || opp.ApprovalStatus__c == 'Licence Approval Granted' ||
           opp.ApprovalStatus__c == 'Initial Approval Rejected' || opp.ApprovalStatus__c == 'Risk Approval Rejected' || opp.ApprovalStatus__c == 'Final Approval Rejected' || opp.ApprovalStatus__c == 'Licence Approval Rejected'){
            //if(pendingApproverLst.size() == 0){
               if(!String.isBlank(opp.Pending_Approver__c)){
                opp.Pending_Approver__c = null;
                oppListTopdateBlank.add(opp);
               }    
           // }  
        }
        
        if((opp.ApprovalStatus__c == 'Pending Final Approval' || opp.ApprovalStatus__c == 'Pending Initial Approval' ||  opp.ApprovalStatus__c =='Pending Risk Approval' ||  opp.ApprovalStatus__c == 'Pending Licence Approval')){
            system.debug('The pending actor after ');
           List<ProcessInstance> pendingApproverLst = [select id,status, targetobjectid, (SELECT actor.name,originalactorid,StepStatus FROM StepsAndWorkitems) 
                              from ProcessInstance where targetobjectid =: opp.id AND STATUS = 'Pending'];
          
        system.debug('Inside Builder'+  pendingApproverLst);
        
          for(ProcessInstance p: pendingApproverLst){
            system.debug('The pending actor after '+  p.StepsAndWorkitems);
             for(ProcessInstanceHistory h: p.StepsAndWorkitems){
                if(h.StepStatus == 'Pending'){
                     
                    if(opp.Pending_Approver__c != h.actor.Id){
                      opp.Pending_Approver__c = h.actor.Id;
                      oppList.add(opp);
                    }
                }
             }
         
           } 
            
       }
        
        if(oppList.size() > 0)
         update oppList;
        
        if(oppListTopdateBlank.size() > 0)
         update oppListTopdateBlank;
        
        

        return '';
    }
}