global class BatchToSendReminderForSurvey implements Database.Batchable<sObject>{
    
    public OrgWideEmailAddress owa;
    public EmailTemplate templateId;
    
    global BatchToSendReminderForSurvey(){
        owa = [select id, DisplayName, Address from OrgWideEmailAddress where Address='uipathsupport@uipath.com'];
		templateId = [Select id,subject,htmlvalue from EmailTemplate where name ='Reminder To Take Survey' ];
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        List<String> recordTypeNames = Label.Survey_Reminder_Record_Types.split(',');
        List<String> recordTypeIds = new List<String>();
        
        for(String recordTypeName : recordTypeNames){
            recordTypeIds.add(Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId());
        }
        
        //String incidentRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Incident').getRecordTypeId();
        
        Date firstReminderDate = System.today().addDays(-1* Integer.valueOf(Label.Case_Survey_First_Reminder));
        Date secondReminderDate = System.today().addDays(-1* Integer.valueOf(Label.Case_Survey_Second_Reminder));
        String query;
        if(Test.isRunningTest()){
            query = 'Select Id, CaseNumber, Subject, Related_To__c,Resolution_Summary__c,ClosedDate, Status,ContactId,(Select Id from SurveyTakers__r) from Case where RecordTypeId in :recordTypeIds';
        }else{
            query = 'Select Id, CaseNumber, Subject, Related_To__c,Resolution_Summary__c,ClosedDate, Status,ContactId,(Select Id from SurveyTakers__r) from Case where RecordTypeId in :recordTypeIds and Origin!=\'Email\' and Status=\'Closed\' and (DAY_ONLY(ClosedDate) = :firstReminderDate  or DAY_ONLY(ClosedDate) = :secondReminderDate)';
        }
        return Database.getQueryLocator(query);
    }
	
    global void execute(Database.BatchableContext bc, List<Case> scope){
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        Map<String,String> caseAndContactIdMap = new Map<String,String>();
        for(Case c : scope){
            if(c.SurveyTakers__r == null || c.SurveyTakers__r.size()==0){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
            	mail.setTemplateID(templateId.Id);
            	mail.setSaveAsActivity(false);
                
                mail.setWhatId(c.Id);
            	mail.setTargetObjectId(c.ContactId); 
            	mail.setOrgWideEmailAddressId(owa.id);
            	emailMessages.add(mail);
            }
        }
        Messaging.sendEmail(emailMessages,false);
    }

    global void finish(Database.BatchableContext bc){
        
    }
    
    
}