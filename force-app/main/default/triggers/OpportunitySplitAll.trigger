trigger OpportunitySplitAll on Opportunity_Split__c (before insert) 
{
    
    if(Trigger.isBefore)
    {
        if (Trigger.isInsert) {
            OpportunitySplitHandlerAll.SetPAMPercent(Trigger.new);
        }
    }
}