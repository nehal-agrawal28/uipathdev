trigger CommunityAccountTrigger on Account (after insert, after update) {
    
    CommunityAccountTriggerHandler handler = new CommunityAccountTriggerHandler();
    
    if (Trigger.isAfter && Trigger.isInsert) {
        handler.onAfterInsert(Trigger.new, Trigger.newMap);
        
    } else if (Trigger.isAfter && Trigger.isUpdate) {
        handler.onAfterUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
        
    }
    
}