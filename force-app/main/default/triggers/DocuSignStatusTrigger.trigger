/**
*
* Author:       Daniel Sarchiz
* Date:         20/11/2017
* Description:  Main trigger for DocuSign Status object
*
**/

trigger DocuSignStatusTrigger on dsfs__DocuSign_Status__c (before insert, before update) {
    
    DocuSignStatusTriggerHandler handler = new DocuSignStatusTriggerHandler(Trigger.isExecuting, Trigger.size);
    
    if(Trigger.isInsert) {
        
        if(Trigger.isBefore) {
            
            handler.onBeforeInsert(Trigger.new);
        }
    }
    else if(Trigger.isUpdate) {
        
        if(Trigger.isBefore) {
            
            handler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}