trigger GroupTaskTrigger on Task (after update) {
    if(TriggerUtilities.SKIP_TRIGGER.containsKey('GroupTaskTrigger')) return;
    
    TaskTriggerHandler TTH = new TaskTriggerHandler(trigger.new, trigger.oldMap);
    
    TriggerUtilities.SKIP_TRIGGER.put('GroupTaskTrigger','Skip');
    TTH.processStatusChanging();
    TriggerUtilities.SKIP_TRIGGER.remove('GroupTaskTrigger');    
}