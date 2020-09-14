({
	sendToVF : function(row, component) {
        console.log('row', JSON.stringify(row));
        var message = row.UnitNo__c;
        var vfOrigin = "https://" + component.get("v.vfHost");
        console.log('vfOrigin', vfOrigin);
        var vfWindow = component.find("vfFrame").getElement().contentWindow;
        vfWindow.postMessage(message, vfOrigin);
    },
})