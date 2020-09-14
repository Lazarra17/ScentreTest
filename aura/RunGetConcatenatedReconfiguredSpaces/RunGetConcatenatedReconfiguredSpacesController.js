({
	init : function(component, event, helper) {
		
		var action = component.get("c.getOpp");
				action.setParams({
					"opportunityId": component.get("v.recordId"),
                    "buttonName": component.get("v.buttonName")
				});
        		console.log('my button name', component.get("v.buttonName"));
				action.setCallback(this, function(response) {
					var state = response.getState();
					if (state === "SUCCESS") {
						var res = response.getReturnValue();
                        var DS7 = 0;
                        if(component.get("v.buttonName") != null) {
                            DS7=11;
                        }
                        let buttonName = component.get("v.buttonName")
                        var CongaUrl = '';
                        if (buttonName === 'generateInternalOwnersPack') {
                            CongaUrl = '/apex/APXTConga4__Conga_Composer'+
										'?sessionId='+res.sessionId+
										'&serverUrl='+res.partnerServer+
										'&Id='+res.Id+
										'&DefaultPDF=1'+
										'&SC0=1'+
										'&DS4=1'+
										'&DS7=' + DS7 +
										'&SC1=SalesforceFile'+
										'&BML=Owner+Pack+-+'+res.Name+
										'&TemplateId='+res.TemplateOwnerPack+
										'&AttachmentParentID='+res.Id+
										'&ContactId='+res.PrimaryContactId+
										'&QueryId=[SpaceandProperty]'+res.SpaceandProperty+'?pv0='+res.Id+',[CappedOccClause]'+res.CappedOccClause+'?pv0='+res.Id+',[PromoFund]'+res.PromotionLevy+'?pv0='+res.Id+',[EstimatedOutgoings]'+res.EstimatedOutgoings+'?'+res.Id+',[ExistingSpace]'+res.ExistingSpace+'?pv0='+res.Id+',[Dexus]'+res.Dexus+'?pv0='+res.PropertyId+',[SUMforOwnerPack]'+res.SUMforOwnerPack+'?pv0='+res.Id+',[SpaceGroup]'+res.SpaceGroup+'?pv0='+res.SpaceId+',[ReconfiguredSpace]'+res.ReconfiguredSpace+'?pv0='+res.concatenatedSpaces+',[SUMofReconfigured]'+res.SUMofReconfigured+'?pv0='+res.concatenatedSpaces+',[SpecialCondi]'+res.SpecialCondi+'?pv1='+res.Id+',[GuarantorNames]'+res.GuarantorNames+'?pv0='+res.Id+',[OpptyClause]'+res.OpptyClause+'?pv0='+res.Id+',[OpportunityLineItems]'+res.OpportunityLineItems+'?pv0='+res.Id+
										'&OFN=Internal Owner\'s+Pack';
                        } else {
                            CongaUrl = '/apex/APXTConga4__Conga_Composer'+
										'?sessionId='+res.sessionId+
										'&serverUrl='+res.partnerServer+
										'&Id='+res.Id+
										'&DefaultPDF=1'+
										'&SC0=1'+
										'&DS4=1'+
										'&DS7=' + DS7 +
										'&SC1=SalesforceFile'+
										'&BML=Owner+Pack+-+'+res.Name+
										'&TemplateId='+res.TemplateOwnerPack+
										'&AttachmentParentID='+res.Id+
										//'&ContactId='+res.PrimaryContactId+
										'&QueryId=[SpaceandProperty]'+res.SpaceandProperty+'?pv0='+res.Id+',[CappedOccClause]'+res.CappedOccClause+'?pv0='+res.Id+',[PromoFund]'+res.PromotionLevy+'?pv0='+res.Id+',[EstimatedOutgoings]'+res.EstimatedOutgoings+'?'+res.Id+',[ExistingSpace]'+res.ExistingSpace+'?pv0='+res.Id+',[Dexus]'+res.Dexus+'?pv0='+res.PropertyId+',[SUMforOwnerPack]'+res.SUMforOwnerPack+'?pv0='+res.Id+',[SpaceGroup]'+res.SpaceGroup+'?pv0='+res.SpaceId+',[ReconfiguredSpace]'+res.ReconfiguredSpace+'?pv0='+res.concatenatedSpaces+',[SUMofReconfigured]'+res.SUMofReconfigured+'?pv0='+res.concatenatedSpaces+',[SpecialCondi]'+res.SpecialCondi+'?pv1='+res.Id+',[GuarantorNames]'+res.GuarantorNames+'?pv0='+res.Id+',[OpptyClause]'+res.OpptyClause+'?pv0='+res.Id+',[OpportunityLineItems]'+res.OpportunityLineItems+'?pv0='+res.Id+
										'&OFN=Owner\'s+Pack+-'+res.Name;

                        }
						 if(!$A.util.isEmpty(CongaUrl)){
							var urlEvent = $A.get("e.force:navigateToURL");
							urlEvent.setParams({
								"url": CongaUrl              
							});
							urlEvent.fire();
						 } 
						
					}

				});
				// Send action off to be executed
				$A.enqueueAction(action);  

    }
})