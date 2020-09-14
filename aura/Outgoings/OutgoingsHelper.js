({
    getData : function(cmp) {
        var action = cmp.get('c.oppoItemList');
        action.setParams({
            "oppoId": cmp.get("v.recordId")
        });
        action.setCallback(this, $A.getCallback(function(response) {
            var state = response.getState();
            cmp.set("v.isShow", false);
            if (state === "SUCCESS") {
                var oppos = []
                if(response.getReturnValue().lineItemList2){
                    oppos = JSON.parse(response.getReturnValue().lineItemList2);
                }
                if(!response.getReturnValue().oppos[0].DealAchieved__c){ // RPP - 10813
                    cmp.set("v.showoutgoingrefresh",true);
                }
                console.log('oppos***: ');
                console.log(oppos);
                cmp.set('v.mydata', oppos);
                if($A.util.isEmpty(cmp.get("v.mydata"))){
                    cmp.set("v.nooutgoingsmessage",$A.get("$Label.c.NoOutgoingsforSpace"));
                    cmp.set("v.nooutgoings",true);
                }
                cmp.set('v.recoverableArea', response.getReturnValue().rentableArea);
                var userinfo=response.getReturnValue().Userinfo;
                var editableprofiles=$A.get("$Label.c.Editableprofilesforoutgoins").split(";");
                if(editableprofiles.includes(userinfo.Profile.Name)){
                    cmp.set("v.ispriceEditable",true);
                }
                cmp.set('v.mycolumns', [
                    { label: 'Active', fieldName: 'isActive', type: 'boolean',editable:true},
                    { label: 'Item Name', fieldName: 'itemName', type: 'text'},
                    { label: 'Sales Price', fieldName: 'listPrice', type: 'currency', editable: cmp.get("v.ispriceEditable")},
                    { label: 'Total Price', fieldName: 'totalPrice', type: 'currency'}
                ]);
            } else if (state === "ERROR") {
                var errors = response.getError();
                console.log(errors);
            }
        }));
        $A.enqueueAction(action);
    },

    clearDraftValuesLS: function () {
        localStorage.setItem('demo-draft-values', JSON.stringify([]));
    },
    handleEditCell: function (cmp, event) {
        var saveLocalStorage = cmp.get('v.saveLocalStorage');
        if (saveLocalStorage) {
            var atomicChange = event.getParam('draftValues');
            var atomicChanges = cmp.get('v.atomicChanges');
            atomicChanges.push(atomicChange);
            cmp.set('v.changeIndex', atomicChanges.length);
            var draftValues = this.getBuildedDraftValues(atomicChanges, atomicChanges.length);
            localStorage.setItem('demo-draft-values', JSON.stringify(atomicChanges));
        }
    },
    getBuildedDraftValues: function (atomicChanges, lastChange) {
        var draftValues = [];
        var mergeChange = function (change, draft) {
            for (var j = 0; j < change.length; j++) {
                var row = false;
                draft.some(function (searchRow) {
                    if (searchRow['Id'] === change[j].Id) {
                        row = searchRow;
                        return true;
                    };
                    return false;
                });
                
                if (row) {
                    Object.assign(row, change[j]);
                } else {
                    draft.push(change[j]);
                }
            }
        }
        for (var i = 0; i < lastChange; i++) {
            mergeChange(atomicChanges[i], draftValues)
        }
        return draftValues;
    },
    saveChanges: function (cmp, draftValues) {
        var self = this;
        var recoverableArea = cmp.get('v.recoverableArea');
        var action = cmp.get('c.updateOppoLineItem');
        var myWrapper = cmp.get('v.mydata');
        var finalList = [];
        for(var i = 0; i < draftValues.length; i++) {
            var obj = draftValues[i];
            var str = obj.Id;
            var index = str.replace('row-', '');
            var finalItem = new Object();
            if (typeof obj.listPrice != 'undefined') {
                finalItem.listPrice = obj.listPrice;
            } else {
                finalItem.listPrice = myWrapper[index].listPrice;
            }
            if (typeof obj.isActive != 'undefined') {
                finalItem.isActive = obj.isActive;
            } else {
                finalItem.isActive = myWrapper[index].isActive;
            }
            finalItem.itemName = myWrapper[index].itemName;
            finalItem.recordId = myWrapper[index].recordId;           
            finalItem.pricebookEntryId = myWrapper[index].pricebookEntryId;
            finalItem.totalPrice = 0;
            finalList.push(finalItem);
            
        }
        action.setParams({
            "draftValues": JSON.stringify(finalList),
            "oppoId": cmp.get("v.recordId"),
            "recoverableArea": recoverableArea
        });
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState(); 
            var res = response.getReturnValue();
            if (state === "SUCCESS" && res.status === "SUCCESS") {
                self.showToast(cmp, "success", "Success!", "Change applied");
                cmp.set('v.errors', []);
                cmp.set('v.draftValues', []);
                cmp.set('v.atomicChanges', []);
                cmp.set("v.isShow", false);
                self.clearDraftValuesLS();
            } else {
                var errors = response.getError();
                let errorMessage = self.errorHandler(res.message);
                cmp.set("v.isShow", false);
                self.showToast(cmp, "error", "Error! Cannot Save Changes, Please Fix below Errors.", errorMessage);
            }
        }));
        
        $A.enqueueAction(action);
    },
    
    
    
    
    updateQuantity : function(cmp, data){
        var self = this;
        var action = cmp.get('c.updateOppoLineItem');
        var recoverableArea = cmp.get('v.recoverableArea');
        
        action.setParams({
            "draftValues": JSON.stringify(data),
            "oppoId": cmp.get("v.recordId"),
            "recoverableArea": recoverableArea
        });
        
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState(); 
            var res = response.getReturnValue();
            cmp.set("v.isShow", false);
            if (state === "SUCCESS" && res.status === "SUCCESS") {
				/*cmp.find('notifLib').showToast({
					"variant": "success",
                    "title": "Change applied",
				});*/
                self.showToast(cmp, "success", "Success!", "Change applied");
                cmp.set('v.errors', []);
                self.getData(cmp);
            } else {
                var errors = response.getError();
                let errorMessage = self.errorHandler(res.message);
                //self.showToast("Error! Cannot Update Recoverable Area, Please Fix below Errors.", errorMessage, "error");
                self.showToast(cmp, "error", "Error! Cannot Save Changes, Please Fix below Errors.", errorMessage);
            }
        }));
        $A.enqueueAction(action);
    },
    errorHandler : function(message) {
        var idxStack = message.indexOf("STACK TRACE:");
        var msg = idxStack != -1 ? message.substring(0, idxStack-1) : message;
        var idx = msg.indexOf("first error:");
        var errMsg = idx != -1 ? msg.substring(idx + 13, msg.length) : 'Something went wrong. Please contact your System Administrator.';
        
        while(errMsg.includes('&quot;')){
            errMsg = errMsg.replace('&quot;', '');
        }
        
        if(errMsg.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
            errMsg = errMsg.replace('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', '');
            var messages = errMsg.split(':');
            var valMsg = '';
            for(var i=0; i< messages.length - 1; i++){
                valMsg = valMsg + messages[i];
            }
            errMsg = valMsg;
        }
        return errMsg;
    },
     showToast : function(component, type, title, message){
        var toast = component.find("toasto");
        
        toast.set("v.title", title);
        toast.set("v.state", type);
        toast.set("v.message", message);
        
        toast.showToast();
    },
    verifyUserAccess : function(component) {
        var action = component.get("c.userHasEditAccess");
        action.setParams({
            opportunityId : component.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var getReturn = response.getReturnValue();
            if(state === "SUCCESS") {
                if(getReturn){
                    component.set("v.isReadOnly", getReturn);
                } else {
                    component.set('v.mycolumns', [
                        { label: 'Active', fieldName: 'isActive', type: 'boolean',editable:false},
                        { label: 'Item Name', fieldName: 'itemName', type: 'text'},
                        { label: 'Sales Price', fieldName: 'listPrice', type: 'currency', editable:false},
                        { label: 'Total Price', fieldName: 'totalPrice', type: 'currency'}
                    ]);
                }
            } else {
                console.log(getReturn.message);
            }
        });
        $A.enqueueAction(action);
    },
    
    refreshOutgoingsHelper : function(component){
        let self = this;
        let opportunity = component.get("v.targetfieldRecord");
        let actionHandler = component.get("c.refreshOutgoings");
        
        actionHandler.setParams({
            opp : opportunity
        });
        
        actionHandler.setCallback(this, function(response){
            let res = response.getReturnValue();
            console.log('response.getState: '+response.getState());
            if(response.getState() === "SUCCESS" && res.status === "SUCCESS"){
                self.getData(component);
            } else {
                component.set("v.isShow", false);
            }
        })
        
        $A.enqueueAction(actionHandler);
    }
})