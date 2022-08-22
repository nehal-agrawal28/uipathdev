trigger ZinfiAccountDeleted on Account (after Delete) 
{
    ZinfiConfiguration__c zinfiSetting = ZinfiConfiguration__c.getInstance();
    if(zinfiSetting != null && zinfiSetting.IsSyncAccount__c)
    {
         Set<Id> Ids = trigger.oldMap.keySet();
         ZinfiSyncOnline.sendAccountFutureCall(Ids);
    }
}