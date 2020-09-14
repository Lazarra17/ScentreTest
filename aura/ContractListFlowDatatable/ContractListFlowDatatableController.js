({
    doInit : function(component, event, helper) { 
        component.set('v.selectedRows', null);
        var dataArr = new Array();
        var colsStr = component.get('v.columnsStr');
        var fieldNameArr = new Array();
        if(colsStr){
            var colStrArr = colsStr.split(';');
            if(colStrArr){
                var colArr = new Array();
                for(var i = 0; i < colStrArr.length; i++){
                    var colDetailArr = colStrArr[i].split(',');
                    if(colDetailArr.length === 3){
                        if(colDetailArr[1] !== "Id"){
                            var colObj = {label: colDetailArr[0], fieldName: colDetailArr[1], type:  colDetailArr[2]};
                            colArr.push(colObj);
                        }
                        fieldNameArr.push(colDetailArr[1]);
                    }
                }
                component.set('v.columns', colArr);        
            }
        }        
        var dataStrArr = component.get('v.dataArr');
        if(dataStrArr){
            for(var j = 0; j < dataStrArr.length; j++){
                var fieldArr = dataStrArr[j].split(',');
                if(fieldArr.length === fieldNameArr.length){
                    var jsonStr = '{';
                    for(var k = 0; k < fieldArr.length; k++){
                        var delimeter = k === (fieldArr.length - 1) ? '' : ',';
                        jsonStr += '"' + fieldNameArr[k] + '" : ' + '"' + fieldArr[k] + '" ' + delimeter;
                    }
                    jsonStr += '}'
                    dataArr.push(JSON.parse(jsonStr));
                }
            }
            component.set('v.data', dataArr);            
        }
    },
    getSelectedId: function(component, event, helper){
        component.set('v.selectedRows', null);
        var selectedRows = event.getParam('selectedRows');
        var key = component.get('v.key');
        var contractSelected = [];
        if(selectedRows){
            for(var i = 0; i < selectedRows.length; i++){
                contractSelected.push(selectedRows[i][key]);
            }
            component.set('v.selectedRows', contractSelected);            
        }
    }
})