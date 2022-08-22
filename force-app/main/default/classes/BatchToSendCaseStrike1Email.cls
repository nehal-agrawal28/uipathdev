global class BatchToSendCaseStrike1Email implements Database.Batchable<sObject>{
    
    public OrgWideEmailAddress owa;
    public EmailTemplate template;
    public Integer autoResolvedRemainingDays;
    public Date dateToConsider;
    global BatchToSendCaseStrike1Email(){
        Integer CaseStrike1Days = Integer.valueOf(Label.CaseStrike1Days);
        Integer CaseAutoResolveDays = Integer.valueOf(Label.CaseAutoResolvedDays);
        autoResolvedRemainingDays = CaseAutoResolveDays - CaseStrike1Days;
        owa = [select id, DisplayName, Address from OrgWideEmailAddress where Address='uipathsupport@uipath.com'];
        template = [Select id,subject,htmlvalue from EmailTemplate where name ='Case Strike 1 Email' ];
        dateToConsider = calculateWorkingDays(Integer.valueOf(Label.CaseStrike1Days));
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        List<String> recordTypeNames = Label.Case3StrikeRuleRecordTypes.split(',');
        List<String> recordTypeIds = new List<String>();
        
        for(String recordTypeName : recordTypeNames){
            recordTypeIds.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId());
        }
        
        String query = '';
        if(Test.isRunningTest()){
            query = 'Select Id, CaseNumber, Subject, Status, Status_Customer_Action_Time_Stamp__c, ContactId, Contact.Name, Contact.Email, SuppliedEmail, SuppliedName, Status_Sub_Category__c from Case where RecordTypeId in :recordTypeIds';
        }else{
            query = 'Select Id, CaseNumber, Subject, Status, Status_Customer_Action_Time_Stamp__c, ContactId, Contact.Name, Contact.Email, SuppliedEmail, SuppliedName, Status_Sub_Category__c, '+
                '(Select Id, NewValue, Field, CreatedDate from Histories where Field = \'Status_Sub_Category__c\' order by createdDate desc limit 1)'+
                'from Case where RecordTypeId in :recordTypeIds and Origin!=\'Email\' and Status=\'Customer Action\' and Status_Sub_Category__c=\'3 Strike Rule\' and '+
                'Id IN (SELECT CaseId FROM CaseHistory where Field = \'Status_Sub_Category__c\' and DAY_ONLY(CreatedDate)=:dateToConsider)';
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Case> scope){
        
        CaseMetadata_SV.isAutoCloseBatch = true;
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        Map<String,String> caseAndContactIdMap = new Map<String,String>();
        for(Case caseInScope : scope){
            if(caseInScope.Histories!=null && caseInScope.Histories.size()>0 && caseInScope.Histories[0].NewValue == '3 Strike Rule' 
               && Date.newInstance(caseInScope.Histories[0].CreatedDate.year(), caseInScope.Histories[0].CreatedDate.month(), caseInScope.Histories[0].CreatedDate.day()) == dateToConsider){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setSaveAsActivity(false);
                List<String> emailAddresses = new List<String>();
                mail.setWhatId(caseInScope.Id);
                //mail.setTargetObjectId(c.ContactId); 
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
                htmlValue = htmlValue.replace('{!Contact.FirstName}', name);
                String autoResolvedText = 'If we do not hear back in next '+autoResolvedRemainingDays+' working day(s), the case will be auto-resolved. <br/>';
                htmlValue = htmlValue.replace('{!AutoResolvedText}', autoResolvedText);
                String reminderNumber = '#Case Reminder 1';
                htmlValue = htmlValue.replace('{!CaseReminderNumber}', reminderNumber);
                String caseId = caseInScope.Id;
                htmlValue += '<br/> '+threadIdClass.caseRefId(UserInfo.getOrganizationId(),caseId);
                mail.setSubject(subject);
                mail.setHtmlBody(htmlValue);
                mail.setToAddresses(emailAddresses);
                mail.setOrgWideEmailAddressId(owa.id);
                mail.setTemplateID(template.Id);
                mail.setSaveAsActivity(true);
                emailMessages.add(mail);
            }
            
        }
        if(emailMessages!=null && emailMessages.size()>0)
        	Messaging.sendEmail(emailMessages,false);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
    public static Date calculateWorkingDays(Integer howManyDays){
        Date startDate = System.today();
        Integer i = 1;
        List<Date> workingDays = new List<Date>();
        while(workingDays.size() != howManyDays){
            Date dt = startDate.addDays(-1 * i);
            DateTime dtTime = DateTime.newInstance(dt.year(), dt.month(), dt.day());
            String dayOfWeek = dtTime.format('EEEE');
            if(dayOfWeek != 'Saturday' && dayOfWeek != 'Sunday'){
                workingDays.add(dt);
            }
            i++;
        }
        return workingDays[workingDays.size()-1];
    }
    
}