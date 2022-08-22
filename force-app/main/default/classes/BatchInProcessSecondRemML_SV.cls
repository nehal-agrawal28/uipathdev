global class BatchInProcessSecondRemML_SV implements Database.Batchable<sObject> {
  public OrgWideEmailAddress owa;
  public EmailTemplate template;

  public BatchInProcessSecondRemML_SV() {
    try {
      owa = [SELECT id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = 'uipathsupport@uipath.com'];
      template = [SELECT id, subject, htmlvalue FROM EmailTemplate WHERE name = 'Case In Process Second Reminder'];
    } catch (Exception e) {
    }
  }

  global Database.QueryLocator start(Database.BatchableContext bc) {
    List<String> recordTypeNames = Label.Case3StrikeRuleRecordTypes.split(',');
    List<String> recordTypeIds = new List<String>();

    for (String recordTypeName : recordTypeNames) {
      recordTypeIds.add(
        Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId()
      );
    }

    Date dateToConsiderML = BatchToSendCaseStrike1Email_SV.calculateWorkingDays(
      Integer.valueOf(Label.CaseInProcessSecondRemML)
    );
    String query = '';
    if (Test.isRunningTest()) {
      query = 'Select Id, CaseNumber, Subject, Status, Status_In_Process_Time_Stamp__c, OwnerId, Owner.Email,Owner_s_Manager_Email__c, Owner.FirstName, Priority from Case where RecordTypeId in :recordTypeIds';
    } else {
      query = 'Select Id, CaseNumber, Subject, Status, Status_In_Process_Time_Stamp__c, OwnerId, Owner.Email,Owner_s_Manager_Email__c, Owner.FirstName, Priority from Case where RecordTypeId in :recordTypeIds and Owner.Type = \'User\' and Origin!=\'Email\' and Status=\'In Process\' and DAY_ONLY(Status_In_Process_Time_Stamp__c) = :dateToConsiderML and (Priority = \'Medium\' or Priority = \'Low\')';
    }
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext bc, List<Case> scope) {
    try {
      List<String> ccAddresses = Label.CaseInProcessSecondRemCCEmails.split(',');
      List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
      Map<String, String> caseAndContactIdMap = new Map<String, String>();
      for (Case caseInScope : scope) {
        List<String> caseCcAddresses = new List<String>();
        caseCcAddresses.addAll(ccAddresses);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSaveAsActivity(false);
        String subject = template.Subject;
        String htmlValue = template.HtmlValue;
        subject = subject.replace(
          '{!Case.CaseNumber}',
          caseInScope.CaseNumber != null &&
            String.isNotBlank(caseInScope.CaseNumber) &&
            String.isNotEmpty(caseInScope.CaseNumber)
            ? caseInScope.CaseNumber
            : ''
        );
        subject = subject.replace(
          '{!Case.Subject}',
          caseInScope.Subject != null &&
            String.isNotBlank(caseInScope.Subject) &&
            String.isNotEmpty(caseInScope.Subject)
            ? caseInScope.Subject
            : ''
        );
        htmlValue = htmlValue.replace(
          '{!Case.OwnerFirstName}',
          caseInScope.Owner.FirstName != null &&
            String.isNotBlank(caseInScope.Owner.FirstName) &&
            String.isNotEmpty(caseInScope.Owner.FirstName)
            ? caseInScope.Owner.FirstName
            : ''
        );
        htmlValue = htmlValue.replace(
          '{!Case.Priority}',
          caseInScope.Priority != null &&
            String.isNotBlank(caseInScope.Priority) &&
            String.isNotEmpty(caseInScope.Priority)
            ? caseInScope.Priority
            : ''
        );
        mail.setSubject(subject);
        mail.setHtmlBody(htmlValue);
        mail.setTargetObjectId(caseInScope.OwnerId);
        //mail.setToAddresses(new List<String>{ caseInScope.Owner.Email });
        if (
          caseInScope.Owner_s_Manager_Email__c != null &&
          String.isNotBlank(caseInScope.Owner_s_Manager_Email__c) &&
          String.isNotEmpty(caseInScope.Owner_s_Manager_Email__c)
        )
          caseCcAddresses.add(caseInScope.Owner_s_Manager_Email__c);
        mail.setCcAddresses(caseCcAddresses);
        mail.setOrgWideEmailAddressId(owa.id);
        mail.setTemplateID(template.Id);
        emailMessages.add(mail);
      }
      Messaging.sendEmail(emailMessages, false);
    } catch (Exception e) {
    }
  }

  global void finish(Database.BatchableContext bc) {
  }
}