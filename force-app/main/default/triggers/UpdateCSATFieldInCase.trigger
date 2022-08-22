trigger UpdateCSATFieldInCase on SurveyQuestionResponse__c (after insert) {
    UpdateCSATFieldInCase_TriggerHandler handler=new UpdateCSATFieldInCase_TriggerHandler();
 if(Trigger.isInsert) {
        system.debug('This trigger is working');
        if(Trigger.isAfter) {
            
            handler.onAfterInsert(Trigger.New);
        }
    }
}