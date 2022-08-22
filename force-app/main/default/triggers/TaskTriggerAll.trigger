/********************************************************************************************************
*    Name:  TaskTriggerAll.trigger
*    Date:  27/4/2021
*    
*    Handler class: TaskTriggerAllHandler.cls
*    Test class: TaskTriggerAllHandlerTest.cls
********************************************************************************************************/

trigger TaskTriggerAll on Task (before insert/*, before update, after insert, after update, before delete, after delete*/) {
    
    /*TaskTriggerAllHandler handler = new TaskTriggerAllHandler();
    
    if (Trigger.isInsert) {
        if (Trigger.isBefore)
            handler.onBeforeInsert(Trigger.New, Trigger.NewMap ) ;
            
        if (Trigger.isAfter) 
            handler.onAfterInsert(Trigger.New, Trigger.NewMap);
    }
    
    if (Trigger.isUpdate) {
        if (Trigger.isBefore)
            handler.onBeforeUpdate(Trigger.New, Trigger.NewMap, Trigger.oldMap);
        
        if (Trigger.isAfter)
            handler.onAfterUpdate(Trigger.New, Trigger.NewMap , Trigger.oldMap);
    }

    if (Trigger.isDelete) {
        if (Trigger.isBefore)
            handler.onBeforeDelete(Trigger.Old, Trigger.oldMap);
        
        if (Trigger.isAfter)
            handler.onAfterDelete(Trigger.Old, Trigger.oldMap );
    }*/

}