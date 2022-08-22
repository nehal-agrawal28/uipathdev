trigger CreateAssetonClosedWon on Opportunity (after insert, after update) 
{
    if(Trigger.isAfter)
    { 
        if(Trigger.isInsert)
        {
            //CreateAssetOnClosedWonHandler.CreateAssetOnClosedWon(Trigger.new);
        }
        else if(Trigger.isUpdate)
        {
            //CreateAssetOnClosedWonHandler.CreateAssetOnClosedWon(Trigger.new);
        }    
    }
}