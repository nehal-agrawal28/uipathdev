public without sharing class OppTeamMemberHandlerAll 
{
    
    private static Map<String, Decimal> AvailableTeamMemberRolesCached;
    
    private static  Map<String, Decimal> AvailableTeamMemberRoles {
        get {
            List<AvailableTeamMemberRole__mdt> availableRoles = 
                [
                    SELECT Id, Role__c, Percentage__c
                    FROM AvailableTeamMemberRole__mdt 
                    
                ];
    
            AvailableTeamMemberRolesCached = new Map<String, Decimal>();
    
            for(AvailableTeamMemberRole__mdt role : availableRoles) {
                AvailableTeamMemberRolesCached.put(role.Role__c, role.Percentage__c);
            }
            
            return AvailableTeamMemberRolesCached;
        }
    }

    public static void preventAddingTeamMember(List<OpportunityTeamMember> oppTeamMemberList, Map<Id, OpportunityTeamMember> oppTeamMemberOldMap) {
        User usr = [SELECT Id, ProfileId FROM User WHERE Id = :UserInfo.getUserId()];
        Validation_Skip_Opportunity_Team__c userValidation = Validation_Skip_Opportunity_Team__c.getInstance(usr.Id);
        Validation_Skip_Opportunity_Team__c profileValidation = Validation_Skip_Opportunity_Team__c.getInstance(usr.ProfileId);
        
        Set<Id> oppIds = new Set<Id>();
        for( OpportunityTeamMember otm: oppTeamMemberList ) {
            if(oppTeamMemberOldMap != null) {
                OpportunityTeamMember oldOppTeamMember = oppTeamMemberOldMap.get(otm.Id);
                if(oldOppTeamMember.TeamMemberRole == 'Opportunity Owner' && oldOppTeamMember.TeamMemberRole != otm.TeamMemberRole && userValidation.Skip_ManuallyChange_Opp_Owner_Validation__c != 'Yes' && profileValidation.Skip_ManuallyChange_Opp_Owner_Validation__c != 'Yes')
                {
                    otm.addError('You cannot change the Opportunity Owner manually.');
                    continue;
                }
            }
            oppIds.add(otm.Id);
        }
        
        List<OpportunityTeamMember> AllOppTeamMembers = [SELECT Id, OpportunityId, UserId FROM OpportunityTeamMember WHERE OpportunityId IN: oppIds];
        Map<Id, Set<Id>> UserIdsByOpportunityMap = new Map<Id, Set<Id>>();
        for( OpportunityTeamMember otm: AllOppTeamMembers ) {
            if(!UserIdsByOpportunityMap.containsKey(otm.OpportunityId)) {
                Set<Id> otmSet = new Set<Id>();
                otmSet.add(otm.UserId);
                UserIdsByOpportunityMap.put(otm.OpportunityId, otmSet);
            } else {
                Set<Id> otmSet = UserIdsByOpportunityMap.get(otm.OpportunityId);
                otmSet.add(otm.UserId);
                UserIdsByOpportunityMap.put(otm.OpportunityId, otmSet);
            }
        }
        System.debug(UserIdsByOpportunityMap);
        for(OpportunityTeamMember otm: oppTeamMemberList) {
            if(UserIdsByOpportunityMap.containsKey(otm.OpportunityId)) {
                Set<Id> ExistingUsers = UserIdsByOpportunityMap.get(otm.OpportunityId);
                if(ExistingUsers.contains(otm.UserId)) {
                    otm.addError('This user already has a role on this opportunity.');
                }
            }
        }
        
    }
    
    public static void CreateOpportunitySplits(List<OpportunityTeamMember> oppTeamMemberList) {

        Set<String> ExcludePAMGeoSet = new Set<String>{'AMER', 'EMEA'};
        List<OpportunityTeamMember> includeOTM = [SELECT Id, OpportunityId, Created_on_opportunity_insert__c, Opportunity.CurrencyIsoCode, Opportunity.Account_Geo__c, Opportunity.Account.Area__c, UserId, TeamMemberRole, Do_Not_Create_Split__c  
            FROM OpportunityTeamMember
            WHERE Id IN: oppTeamMemberList];
        List<OpportunityTeamMember> selectedOTM = new List<OpportunityTeamMember>();
        Set<Id> oppIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        for(OpportunityTeamMember otm: includeOTM ) {
            if(otm.Do_Not_Create_Split__c == false && (!(ExcludePAMGeoSet.contains(otm.Opportunity.Account_Geo__c) && otm.Opportunity.Account.Area__c != 'Japan' && otm.TeamMemberRole == 'Partner Account Manager' && otm.Created_on_opportunity_insert__c == true) &&
            !(otm.Opportunity.Account.Area__c == 'Japan' &&  otm.TeamMemberRole == 'Partner Account Manager' && otm.Created_on_opportunity_insert__c == false))) {
                oppIds.add(otm.OpportunityId);
                userIds.add(otm.UserId);
                selectedOTM.add(otm);
            }
        }
        if(oppIds.size() > 0) {
            List<Opportunity_Split__c> oppSplitList =
                [
                    SELECT Id, User__c, Opportunity__c, TeamMemberRole__c
                    FROM Opportunity_Split__c
                    WHERE Opportunity__c IN :oppIds
                ];
            Map<String, Integer> OppSplitsRolesNumberMap = new Map<String, Integer>();
            for(Opportunity_Split__c oppspl: oppSplitList) {
                if(!OppSplitsRolesNumberMap.containsKey(oppspl.Opportunity__c + '-' + oppspl.TeamMemberRole__c)) {
                    OppSplitsRolesNumberMap.put(oppspl.Opportunity__c + '-' + oppspl.TeamMemberRole__c, 1);
                } else {
                    Integer roleNo = OppSplitsRolesNumberMap.get(oppspl.Opportunity__c + '-' + oppspl.TeamMemberRole__c);
                    OppSplitsRolesNumberMap.put(oppspl.Opportunity__c + '-' + oppspl.TeamMemberRole__c, roleNo + 1);
                }
            }
            
            
            Map<Id, User> oppOwnersMap = new Map<Id, User>([SELECT Id, ProfileId, Profile.Name, UserRoleId, UserRole.Name 
                FROM User
                WHERE Id IN: userIds
            ]);
            List<Opportunity_Split__c> oppSplitToInsert = new List<Opportunity_Split__c>();
            for(OpportunityTeamMember oppTeam: selectedOTM) {
                if(AvailableTeamMemberRoles.containsKey(oppTeam.TeamMemberRole)) {
                    //if(oppTeam.Created_on_opportunity_insert__c == false) {
                        Opportunity_Split__c oppSplit = new Opportunity_Split__c();
                        oppSplit.Opportunity__c = oppTeam.OpportunityId;
                        oppSplit.User__c = oppTeam.UserId;
                        if(!OppSplitsRolesNumberMap.containsKey(oppTeam.OpportunityId + '-' + oppTeam.TeamMemberRole)) {
                            oppSplit.Percentage__c = AvailableTeamMemberRoles.get(oppTeam.TeamMemberRole);
                        } else
                            oppSplit.Percentage__c = 0;
                        if(oppTeam.TeamMemberRole == 'Opportunity Owner' && oppOwnersMap.containsKey(oppTeam.UserId)) {
                            User u = oppOwnersMap.get(oppTeam.UserId);
                            if((u.Profile.Name).contains('Partner') || (u.UserRoleId != null && u.UserRole.Name.contains('Partner'))) {
                                oppSplit.TeamMemberRole__c = 'Partner Account Manager';
                                oppSplit.Percentage__c = 100;
                            } else
                                oppSplit.TeamMemberRole__c = oppTeam.TeamMemberRole; 
                        } else {
                            oppSplit.TeamMemberRole__c = oppTeam.TeamMemberRole; 
                        }                       
                        oppSplit.CurrencyIsoCode = oppTeam.Opportunity.CurrencyIsoCode;
                        //oppSplit.Opportunity_Team_Member__c = oppTeam.Id;
                        oppSplitToInsert.add(oppSplit);
                       
                    //}
                }
            }
            system.debug('Insert oppSplitToInsert =====> ' + oppSplitToInsert);
            if(oppSplitToInsert.size() > 0) {
                insert oppSplitToInsert;
            }
        }
    }
    
    

    
    public static void UpdateOpportunitySplits(List<OpportunityTeamMember> oppTeamMemberList, Map<Id, OpportunityTeamMember> oppTeamMemberOldMap)
    {
        Set<Id> userIds = new Set<Id>();
        Set<String> oppIds = new Set<String>();
        List<OpportunityTeamMember> oppTeamMembers = new List<OpportunityTeamMember>();
        
        
        List<OpportunityTeamMember> includeOTM = [SELECT Id, Created_on_opportunity_insert__c, OpportunityId, Opportunity.CurrencyIsoCode, Opportunity.Account_Geo__c, Opportunity.AccountId, Opportunity.Account.Area__c, UserId, TeamMemberRole, Do_Not_Create_Split__c  
            FROM OpportunityTeamMember
            WHERE Id IN: oppTeamMemberList];

        for(OpportunityTeamMember oppTeamMember : includeOTM )
        {
            OpportunityTeamMember oldOppTeamMember = oppTeamMemberOldMap.get(oppTeamMember.Id);
            if((oppTeamMember.UserId != oldOppTeamMember.UserId || oppTeamMember.TeamMemberRole != oldOppTeamMember.TeamMemberRole) /*&& oppTeamMember.Created_on_opportunity_insert__c == false*/)
            {
                oppIds.add(oppTeamMember.OpportunityId);
                userIds.add(oppTeamMember.UserId);
                oppTeamMembers.add(oppTeamMember);
            }
        }
        // system.debug('Update oppTeamMembers =====> ' + oppTeamMembers);
        if(!oppIds.isEmpty()) {
            List<Opportunity_Split__c> oppSplitList =
                [
                    SELECT Id, User__c, Opportunity__c, TeamMemberRole__c
                    FROM Opportunity_Split__c
                    WHERE Opportunity__c IN :oppIds
                ];
            
             Map<Id, User> oppOwnersMap = new Map<Id, User>([SELECT Id, ProfileId, Profile.Name, UserRoleId, UserRole.Name 
                FROM User
                WHERE Id IN: userIds
            ]);
            // system.debug('Update oppSplitList =====> ' + oppSplitList );
            List<Opportunity_Split__c> osToUpsert = new List<Opportunity_Split__c>();
            List<Opportunity_Split__c> osToDelete = new List<Opportunity_Split__c>();
            
            if(!oppSplitList.isEmpty()) {
                Map<String, Opportunity_Split__c> OpportunitySplitMap = new Map<String, Opportunity_Split__c>(); 
                
                for(Opportunity_Split__c os: oppSplitList) {
                    String mapKey = String.valueOf(os.Opportunity__c) + '-' + String.valueOf(os.User__c);
                    OpportunitySplitMap.put(mapKey, os);
                }
               
                
                Set<String> ExcludePAMGeoSet = new Set<String>{'AMER', 'EMEA'};
                
                for(OpportunityTeamMember otm : oppTeamMembers)
                {    
                    String mapkeycheck = String.valueOf(otm.OpportunityId) + '-' + String.valueOf(otm.UserId);
                    
                    if(!(ExcludePAMGeoSet.contains(otm.Opportunity.Account_Geo__c) && otm.Opportunity.Account.Area__c != 'Japan' && otm.TeamMemberRole == 'Partner Account Manager' && otm.Created_on_opportunity_insert__c == true) &&
                    !(otm.Opportunity.Account.Area__c == 'Japan' && otm.TeamMemberRole == 'Partner Account Manager' && otm.Created_on_opportunity_insert__c == false)) {    
                        if(OpportunitySplitMap.containsKey(mapkeycheck))
                        {
                            Opportunity_Split__c oppsp = OpportunitySplitMap.get(mapkeycheck);
                            if(!AvailableTeamMemberRoles.containsKey(otm.TeamMemberRole)) {
                                osToDelete.add(oppsp);
                                
                            } else {
                                if(otm.TeamMemberRole == 'Opportunity Owner' || otm.TeamMemberRole == 'Global Account Manager'
                                        || otm.TeamMemberRole == 'Key Account Manager') {
                                    
                                    osToDelete.add(oppsp);
                                    //otm.addError('The user is already a team member with another role.');
                                    if(otm.TeamMemberRole == 'Opportunity Owner' && otm.Created_on_opportunity_insert__c == true){
                                        Opportunity_Split__c newOS = addOpportunityOwnerSplit(otm);
                                        osToUpsert.add(newOS);
                                    }
                                } else {
                                    oppsp.Percentage__c = AvailableTeamMemberRoles.get(otm.TeamMemberRole);
                                    oppsp.TeamMemberRole__c = otm.TeamMemberRole;
                                    osToUpsert.add(oppsp);
                                }
                            }
                            
                        } else {
                            if(AvailableTeamMemberRoles.containsKey(otm.TeamMemberRole)) {
                                Opportunity_Split__c oppSplit = new Opportunity_Split__c();
                                oppSplit.Opportunity__c = otm.OpportunityId;
                                oppSplit.User__c = otm.UserId;
                                oppSplit.Percentage__c = AvailableTeamMemberRoles.get(otm.TeamMemberRole);
                                if(otm.TeamMemberRole == 'Opportunity Owner' && oppOwnersMap.containsKey(otm.UserId)) {
                                    User u = oppOwnersMap.get(otm.UserId);
                                    if((u.Profile.Name).contains('Partner') || (u.UserRoleId != null && u.UserRole.Name.contains('Partner'))) {
                                        oppSplit.TeamMemberRole__c = 'Partner Account Manager';
                                        oppSplit.Percentage__c = 100;
                                    } else
                                        oppSplit.TeamMemberRole__c = otm.TeamMemberRole; 
                                } else {
                                    oppSplit.TeamMemberRole__c = otm.TeamMemberRole; 
                                }                                        
                                oppSplit.CurrencyIsoCode = otm.Opportunity.CurrencyIsoCode;
    
                                osToUpsert.add(oppSplit);
                            }
                        }
                    } else {
                        if(OpportunitySplitMap.containsKey(mapkeycheck))
                        { 
                            Opportunity_Split__c oppsp = OpportunitySplitMap.get(mapkeycheck);
                            osToDelete.add(oppsp);
                        }
                    }
                }
                // system.debug('Update osToDelete ======> ' + osToDelete);
                // system.debug('Update osToUpsert ======> ' + osToUpsert);
                if(!osToDelete.isEmpty())
                    delete osToDelete;
                if(!osToUpsert.isEmpty())
                    upsert osToUpsert;
            } else {
                for(OpportunityTeamMember otm : oppTeamMembers)
                { 
                    if(otm.TeamMemberRole == 'Opportunity Owner' && otm.Created_on_opportunity_insert__c == true){
                        Opportunity_Split__c newOS = addOpportunityOwnerSplit(otm);
                        osToUpsert.add(newOS);
                    }
                }
                if(!osToUpsert.isEmpty())
                    upsert osToUpsert;
            }
        }
    }
    
    private static Opportunity_Split__c addOpportunityOwnerSplit(OpportunityTeamMember otm) {
        Opportunity_Split__c oppSplit = new Opportunity_Split__c();
        oppSplit.Opportunity__c = otm.OpportunityId;
        oppSplit.User__c = otm.UserId;
        oppSplit.Percentage__c = AvailableTeamMemberRoles.get(otm.TeamMemberRole);
        oppSplit.TeamMemberRole__c = otm.TeamMemberRole;                                      
        oppSplit.CurrencyIsoCode = otm.Opportunity.CurrencyIsoCode;

        return oppSplit;
    }

    public static void RemoveOpportunitySplits(List<OpportunityTeamMember> oppTeamMemberList)
    {
        Set<String> oppIds = new Set<String>();
        Set<String> userIds = new Set<String>();

        for(OpportunityTeamMember oppTeamMember : oppTeamMemberList)
        {
            oppIds.add(oppTeamMember.OpportunityId);
            userIds.add(oppTeamMember.UserId);
        }
        
        List<Opportunity_Split__c> oppSplitList =
            [
                SELECT Id, User__c, Opportunity__c 
                FROM Opportunity_Split__c
                WHERE User__c IN :userIds
                AND Opportunity__c IN :oppIds /*AND Role__c != 'Global Account Manager' AND Role__c != 'Opportunity Owner'*/
            ];
            
        List<Opportunity_Split__c> oppSplitListToDelete = new List<Opportunity_Split__c>();

        for(Opportunity_Split__c oppSplit : oppSplitList)
        {
            for(OpportunityTeamMember oppTeamMember : oppTeamMemberList)
            {
                if(oppSplit.User__c == oppTeamMember.userId && oppSplit.Opportunity__c == oppTeamMember.OpportunityId)
                {
                    oppSplitListToDelete.add(oppSplit);
                }
            }
        }
        if(oppSplitListToDelete.size() > 0)
        {
            delete oppSplitListToDelete;
        }
    }
    
    
    
    public static void PreventAddingOppOwnerAndGAM(List<OpportunityTeamMember> oppTeamMemberList) {
        User usr = [SELECT Id, Name, ProfileId FROM User WHERE Id = :UserInfo.getUserId()];
        Validation_Skip_Opportunity_Team__c userValidation = Validation_Skip_Opportunity_Team__c.getInstance(usr.Id);
        Validation_Skip_Opportunity_Team__c profileValidation = Validation_Skip_Opportunity_Team__c.getInstance(usr.ProfileId);
        System.debug('Name' + usr.Name);
        System.debug('userValidation' + userValidation.Skip_Manually_Add_Opp_Owner_Validation__c);
        System.debug('profileValidation' + userValidation.Skip_Manually_Add_Opp_Owner_Validation__c);
        
        for (OpportunityTeamMember otm : oppTeamMemberList) {
            if (otm.TeamMemberRole == 'Opportunity Owner' && otm.Created_on_opportunity_insert__c == false && userValidation.Skip_Manually_Add_Opp_Owner_Validation__c != 'Yes' && profileValidation.Skip_Manually_Add_Opp_Owner_Validation__c != 'Yes') {
                otm.addError('You can\'t manually add the Opportunity Owner role');
            } 
            
            /*if (otm.TeamMemberRole == 'Global Account Manager' && otm.Created_on_opportunity_insert__c == false) {
                otm.addError('You can\'t manually add the Global Account Manager role');
            }*/ 
        }
    }
    
   
    public static void preventDeletion(List<OpportunityTeamMember> oldList) {
        User usr = [SELECT Id, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        if ((usr.Profile.Name != 'Super Admin' && usr.Profile.Name != 'System Administrator' && usr.Profile.Name != 'Sales Ops Geo Leads' && usr.Profile.Name != 'Data Stewards') || Test.isRunningTest()) {
            Set<Id> oppIdSet = new Set<Id>();
            for (OpportunityTeamMember pi : oldList) {
                oppIdSet.add(pi.OpportunityId);
            }
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, RecordType.DeveloperName FROM Opportunity WHERE Id IN :oppIdSet]);
            for (OpportunityTeamMember pi : oldList) {
                if (oppMap.containsKey(pi.OpportunityId)) {
                    if (oppMap.get(pi.OpportunityId).RecordType.DeveloperName == 'UiPath_Standard_Locked' ||
                            oppMap.get(pi.OpportunityId).RecordType.DeveloperName == 'CPQ_Locked')
                        pi.addError('You cannot delete a team member for a locked opportunity.');
                }
            }
        }
    }
    
    public static void preventDeletingOppOwnerAndGAM(List<OpportunityTeamMember> oldList) {
        User usr = [SELECT Id, Name, ProfileId FROM User WHERE Id = :UserInfo.getUserId()];
        Validation_Skip_Opportunity_Team__c userValidation = Validation_Skip_Opportunity_Team__c.getInstance(usr.Id);
        Validation_Skip_Opportunity_Team__c profileValidation = Validation_Skip_Opportunity_Team__c.getInstance(usr.ProfileId);
        
        Set<Id> oppIdSet = new Set<Id>();
        for (OpportunityTeamMember pi : oldList) {
            if(pi.TeamMemberRole == 'Opportunity Owner')
                oppIdSet.add(pi.OpportunityId);
        }
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, OwnerId, AccountId, Account.KAM_ID__c  FROM Opportunity WHERE Id IN :oppIdSet]);
        for (OpportunityTeamMember pi : oldList) {
            if (oppMap.containsKey(pi.OpportunityId)) {
                if (oppMap.get(pi.OpportunityId).OwnerId == pi.UserId && !Test.isRunningTest() && userValidation.Skip_Delete_Opp_Owner_Validation__c != 'Yes' && profileValidation.Skip_Delete_Opp_Owner_Validation__c != 'Yes')
                    pi.addError('You cannot manually delete Opportunity Owner.');
            }
        }
       
    }
}