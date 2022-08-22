trigger TechnicalReview_trigger on Technical_Review__c (After insert,After Update, after delete, before delete) {
 TechnicalReview_TriggerHelper helper= new  TechnicalReview_TriggerHelper();
     if(Trigger.isInsert) 
    {    
        if(Trigger.isAfter) 
        {
            helper.onAfterInsert(Trigger.New);
        }
    }
    else if(Trigger.isUpdate) 
    {    
        if(Trigger.isAfter) 
        {
            helper.onAfterInsert(Trigger.New);
        }
    }
}