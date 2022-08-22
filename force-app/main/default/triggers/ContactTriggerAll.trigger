/********************************************************************************************************
*    Name:  ContactTriggerAll.trigger
*    Author: Mirela Chituc (mirela.chituc@uipath.com) 
*    Date:  10/3/2019
*    
*    Handler class: ContactTriggerAllHandler.cls
*    Test class: ContactTriggerAllHandlerTest.cls
********************************************************************************************************/

trigger ContactTriggerAll on Contact (before insert, before update, after insert, after update, before delete, after delete) {
    
    ContactTriggerAllHandler handler = new ContactTriggerAllHandler();
    
    if (Trigger.isInsert) {
        if (Trigger.isBefore)
            handler.onBeforeInsert(Trigger.New, Trigger.NewMap ) ;
            
        if (Trigger.isAfter) 
            handler.onAfterInsert(Trigger.New, Trigger.NewMap, Trigger.oldMap);
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
    }

}