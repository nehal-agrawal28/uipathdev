public with sharing class DisplayCustomOppSplitController 
{
    public String opportunityId;
    public List<Opportunity_Split__c> oppSplitList {get; set;} 
    public List<OpportunityTeamMember> oppTeamMemberList {get; set;}
    public Map<String, Decimal> roleToPercentageSumCurrent {get; set;}
    public List<OppSplitWrapper> oppSplitWrapperList {get; set;}

    public void setOpportunityId (String oppId) 
    {
        opportunityId = oppId;
        DisplayCustomOppSplit();
    }
        
    public String getOpportunityId() 
    {
        return opportunityId;
    }

	public void DisplayCustomOppSplit() 
    {
        roleToPercentageSumCurrent = new Map<String, Decimal>();

        List<AvailableTeamMemberRole__mdt> availableRoles = 
            [
                SELECT Id, Role__c
                FROM AvailableTeamMemberRole__mdt
            ];

        Set<String> roleSet = new Set<String>();

        for(AvailableTeamMemberRole__mdt role : availableRoles)
        {
            roleSet.add(role.Role__c);
        }

        oppSplitWrapperList = new List<OppSplitWrapper>();

        oppSplitList =
            [
                SELECT User__r.Profile.Name, User__r.UserRole.Name, Id, Percentage__c, User__c, Opportunity__c, User__r.Name, Role__c, User__r.GIC_Sales__c
                FROM Opportunity_Split__c
                WHERE Opportunity__c = :opportunityId
            ];
        
        oppTeamMemberList =
            [
                SELECT User.Profile.Name, User.UserRole.Name, Id, TeamMemberRole, UserId, User.GIC_Sales__c, User.Name
                FROM OpportunityTeamMember
                WHERE OpportunityId = :opportunityId
                AND TeamMemberRole IN :roleSet
            ];

        Set<String> usedRoleSet = new Set<String>();

        for(OpportunityTeamMember oppTeamMember : oppTeamMemberList)
        { 
            if(oppTeamMember.User.GIC_Sales__c == true || usedRoleSet.contains(oppTeamMember.TeamMemberRole))
            {
                continue;
            }

            if(oppTeamMember.TeamMemberRole == 'Opportunity Owner' && (oppTeamMember.User.UserRole != null && (oppTeamMember.User.UserRole.Name.contains('Inside Sales') || oppTeamMember.User.Profile.Name.contains('Inside Sales'))))
            {
                continue;
            }

            // add only once the percentage for same role splits.
            usedRoleSet.add(oppTeamMember.TeamMemberRole);

            // make a list with all the mebers from both 'Opportunity Owner' and 'Sales Representative'
            if(oppTeamMember.TeamMemberRole == 'Sales Representative')
            {
                usedRoleSet.add('Opportunity Owner');
            }
            else if(oppTeamMember.TeamMemberRole == 'Opportunity Owner')
            {
                usedRoleSet.add('Sales Representative');
            }

            roleToPercentageSumCurrent.put(oppTeamMember.TeamMemberRole, 0);

            for(Opportunity_Split__c oppSplit : oppSplitList)
            {
                if(oppSplit.User__r.GIC_Sales__c == true)
                {
                    continue;
                }

                if(oppSplit.Role__c == 'Opportunity Owner' && (oppSplit.User__r.UserRole != null && (oppSplit.User__r.UserRole.Name.contains('Inside Sales') || oppSplit.User__r.Profile.Name.contains('Inside Sales'))))
                {
                    continue;
                }

                if(oppTeamMember.TeamMemberRole == 'Sales Representative' && oppSplit.Role__c == 'Opportunity Owner')
                {
                    roleToPercentageSumCurrent.put(oppTeamMember.TeamMemberRole, roleToPercentageSumCurrent.get(oppTeamMember.TeamMemberRole) + oppSplit.Percentage__c);
                }
                else if(oppTeamMember.TeamMemberRole == 'Opportunity Owner' && oppSplit.Role__c == 'Sales Representative')
                {
                    roleToPercentageSumCurrent.put(oppTeamMember.TeamMemberRole, roleToPercentageSumCurrent.get(oppTeamMember.TeamMemberRole) + oppSplit.Percentage__c);
                }
                else if(oppTeamMember.TeamMemberRole == oppSplit.Role__c)
                {
                    roleToPercentageSumCurrent.put(oppTeamMember.TeamMemberRole, roleToPercentageSumCurrent.get(oppTeamMember.TeamMemberRole) + oppSplit.Percentage__c);
                }
            }
            
            if(roleToPercentageSumCurrent.get(oppTeamMember.TeamMemberRole) > 125)
            {                
                for(Opportunity_Split__c oppSplit : oppSplitList)
                {
                    if(oppSplit.User__r.GIC_Sales__c == true)
                    {
                        continue;
                    }

                    if(oppSplit.Role__c == 'Opportunity Owner' && (oppSplit.User__r.UserRole != null && (oppSplit.User__r.UserRole.Name.contains('Inside Sales') || oppSplit.User__r.Profile.Name.contains('Inside Sales'))))
                    {
                        continue;
                    }

                    if(oppTeamMember.TeamMemberRole == 'Sales Representative' && oppSplit.Role__c == 'Opportunity Owner')
                    {
                        OppSplitWrapper oppSplitWrapper = new OppSplitWrapper();
                        oppSplitWrapper.oppSplit = oppSplit;
                        oppSplitWrapper.teamMember = oppTeamMember;

                        oppSplitWrapperList.add(oppSplitWrapper);
                    }
                    else if(oppTeamMember.TeamMemberRole == 'Opportunity Owner' && oppSplit.Role__c == 'Sales Representative')
                    {
                        OppSplitWrapper oppSplitWrapper = new OppSplitWrapper();
                        oppSplitWrapper.oppSplit = oppSplit;
                        oppSplitWrapper.teamMember = oppTeamMember;

                        oppSplitWrapperList.add(oppSplitWrapper);   
                    }
                    else if(oppTeamMember.TeamMemberRole == oppSplit.Role__c)
                    {
                        OppSplitWrapper oppSplitWrapper = new OppSplitWrapper();
                        oppSplitWrapper.oppSplit = oppSplit;
                        oppSplitWrapper.teamMember = oppTeamMember;

                        oppSplitWrapperList.add(oppSplitWrapper);   
                    }
                }
            }
        }
	}

    public class OppSplitWrapper
    {
        public Opportunity_Split__c oppSplit {get; set;}
        public OpportunityTeamMember teamMember {get; set;}
        public Boolean hasTeamMember {get; set;}

        public OppSplitWrapper()
        {
            oppSplit = new Opportunity_Split__c();
            teamMember = new OpportunityTeamMember();
            hasTeamMember = true;
        }
    }
}