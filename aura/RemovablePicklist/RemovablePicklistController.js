({
    handleChange: function (component, event) {
        // This will contain the string of the "value" attribute of the selected option
        let selectedOptionValue = event.getParam("value");
        let pickListValue = component.get('v.picklist');
        let previousValue = component.get('v.previousSelect');
        component.set('v.currentSelect', selectedOptionValue);
    },
    init : function(component, event, helper) {
        let previousValue = component.get('v.previousSelect');
        let pickListValue = component.get('v.picklist');
        console.log('current pickListValue', pickListValue);
        console.log('current previousValue', previousValue);
        if (!$A.util.isUndefinedOrNull(previousValue) && previousValue != '') {
            pickListValue = pickListValue.replace(previousValue + ";", "");
            pickListValue = pickListValue.replace(";" + previousValue, "");
            pickListValue = pickListValue.replace(previousValue, "");
        }
        console.log('after pickListValue', pickListValue);
        component.set('v.outPicklist', pickListValue);
        if (!$A.util.isUndefinedOrNull(pickListValue) && pickListValue != '') {
            let valueSet = [];
            let res = pickListValue.split(";");
            let arrayLength = res.length;
            for (var i = 0; i < arrayLength; i++) {
                let item = {};
                item.label = res[i];
                item.value = res[i];
                valueSet.push(item);
            }
            component.set('v.options', valueSet);
        } else {
            component.set('v.renderOption', false);
            component.set('v.currentSelect', 'Finish');
        }
	},
})