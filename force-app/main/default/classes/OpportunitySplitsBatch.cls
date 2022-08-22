/* run batch =============================================================
   OpportunitySplitsBatch  osBatchObject = new OpportunitySplitsBatch(); 
   Id batchId = Database.executeBatch(osBatchObject);
==========================================================================*/

global class OpportunitySplitsBatch implements Database.Batchable<sObject> {
    public final Set<String> roleSet;
    public final Map<String, Decimal> AvailableTeamMemberRoles;
    
    public OpportunitySplitsBatch() {
        List<AvailableTeamMemberRole__mdt> availableRoles = 
            [
                SELECT Id, Role__c, Percentage__c
                FROM AvailableTeamMemberRole__mdt
            ];

        roleSet = new Set<String>();
        AvailableTeamMemberRoles = new Map<String, Decimal>();

        for(AvailableTeamMemberRole__mdt role : availableRoles)
        {
            roleSet.add(role.Role__c);
            AvailableTeamMemberRoles.put(role.Role__c, role.Percentage__c);
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
        String query = 'SELECT Id FROM Opportunity WHERE LastModifiedDate = LAST_N_DAYS:2';
        return Database.getQueryLocator(query);
    }
     
    global void execute(Database.BatchableContext BC, List<Opportunity> oppList) {
        
        // System.debug('oppList >>>>>>>> ' + oppList);   
        
        Set<String> ExcludePAMGeoSet = new Set<String>{'AMER', 'EMEA'};
        
        List<OpportunityTeamMember> oppTeamMemberList =
            [
                SELECT User.Profile.Name, User.UserRole.Name, Id, TeamMemberRole, UserId, User.GIC_Sales__c, 
                User.Name, OpportunityId, Opportunity.Account_Geo__c, Opportunity.AccountId, Opportunity.Account.Area__c,
                Created_on_opportunity_insert__c, Opportunity.CurrencyIsoCode
                FROM OpportunityTeamMember
                WHERE OpportunityId = :oppList
                AND TeamMemberRole IN :roleSet
            ];
        // System.debug('oppTeamMemberList >>>>>>>> ' + oppTeamMemberList );     
        Set<Id> userIds = new Set<Id>();
        Map<Id, List<OpportunityTeamMember>> otmMap = new Map<Id, List<OpportunityTeamMember>>();
        for(OpportunityTeamMember otm: oppTeamMemberList) {
            userIds.add(otm.UserId);
            if(!otmMap.containsKey(otm.OpportunityId)) {
                otmMap.put(otm.OpportunityId, new List<OpportunityTeamMember>{otm});
            } else {
                List<OpportunityTeamMember> otmList = otmMap.get(otm.OpportunityId);
                otmList.add(otm);
                otmMap.put(otm.OpportunityId, otmList);
            }
        }
        // System.debug('otmMap >>>>>>>> ' + otmMap);  
        
        
        Map<Id, User> oppOwnersMap = new Map<Id, User>([SELECT Id, ProfileId, Profile.Name, UserRoleId, UserRole.Name 
                FROM User
                WHERE Id IN: userIds
            ]);
        // System.debug('oppOwnersMap >>>>>>>> ' + oppOwnersMap );      
        List<Opportunity_Split__c> oppSplitList =
            [
                SELECT User__r.Profile.Name, User__r.UserRole.Name,User__r.Goal_Master_Role__c, 
                    Included_in_Compensation__c, Id, Percentage__c, User__c, Opportunity__c, 
                    User__r.Name,  TeamMemberRole__c, User__r.GIC_Sales__c
                FROM Opportunity_Split__c
                WHERE Opportunity__c = :oppList
            ];
        
        Map<Id, Set<String>> osMap = new Map<Id, Set<String>>();
        for(Opportunity_Split__c oppspl: oppSplitList) {
            String s = oppspl.Opportunity__c + '-' + oppspl.User__c + '-' + oppspl.TeamMemberRole__c;
            if(!osMap.containsKey(oppspl.Opportunity__c)) {
                osMap.put(oppspl.Opportunity__c, new Set<String> {s});
            } else {
                Set<String> otmSet = osMap.get(oppspl.Opportunity__c);
                otmSet.add(s);
                osMap.put(oppspl.Opportunity__c, otmSet);
            }
        }
        // System.debug('osMap >>>>>>>> ' + osMap); 
        
        List<Opportunity_Split__c> oppSplitToInsert = new List<Opportunity_Split__c>();
        for(Id oppId: otmMap.keySet()) {
            List<OpportunityTeamMember> otmOppList = otmMap.get(oppId);
            Set<String> oppSplitSet = osMap.get(oppId);
            for(OpportunityTeamMember oppTeam: otmOppList) {
                if(!(ExcludePAMGeoSet.contains(oppTeam.Opportunity.Account_Geo__c) && oppTeam.Opportunity.Account.Area__c != 'Japan' && oppTeam.TeamMemberRole == 'Partner Account Manager' && oppTeam.Created_on_opportunity_insert__c == true) &&
                !(oppTeam.Opportunity.Account.Area__c == 'Japan' &&  oppTeam.TeamMemberRole == 'Partner Account Manager' && oppTeam.Created_on_opportunity_insert__c == false)) {
                    if(AvailableTeamMemberRoles.containsKey(oppTeam.TeamMemberRole)) {
                        if(oppSplitSet == null || !oppSplitSet.contains(oppTeam.OpportunityId + '-' + oppTeam.UserId + '-' + oppTeam.TeamMemberRole)) {
                            Opportunity_Split__c oppSplit = new Opportunity_Split__c();
                            oppSplit.Opportunity__c = oppTeam.OpportunityId;
                            oppSplit.User__c = oppTeam.UserId;
                            if(!AvailableTeamMemberRoles.containsKey(oppTeam.TeamMemberRole)) {
                                oppSplit.Percentage__c = AvailableTeamMemberRoles.get(oppTeam.TeamMemberRole);
                            } else
                                oppSplit.Percentage__c = 0;
                            if(oppTeam.TeamMemberRole == 'Opportunity Owner' && oppOwnersMap.containsKey(oppTeam.UserId)) {
                                User u = oppOwnersMap.get(oppTeam.UserId);
                                if((u.Profile.Name).contains('Partner') || (u.UserRoleId != null && u.UserRole.Name.contains('Partner')))
                                    oppSplit.TeamMemberRole__c = 'Partner Account Manager';
                                else
                                    oppSplit.TeamMemberRole__c = oppTeam.TeamMemberRole; 
                            } else {
                                oppSplit.TeamMemberRole__c = oppTeam.TeamMemberRole; 
                            }                       
                            oppSplit.CurrencyIsoCode = oppTeam.Opportunity.CurrencyIsoCode;
                            oppSplitToInsert.add(oppSplit);
                        }
                    }
                }
            }
        }
        // System.debug('oppSplitToInsert >>>>>>>> ' + oppSplitToInsert);     
        if(oppSplitToInsert.size() > 0) {
            try {
                insert oppSplitToInsert;
            } catch(Exception e) {
                System.debug(e);
            }
        }    
       
    }

    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email
    }
}