({
    searchABNHelper : function(component, service, searchValue) {
        let self = this;
        let accountABNDetails;
        let actionHandler = component.get("c.getABNDetails");
        let accountRec = component.get("v.mainRecord");
        
        actionHandler.setParams({
            service : service,
            searchValue : searchValue
        });
        
        actionHandler.setCallback(this, function(response){
            let res = response.getReturnValue();
            if(res.status!==null){
                if(res.status === "SUCCESS"){
                    if(res.returnValue) {
                        if(service === 'ABN') {
                            let abnDetails = JSON.parse(res.returnValue);
                            component.set("v.abnResult", abnDetails);
                            if(component.get("v.abnResult.abn")!=null&&component.get("v.abnResult.abn")!=" "){
                                component.set("v.showABN", true);
                            }
                            var optionsValueList=[];
                            if(abnDetails.businessName) {
                                for(let tradingamevar of abnDetails.businessName){
                                    optionsValueList.push({
                                        label:tradingamevar, 
                                        value:tradingamevar}); 
                                }
                                component.set("v.abnBusinessNamesoptions",optionsValueList);
                            }
                        } else if(service === 'ACN') {
                            let acnDetails = JSON.parse(res.returnValue);
                            component.set("v.acnResult", acnDetails);
                            var optionsValueList=[];
                            
                            if(component.get("v.acnResult.abn")!=null&&component.get("v.acnResult.abn")!=" "){
                                component.set("v.showACN", true);
                            }
                            if(acnDetails.businessName) {
                                for(let tradingamevar of acnDetails.businessName){
                                    optionsValueList.push({
                                        label:tradingamevar, 
                                        value:tradingamevar}); 
                                }
                                component.set("v.acnBusinessNamesoptions",optionsValueList);
                            }
                        }
                    }
                } else {
                    console.log("ERROR : ", res.message);
                    if(service === 'ABN') {
                        component.set("v.abnErrorMessage", res.message);
                        component.set("v.abnResult", "");
                        component.set("v.abnBusinessNames", "");
                        component.set("v.showABN",true);
                    } else if(service === 'ACN') {
                        component.set("v.acnErrorMessage", res.message);
                        component.set("v.acnResult", "");
                        component.set("v.acnBusinessNames", "");
                        component.set("v.showACN",true);
                    }
                }
            }
        });
        component.set("v.isLoading", false);
        $A.enqueueAction(actionHandler);
    },
    searchNZBNHelper : function(component) {
        let self = this;
        let accountABNDetails;
        let actionHandler = component.get("c.getNZBNDetails");
        let accountRec = component.get("v.mainRecord");
        
        actionHandler.setParams({
            searchValue : accountRec.ABNNZBN__c
        });
        
        actionHandler.setCallback(this, function(response){
            let res = response.getReturnValue();
            if(res.status === "SUCCESS"){
                if(res.returnValue) {
                    let nzbnDetails = JSON.parse(res.returnValue);
                    component.set("v.nzbnResult", nzbnDetails);
                    if(component.get("v.nzbnResult.nzbn") != null && component.get("v.nzbnResult.nzbn") != "") {
                        component.set("v.showNZBN", true);
                    }
                }
            } else {
                component.set("v.nzbnErrorMessage", res.message);
                //component.set("v.nzbnResult", "");
                if(component.get("v.nzbnResult")!==null){
               	 component.set("v.nzbnResult.nzbn", accountRec.ABNNZBN__c);
                }
            }
            component.set("v.isLoading", false);
        });
        
        $A.enqueueAction(actionHandler);
    },
    setBusinessNames : function(arrBusinessNames){
        let concatBusinessNames = "";
        var optionsValueList=[];
        for(let bName of arrBusinessNames){
            concatBusinessNames += bName + "\n";
        }
        concatBusinessNames = concatBusinessNames.substring(0, concatBusinessNames.lastIndexOf("\n"));
        return concatBusinessNames;
    },
    
    validateUpdateOperationHelper : function(component, event) {
        let actionHandler = component.get("c.isaccountvalidtoupdatedetails");
        let accountRec = component.get("v.mainRecord.Id");
        actionHandler.setParams({
            accountRecordId : accountRec
        });
        actionHandler.setCallback(this, function(response){           
            let res = response.getReturnValue();
            if(res.status!==null&&res.status === "SUCCESS"){
                let returndetails = JSON.parse(res.returnValue);
                component.set("v.activecontracts",returndetails);
                if(returndetails <= 0) {
                    this.updateAccountDataHelper(component,event);
                } else {
                    component.find('notifLib').showToast({
                        "title": "Error On Updating Account!",
                        "message": $A.get("$Label.c.ABNActiveContractErrorMessage"),
                        "variant": "error"
                    });
                }
            }
        });
        $A.enqueueAction(actionHandler);
    },
    updateAccountDataHelper : function(component, event) {
        var mainRecord = component.get("v.mainRecord");
        var recordCountry = component.get("v.recordCountry");
        var sobjectName = component.get("v.sObjectName");
        var recordDataId;
        var abnnzbnStatus;
        var buttonname=event.getSource().get("v.name");
        if(sobjectName == 'Lead') {
            recordDataId = 'leadRecord';
        } else if(sobjectName == 'Account') {
            recordDataId = 'opportunityRecord';
        }
        //component.find(recordDataId).reloadRecord();
        component.set("v.isLoading", true);
        if(recordCountry == 'New Zealand') {
            if(component.find("nzStatus").get("v.value") === 'Registered') {
                abnnzbnStatus = 'Active';
            } else {
                abnnzbnStatus = 'InActive';
            }
            if(abnnzbnStatus != null) {
                component.set("v.mainRecord.ABNNZBNStatus__c", abnnzbnStatus);
            }
            console.log("buttonname: "+ buttonname);
            if(buttonname==="nzbnupdatebutton"){
                if(component.get("v.nzbnResult.entityName")!==null && !$A.util.isEmpty(component.get("v.nzbnResult.entityName"))){
                    component.set("v.mainRecord.LesseeName__c", component.get("v.nzbnResult.entityName"));
                }
            }
        } else if(recordCountry === 'Australia') {
            
            console.log("buttonname: "+ buttonname);
            var abnNZBNStatus;
            if(buttonname==="abnupdatebutton"){
                if(component.find("status").get("v.value") === 'Active') {
                    abnnzbnStatus = 'Active';
                } else {
                    abnnzbnStatus = 'InActive';
                }
                if(component.get("v.abnResult.entityName")!==null && !$A.util.isEmpty(component.get("v.abnResult.entityName"))){
                    component.set("v.mainRecord.LesseeName__c", component.get("v.abnResult.entityName"));
                }
                if(component.get("v.abnBusinessNamestring")!==null && !$A.util.isEmpty(component.get("v.abnBusinessNamestring"))){
                    component.set("v.mainRecord.TradingName__c", component.get("v.abnBusinessNamestring"));
                }
            }else if(buttonname==="acnupdatebutton"){
                if(component.find("acnStatus").get("v.value") === 'Active') {
                    abnnzbnStatus = 'Active';
                } else {
                    abnnzbnStatus = 'InActive';
                }
                if(component.get("v.acnResult.entityName")!==null && !$A.util.isEmpty(component.get("v.acnResult.entityName"))){
                    component.set("v.mainRecord.LesseeName__c", component.get("v.acnResult.entityName"));
                }
                if(component.get("v.acnBusinessNamestring")!==null&& !$A.util.isEmpty(component.get("v.acnBusinessNamestring"))){
                    component.set("v.mainRecord.TradingName__c", component.get("v.acnBusinessNamestring"));
                }
            }
            component.set("v.mainRecord.ABNNZBNStatus__c", abnnzbnStatus);
        }
        
        component.find(recordDataId).saveRecord(function(saveResult) {
            if(saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                component.set("v.isLoading", false);
                component.find('notifLib').showToast({
                    "title": "Success On Updating Account!",
                    "message": "The record has been updated successfully.",
                    "variant": "success"
                });
            } else if (saveResult.state === "ERROR") {
                component.set("v.isLoading", false);
                component.find('notifLib').showToast({
                    "title": "Error On Updating Account!",
                    "message": "Error On Update.",
                    "variant": "error"
                });
            }
        });
    }
})