public with sharing class RentUtility {
	
    public static Map<Id, Double> getRentInfo(List<Opportunity> newOppList) {
        Map<Id, Decimal> resultList = new Map<Id, Decimal>();
        Decimal promotion;

        /*Set<Id> oppIds = new Set<Id>();
        for(Opportunity opp : newOppList){
        	oppIds.add(opp.Id);
        }

        Map<Id, Opportunity> opplst = new Map<Id, Opportunity>([Select Id, AnnualMinimumRent__c, NZProperty__c, PromoLevyIncluded__c, DealType__c, NationalAgreement__r.PromoPercentage__c,NationalAgreement__r.CurrentMinimumThreshold__c,NationalAgreement__r.CurrentMaximumThreshold__c, NationalAgreement__r.Status__c 
        							from Opportunity 
        							where Id IN :oppIds]);
        */ //SOQL FIX - 1
        List<PromotionFund__mdt> promotionFunds = [select id, CategoryAmount__c, CategoryPecentage__c, MaxPromotionFund__c, MaxRequired__c, MinimumPromotionFund__c, MinRequired__c, RentCategory__c, RentRangeMax__c, RentRangeMin__c, Type__c 
        											from PromotionFund__mdt];   

        // Calculate promotion fund
        for(Opportunity opp : newOppList){
        	if(opp.PromoLevyIncluded__c != null && opp.PromoLevyIncluded__c.equals('Yes') && opp.NationalAgreement__c != null && opp.NationalAgreement__r.PromoPercentage__c != null && opp.NationalAgreement__r.Status__c == 'Active'){
	            resultList = calculatePromotionFundBasedOnNatAgree(opp, promotionFunds);
	        }else if (opp.NZProperty__c ==  NULL && opp.AnnualMinimumRent__c != null && opp.AnnualMinimumRent__c > 0 && opp.PromoLevyIncluded__c !=null && opp.PromoLevyIncluded__c.equals('Yes') && opp.DealType__c != null) {
	            resultList = calculatePromotionFundBasedOnFund(opp, promotionFunds);
	        }else if(opp.NZProperty__c != NULL && opp.AnnualMinimumRent__c > 0 && opp.PromoLevyIncluded__c.equals('Yes')){
	            resultList = calculatePromotionFundBasedOnFundNZ(opp, TRUE, promotionFunds);
	        }
        }

        return resultList;
    }

    public static Map<Id, Decimal> calculatePromotionFundBasedOnNatAgree(Opportunity opp, List<PromotionFund__mdt> promotionFunds) {
        Map<Id, Decimal> resultList = new Map<Id, Decimal>();
        Decimal promotion= 0;
        Decimal min = 0;
        Decimal max = 999999999999.99;
        Decimal currentRent = opp.AnnualMinimumRent__c;
        
        
        
        //10705 start
        if(opp.NationalAgreement__r.PromoPercentage__c != Null && opp.NationalAgreement__r.PromoPercentage__c != 0){
            
            promotion = currentRent * opp.NationalAgreement__r.PromoPercentage__c / 100 ;
                if(opp.NationalAgreement__r.CurrentMaximumThreshold__c == Null && opp.NationalAgreement__r.CurrentMinimumThreshold__c == Null){
                        resultList.put(opp.Id, promotion);
                        return resultList;
                }else{
                    if(opp.NationalAgreement__r.CurrentMaximumThreshold__c != Null && promotion >= opp.NationalAgreement__r.CurrentMaximumThreshold__c){
                        promotion = opp.NationalAgreement__r.CurrentMaximumThreshold__c;
                    }
                    if(opp.NationalAgreement__r.CurrentMinimumThreshold__c != Null && promotion <= opp.NationalAgreement__r.CurrentMinimumThreshold__c){
                        promotion = opp.NationalAgreement__r.CurrentMinimumThreshold__c;
                    }
                    resultList.put(opp.Id, promotion);
                    return resultList;
                }
            
        }
       //10705 end

        if(opp.NationalAgreement__r.CurrentMinimumThreshold__c != null){
            min = opp.NationalAgreement__r.CurrentMinimumThreshold__c;
        }
        if(opp.NationalAgreement__r.CurrentMaximumThreshold__c != null){
            max = opp.NationalAgreement__r.CurrentMaximumThreshold__c;
        }

        Decimal promoMinValue = promotionFunds[0].MinimumPromotionFund__c;
        Decimal promoMaxValue = promotionFunds[0].MaxPromotionFund__c;
        Decimal oppNatAgreementMinThreshold = opp.NationalAgreement__r.CurrentMinimumThreshold__c;
        Decimal oppNatAgreementMaxThreshold = opp.NationalAgreement__r.CurrentMaximumThreshold__c;

        promotion = currentRent * opp.NationalAgreement__r.PromoPercentage__c / 100 >= min ? currentRent * opp.NationalAgreement__r.PromoPercentage__c / 100 : min;

        promotion = comparePromoFund(promotion, oppNatAgreementMaxThreshold, oppNatAgreementMinThreshold, promoMaxValue, promoMinValue);
        
        System.debug('promotion: '+promotion);
        resultList.put(opp.Id, promotion);
        return resultList;
    }

    @testVisible
    private static Map<Id, Decimal> calculatePromotionFundBasedOnFund(Opportunity opp, List<PromotionFund__mdt> promotionFunds) {
        Decimal promotion= 0;
        Map<Id, Decimal> resultList = new Map<Id, Decimal>();

        for(PromotionFund__mdt pFund : promotionFunds){
            if(pFund.RentRangeMin__c <= opp.AnnualMinimumRent__c && pFund.RentRangeMax__c >= opp.AnnualMinimumRent__c && opp.DealType__c == pFund.Type__c){
	            
                Decimal promoMinValue = pFund.MinimumPromotionFund__c;
                Decimal promoMaxValue = pFund.MaxPromotionFund__c;
                Decimal oppNatAgreementMinThreshold = opp.NationalAgreement__r.CurrentMinimumThreshold__c;
                Decimal oppNatAgreementMaxThreshold = opp.NationalAgreement__r.CurrentMaximumThreshold__c;
                
                if ((pFund.MinRequired__c != null && pFund.MinRequired__c) || (pFund.MaxRequired__c!= null && pFund.MaxRequired__c)) {
	            	promotion = opp.AnnualMinimumRent__c * pFund.CategoryPecentage__c / 100;
                }else {
	                promotion = opp.AnnualMinimumRent__c * pFund.CategoryPecentage__c / 100 >= pFund.MinimumPromotionFund__c ? opp.AnnualMinimumRent__c * pFund.CategoryPecentage__c / 100 : pFund.MinimumPromotionFund__c;
	            }

                promotion = comparePromoFund(promotion, oppNatAgreementMaxThreshold, oppNatAgreementMinThreshold, promoMaxValue, promoMinValue);

            }
        }
        
        System.debug('promotion: '+promotion);
        resultList.put(opp.Id, promotion);
        return resultList;
    }
	
    @testVisible
    private static Map<Id, Decimal> calculatePromotionFundBasedOnFundNZ(Opportunity Opp, Boolean isThresholdApplicable, List<PromotionFund__mdt> promotionFunds){
        Map<Id, Decimal> resultList = new Map<Id, Decimal>();
        Decimal promotion= 0;
        Decimal currentRent = opp.AnnualMinimumRent__c;

        for(PromotionFund__mdt pFund : promotionFunds){
        	if(pFund.RentRangeMin__c <= opp.AnnualMinimumRent__c && pFund.RentRangeMax__c >= opp.AnnualMinimumRent__c){
                if(opp.NZProperty__c.contains(pFund.Type__c)){
                    Decimal promoMinValue = pFund.MinimumPromotionFund__c;
                    Decimal promoMaxValue = pFund.MaxPromotionFund__c;
                    Decimal oppNatAgreementMinThreshold = opp.NationalAgreement__r.CurrentMinimumThreshold__c;
                    Decimal oppNatAgreementMaxThreshold = opp.NationalAgreement__r.CurrentMaximumThreshold__c;

                    promotion = currentRent * pFund.CategoryPecentage__c / 100;

                    promotion = comparePromoFund(promotion, oppNatAgreementMaxThreshold, oppNatAgreementMinThreshold, promoMaxValue, promoMinValue);
                }
        	}
        }
        
        System.debug('promotion: '+promotion);
        resultList.put(opp.Id, promotion);
        return resultList;
    }

    public static Decimal comparePromoFund(Decimal promotion, Decimal aMaxValue, Decimal aMinValue, Decimal mMaxValue, Decimal mMinValue){

        if(aMaxValue != NULL){
            if(promotion > aMaxValue)
                promotion = aMaxValue;
        }else if(mMaxValue != NULL && promotion > mMaxValue){
            promotion = mMaxValue;
        }
        
        if(aMinValue != NULL){
            if(promotion < aMinValue)
                promotion = aMinValue;
        }else if(mMinValue != NULL && promotion < mMinValue){
            promotion = mMinValue;
        }

        return promotion;
    }
}