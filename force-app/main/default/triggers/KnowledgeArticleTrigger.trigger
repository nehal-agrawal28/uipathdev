trigger KnowledgeArticleTrigger on Knowledge__kav (before insert, before update,after insert) {
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            KnowledgeArticleTriggerHandler.beforeInsertOperations(Trigger.New);
        }
        if(Trigger.isUpdate){
            KnowledgeArticleTriggerHandler.beforeUpdateOperations(Trigger.New, Trigger.OldMap);
        }
    }
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            KnowledgeArticleTriggerHandler.afterInsertOperations(Trigger.New, Trigger.OldMap);
        }
        
    }
    
}