public without sharing class OpportunitySplitHandlerAll 
{
     
    public static void SetPAMPercent(List<Opportunity_Split__c> oldList) {
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity_Split__c os : oldList) {
            if(os.TeamMemberRole__c == 'Partner Account Manager')
                oppIds.add(os.Opportunity__c);
        }
        
        if(oppIds.size() > 0) {
            List<Opportunity_Split__c> oppSplitList =
                [
                    SELECT Id, User__c, Opportunity__c, TeamMemberRole__c
                    FROM Opportunity_Split__c
                    WHERE Opportunity__c IN :oppIds AND TeamMemberRole__c = 'Partner Account Manager' AND Percentage__c = 100
                ];
            Map<String, Integer> OppSplitsRolesNumberMap = new Map<String, Integer>();
            for(Opportunity_Split__c oppspl: oppSplitList) {
                OppSplitsRolesNumberMap.put(oppspl.Opportunity__c + '-' + oppspl.TeamMemberRole__c, 1);
            }
            
            for (Opportunity_Split__c os : oldList) {
                if(os.TeamMemberRole__c == 'Partner Account Manager') {
                    if(OppSplitsRolesNumberMap.containsKey(os.Opportunity__c + '-' + os.TeamMemberRole__c)) {
                        os.Percentage__c = 0;
                    } else {
                        os.Percentage__c = 100;
                    }
                }
            }
        }
    }
}