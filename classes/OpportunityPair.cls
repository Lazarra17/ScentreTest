public class OpportunityPair {
	
    public class OppoPair {
        public String primaryOppoId;
        public String secondOppoId;
    }
    
    public static boolean checkKeyPairExist (List<OppoPair> oppoPairs, String primaryId, String secondaryId) {
        if (oppoPairs.size() > 0) {
            for (OppoPair oppoPair : oppoPairs) {
                if ((oppoPair.primaryOppoId == primaryId && oppoPair.secondOppoId == secondaryId)
                   || (oppoPair.primaryOppoId == secondaryId && oppoPair.secondOppoId == primaryId)) {
                    return true;
                }
            }
        }
        return false;
    }
    
    public static List<OppoPair> produceKeyPairs (Set<String> oppoIds) {
        List<OppoPair> oppoPairsNew = new List<OppoPair>();
        for (String mString : oppoIds) { // Primary
            for (String nString : oppoIds) { // Secondary
                if (mString == nString) {
                    continue;
                } else {
                    //if (!checkKeyPairExist(oppoPairsNew, mString, nString)) {
                        OppoPair pairNew = new OppoPair();
                        pairNew.primaryOppoId = mString;
                        pairNew.secondOppoId = nString;
                        oppoPairsNew.add(pairNew);
                    //}
                }
            }
    	}
        //System.debug(oppoPairsNew);
        return oppoPairsNew;
    }
}