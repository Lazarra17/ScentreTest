({
	processBatch : function(component,event,helper){
    	var action= component.get("c.runSpaceManagementBatch");
        component.set("v.isBatchProcessing",true);
        action.setCallback(this, function(response){
            if(response.getState() === "SUCCESS"){
                var jobResponse = response.getReturnValue();
                this.checkBatchStatus(component,true);
            }
        })
        
        $A.enqueueAction(action);
	},
    
    checkBatchStatus : function(component,reCheckStatus){
        var action= component.get("c.checkLatestBatchStatus");
        action.setCallback(this, function(response){
            console.log(response.getState());
            if(response.getState() === "SUCCESS"){
                var jobResponse = response.getReturnValue();
                if(!jobResponse){
                    component.set("v.message","Currently no jobs are running.");
                }else{
                    var jobRec = JSON.parse(jobResponse);
                    if(!jobRec[0].CompletedDate){
                        component.set("v.message","Job is running with status "+jobRec[0].Status);
                        if(reCheckStatus){
                            this.checkBatchStatus(component,reCheckStatus);
                        }
                    }else{
                        component.set("v.isBatchProcessing",false);
                        component.set("v.message","Last processed job ended with status "+ jobRec[0].Status);
                    }   
                }                
            }else{
                component.set("v.message","Error");
            }
            
        })
        
        $A.enqueueAction(action);
    	
	}
})