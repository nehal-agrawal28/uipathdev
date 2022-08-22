trigger OpportunityTeamMember on OpportunityTeamMember (after delete, after update, before insert, before update, before delete) 
{
    /*if(Trigger.isAfter)
    {
        if(Trigger.isDelete)
        {
            OppTeamMemberHandler.RemoveOpportunitySplits(Trigger.old);
        }
        else if(Trigger.isUpdate)
        {
            List<OpportunityTeamMember> oppTeamMembersToUpdate = new List<OpportunityTeamMember>();

            for(OpportunityTeamMember oppTeamMember : Trigger.new)
            {
                // only update Opportunity Splits for the OTM that had their role changed
                if(oppTeamMember.TeamMemberRole != Trigger.oldMap.get(oppTeamMember.Id).TeamMemberRole)
                {
                    oppTeamMembersToUpdate.add(oppTeamMember);
                }
            }

            if(oppTeamMembersToUpdate.size() > 0)
            {
                OppTeamMemberHandler.UpdateOpportunitySplits(oppTeamMembersToUpdate);
            }
        }
    }
    if(Trigger.isBefore)
    {
        if (Trigger.isInsert || Trigger.isUpdate) {
            OppTeammemberHandler.PreventAddingOpportunityOwner(Trigger.new);
        }
        if (Trigger.isDelete) {
            OppTeammemberHandler.preventDeletion(Trigger.old);
        }
    }*/
}