trigger ZinfiContactCreateForAccountUpdate on Account (after Update) 
{
    ZinfiConfiguration__c zinfiSetting = ZinfiConfiguration__c.getInstance();
    if(zinfiSetting != null && zinfiSetting.IsSyncAccount__c)
    {
         Set<Id> Ids = trigger.oldMap.keySet();
         ZinfiSyncContactWithAccount.sendContactFutureCall(Ids);
    }
}