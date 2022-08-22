global class BatchToSendCaseResolvedReminder implements Database.Batchable<sObject>{
  
    public OrgWideEmailAddress owa;
    public EmailTemplate template;
    
    global BatchToSendCaseResolvedReminder(){
        owa = [select id, DisplayName, Address from OrgWideEmailAddress where Address='uipathsupport@uipath.com'];
        template = [Select id,subject,htmlvalue from EmailTemplate where name ='Case Resolved Reminder To Customer' ];
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        List<String> recordTypeNames = Label.Case3StrikeRuleRecordTypes.split(',');
        List<String> recordTypeIds = new List<String>();
        
        for(String recordTypeName : recordTypeNames){
            recordTypeIds.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId());
        }
        
        Date resolutionDate = System.today().addDays(-1* Integer.valueOf(Label.CaseResolvedReminderDays));
        String query = '';
        if(Test.isRunningTest()){
            query = 'Select Id, CaseNumber, Subject, Status, Status_Resolved_Time_Stamp__c, ContactId, Contact.Name, Contact.Email, SuppliedEmail, SuppliedName from Case where RecordTypeId in :recordTypeIds';
        }else{
            query = 'Select Id, CaseNumber, Subject, Status, Status_Resolved_Time_Stamp__c, ContactId, Contact.Name, Contact.Email, SuppliedEmail, SuppliedName from Case where RecordTypeId in :recordTypeIds and Origin!=\'Email\' and Status=\'Resolved\' and DAY_ONLY(Status_Resolved_Time_Stamp__c) = :resolutionDate';
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Case> scope){
        CaseMetadata_SV.isAutoCloseBatch = true;
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        Map<String,String> caseAndContactIdMap = new Map<String,String>();
        for(Case caseInScope : scope){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setWhatId(caseInScope.Id);
            mail.setSaveAsActivity(true);
            List<String> emailAddresses = new List<String>();
            String subject = template.Subject;
            String htmlValue = template.HtmlValue;
            String name = '';
            if(caseInScope.ContactId !=null && String.isNotBlank(caseInScope.ContactId) && String.isNotEmpty(caseInScope.ContactId)){
                emailAddresses.add(caseInScope.Contact.Email);
                name = caseInScope.Contact.Name;
            }else {
                emailAddresses.add(caseInScope.SuppliedEmail);
                name = caseInScope.SuppliedName;
            }
            subject = subject.replace('{!Case.CaseNumber}',caseInScope.CaseNumber);
            subject = subject.replace('{!Case.Subject}',caseInScope.Subject);
            htmlValue = htmlValue.replace('{!Case.CaseNumber}',caseInScope.CaseNumber);
            htmlValue = htmlValue.replace('{!Contact.FirstName}', name);
            String caseId = caseInScope.Id;
            htmlValue += '<br/> '+threadIdClass.caseRefId(UserInfo.getOrganizationId(),caseId);
            mail.setSubject(subject);
            mail.setHtmlBody(htmlValue);
            mail.setToAddresses(emailAddresses);
            mail.setOrgWideEmailAddressId(owa.id);
            mail.setTemplateID(template.Id);
            emailMessages.add(mail);
        }
        Messaging.sendEmail(emailMessages,false);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
    
}